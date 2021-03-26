import parseopt
import os
import system
import strutils
import distros
import tables

# taskopen modules
import ./output
import ./config
import ./taskwarrior as tw
import ./types
import ./core

proc version():string =
  result = "unknown"
  when defined(versionGit):
    const gitver = staticExec("git describe --tags HEAD")
    result = gitver
  elif defined(versionNimble):
    let regex = re(".*version\\s*=\\s*\"([^\n]+)\"", {reDotAll})
    const nf = staticRead("../taskopen.nimble")
    if nf =~ regex:
      result = matches[0]

  when not defined(release):
    result &= " (Debug)"


proc writeDiag(settings: Settings) =
  echo "Environment"
  when defined(posix):
    if detectOs(MacOSX):
      echo "    Platform:      ", "Mac OSX"
    elif detectOs(Linux):
      echo "    Platform:      ", "Linux"
  when defined(windows):
    echo "    Platform:      ", "Windows"

  echo "    Taskopen:      ", version()
  echo "    Taskwarrior:   ", tw.version(settings.taskbin)
  echo "    Configuration: ", settings.configfile

  echo "Current configuration"
  echo "  Binaries and paths:"
  echo "    taskbin            = ", settings.taskbin
  echo "    editor             = ", settings.editor
  echo "    path_ext           = ", settings.pathExt
  echo "  General:"
  echo "    debug              = ", settings.debug
  echo "    no_annotation_hook = ", settings.noAnnot
  echo "    task_attributes    = ", settings.taskAttributes
  echo "  Action groups:"
  for group, actions in settings.actionGroups.pairs():
    echo "    ", alignLeft(group, 19), "= ", actions
  echo "  Subcommands:"
  echo "    default            = ", settings.defaultSubcommand
  for sub, alias in settings.validSubcommands.pairs():
    if alias != "":
      echo "    ", alignLeft(sub, 19), "= ", alias

  echo "  Actions:"
  for action in settings.validActions.values():
    echo "    ", action.name
    echo "      ", alignLeft(".target", 17), "= ", action.target
    echo "      ", alignLeft(".regex", 17),  "= ", action.regex
    echo "      ", alignLeft(".labelregex", 17),  "= ", action.labelregex
    echo "      ", alignLeft(".command", 17),  "= ", action.command
    echo "      ", alignLeft(".modes", 17),  "= ", action.modes.join(",")
    if action.inlinecommand != "":
      echo "      ", alignLeft(".inlinecommand", 17),  "= ", action.inlinecommand
    if action.filtercommand != "":
      echo "      ", alignLeft(".filtercommand", 17),  "= ", action.filtercommand


proc writeHelp() =
  echo "Help not implemented"


proc includeActions(valid: OrderedTable[string, Action], groups: Table[string, string], includes: string): seq[string] =
  for a in includes.split(','):
    if valid.hasKey(a):
      result.add(a)
    elif groups.hasKey(a):
      # expand action group
      for a2 in groups[a].split(','):
        if valid.hasKey(a2):
          result.add(a2)


proc excludeActions(valid: OrderedTable[string, Action], groups: Table[string, string], excludes: string): seq[string] =
  var excluded = excludes.split(',')

  # expand action groups
  var expanded = excluded
  for a in excluded:
    if not valid.hasKey(a) and groups.hasKey(a):
      for a2 in groups[a].split(','):
        if valid.hasKey(a2):
          expanded.add(a2)

  for a in valid.keys():
    if not (a in expanded):
      result.add(a)


proc parseOpts(opts: seq[string], settings: var Settings, ignoreconfig: bool): string =
  const shortNoVal = { 'v', 'h', 'A'}
  const longNoVal  = @["verbose", "help", "All", "debug"]
  var p = initOptParser(opts,
    shortNoVal=shortNoVal,
    longNoVal=longNoVal)

  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "":
        settings.filter.add(p.remainingArgs)
        break

      case p.key
      of "h", "help":
        writeHelp()
        quit()

      of "v", "verbose":
        output.level = LogLevel(min(int(info), int(output.level)))

      of "debug":
        output.level = debug
        settings.debug = true

      of "s", "sort":
        settings.sort = p.val

      of "c", "config":
        if not ignoreconfig and os.fileExists(p.val):
          warn.log("Using alternate config file ", p.val)
          return p.val
        elif not ignoreconfig:
          # ask user whether to create the config file
          stdout.write("Config file '", p.val, "' does not exist, create it? [y/N]: ")
          let answer = readLine(stdin)
          if answer == "y" or answer == "Y":
            createConfig(p.val, settings)

      of "a", "active-tasks":
        settings.basefilter = p.val

      of "x", "execute":
        settings.forceCommand = p.val

      of "f", "filter-command":
        settings.filterCommand = p.val

      of "i", "inline-command":
        settings.inlineCommand = p.val

      of "args":
        settings.args = p.val

      of "include":
        if settings.restrictActions:
          warn.log("Ignoring --include option because --exclude was already specified.")
        else:
          settings.actions = includeActions(settings.validActions,
                                            settings.actionGroups,
                                            p.val)
          settings.restrictActions = true

      of "exclude":
        if settings.restrictActions:
          warn.log("Ignoring --exclude option because --include was already specified.")
        else:
          settings.actions = excludeActions(settings.validActions,
                                            settings.actionGroups,
                                            p.val)
          settings.restrictActions = true

      of "A", "All":
        settings.all = true
      else:
        warn.log("Invalid command line option: ", p.key, "=", p.val)

    of cmdArgument:
      if settings.command == "" and settings.validSubcommands.hasKey(p.key):
        let alias = settings.validSubcommands[p.key]

        if alias != "":
          let cfg = parseOpts(alias.splitWhitespace(), settings, ignoreconfig)

          if cfg != "":
            return cfg
        else:
          settings.command = p.key

      else:
        settings.filter.add(p.key)

  result = ""


proc setup(): Settings =
  output.level = warn

  # first, read the config to get aliases and default options
  result = parseConfig(findConfig())

  # second, parse command line options
  let configfile = parseOpts(result.unparsedOptions & commandLineParams(),
                             result,
                             false)
  if configfile != "":
    # if --config options was found, redo everything
    result = parseConfig(configfile)
    discard parseOpts(result.unparsedOptions & commandLineParams(),
                      result,
                      true)

  # apply default command
  if result.command == "":
    if not result.validSubcommands.hasKey(result.defaultSubcommand):
      warn.log("Ignoring non-existing default subcommand '", result.defaultSubcommand, "'.")
      result.command = "normal"
    else:
      let alias = result.validSubcommands[result.defaultSubcommand]
      if alias != "":
        # note, if an alias is used as default subcommand --config is ignored
        discard parseOpts(alias.splitWhitespace(), result, true)
      else:
        result.command = result.defaultSubcommand


when isMainModule:

  var settings = setup()

  debug.log("Settings: ")
  for key, val in settings.fieldPairs:
    debug.log("  ", key, ": ", $val)

  try:
    case settings.command
    of "normal":
      run(settings, single=true, interactive=true)
    of "batch":
      run(settings, single=true, interactive=false)
    of "any":
      run(settings, single=false, interactive=true)
    of "diagnostics":
      writeDiag(settings)
    of "version":
      echo version()
  except OSError as e:
    error.log(e.msg)
    quit(1)
