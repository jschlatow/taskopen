import parseopt
import os
import system
from strutils import indent, split, splitWhitespace, join
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

  var indent = 2

  let env = [Column(align: Left, width: 16),
             Column(align: Left, width: 0)]

  when defined(posix):
    if detectOs(MacOSX):
      env.columnise(indent, "Platform: ", "Mac OSX")
    elif detectOs(Linux):
      env.columnise(indent, "Platform: ", "Linux")
  when defined(windows):
    env.columnise(indent, "Platform: ", "Windows")

  env.columnise(indent, "Taskopen: ",      version())
  env.columnise(indent, "Taskwarrior: ",   tw.version(settings.taskbin))
  env.columnise(indent, "Configuration: ", settings.configfile)

  echo "Current configuration"
  echo(indent("Binaries and paths:", indent))
  indent += 2

  var cfg = [Column(align: Left, width: 18),
             Column(align: Left, width: 3),
             Column(align: Left, width: 54)]

  cfg.columnise(indent, "taskbin",   " = ", settings.taskbin)
  cfg.columnise(indent, "taskargs",  " = ", settings.taskargs.join(" "))
  cfg.columnise(indent, "editor",    " = ", settings.editor)
  cfg.columnise(indent, "path_ext",  " = ", settings.pathExt)

  echo(indent("General:", indent-2))
  cfg.columnise(indent, "debug",              " = ", settings.debug)
  cfg.columnise(indent, "no_annotation_hook", " = ", settings.noAnnot)
  cfg.columnise(indent, "task_attributes",    " = ", settings.taskAttributes)

  echo(indent("Action groups:", indent-2))
  for group, actions in settings.actionGroups.pairs():
    cfg.columnise(indent, group, " = ", actions)

  echo(indent("Subcommands:", indent-2))
  cfg.columnise(indent, "default", " = ", settings.defaultSubcommand)
  for sub, alias in settings.validSubcommands.pairs():
    if alias != "":
      cfg.columnise(indent, sub, " = ", alias)

  cfg[0].width -= 2
  echo(indent("Actions:", indent-2))
  for action in settings.validActions.values():
    echo(indent(action.name, indent))
    cfg.columnise(indent+2, ".target",     " = ", action.target)
    cfg.columnise(indent+2, ".regex",      " = ", action.regex)
    cfg.columnise(indent+2, ".labelregex", " = ", action.labelregex)
    cfg.columnise(indent+2, ".command",    " = ", action.command)
    cfg.columnise(indent+2, ".modes",      " = ", action.modes.join(","))

    if action.inlinecommand != "":
      cfg.columnise(indent+2, ".inlinecommand", " = ", action.inlinecommand)
    if action.filtercommand != "":
      cfg.columnise(indent+2, ".filtercommand", " = ", action.filtercommand)


proc writeHelp() =
  echo("Usage: ", getAppFilename(), " [subcommand] [options] [filter1 filter2 .. filterN]")

  let indent  = 2
  var columns = [Column(align: Left, width: 28),
                 Column(align: Left, width: 49)]

  echo("")
  echo("Available options:")
  columns.columnise(indent, "-h, --help",    "Show this text.")
  columns.columnise(indent, "-v, --verbose", "Print additional info messages.")
  columns.columnise(indent, "--debug",       "Print debug messages (includes -v).")

  columns.columnise(indent, "-s, --sort 'key1+,key2-'",  "Defines the sort order of actionable items.")
  columns.columnise(indent, "-c, --config \"filepath\"",   "Use a different config file.")
  columns.columnise(indent, "-a, --active-tasks 'filter'", "Changes the filter to determine active tasks.")
  columns.columnise(indent, "-A, --All",                   "Query all tasks (ignores taskwarrior context and active task filter).")

  columns.columnise(indent, "-x, --execute 'cmd'", "Overrides the command executed for every action.")
  columns.columnise(indent, "-f, --filter-command 'cmd'", "Overrides filter command for every action.")
  columns.columnise(indent, "-i, --inline-command 'cmd'", "Overrides inline command for every action.")
  columns.columnise(indent, "--args 'arguments'", "Defines arguments that will be available as $ARGS in any command.")

  columns.columnise(indent, "--include action1,action2", "Only consider the listed actions. Also determines their priority.")
  columns.columnise(indent, "--exclude action1,action2", "Consider all but the listed actions.")


  columns[0].width -= 12
  columns[1].width += 12

  echo("")
  echo("Available subcommands:")
  columns.columnise(indent, "normal",      "Shows a menu of the first applicable action for each annotation. Default subcommand.")
  columns.columnise(indent, "any",         "Shows a menu for every applicable action for each annotation.")
  columns.columnise(indent, "batch",       "Executes the first applicable action for each annotation without showing an interactive menu before.")
  columns.columnise(indent, "diagnostics", "Print diagnostic output.")
  columns.columnise(indent, "version",     "Print version information.")

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
