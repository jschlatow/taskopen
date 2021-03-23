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
  echo "  Actions:"
  echo "    TODO"
  echo "  Subcommands:"
  echo "    default            = ", settings.defaultSubcommand


proc writeHelp() =
  echo "Help not implemented"


proc includeActions(valid: OrderedTable[string, Action], includes: string): seq[string] =
  for a in includes.split(','):
    if valid.hasKey(a):
      result.add(a)


proc excludeActions(valid: OrderedTable[string, Action], excludes: string): seq[string] =
  var excluded = excludes.split(',')
  for a in valid.keys():
    if not (a in excluded):
      result.add(a)


proc setup(configfile:string = ""): Settings =
  output.level = debug

  # first, read the config to get aliases and default options
  if configfile != "":
    result = parseConfig(configfile)
  else:
    result = parseConfig(findConfig())

  # now, parse the command line
  const shortNoVal = { 'v', 'h', 'A' }
  const longNoVal  = @["verbose", "help", "All", ""]
  var p = initOptParser(commandLineParams(),
    shortNoVal=shortNoVal,
    longNoVal=longNoVal)

  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "":
        result.filter.add(p.remainingArgs)
        break

      case p.key
      of "h", "help":
        writeHelp()
        quit()

      of "v", "verbose":
        output.level = LogLevel(min(int(info), int(output.level)))

      of "s", "sort":
        result.sort = p.val

      of "c", "config":
        if configfile == "" and os.fileExists(p.val):
          warn.log("Using alternate config file ", p.val)
          return setup(p.val)
        else:
          # ask user whether to create the config file
          stdout.write("Config file '", p.val, "' does not exist, create it? [y/N]: ")
          let answer = readLine(stdin)
          if answer == "y" or answer == "Y":
            createConfig(p.val, result)

      of "a", "active-tasks":
        result.basefilter = p.val

      of "x", "execute":
        result.forceCommand = p.val

      of "f", "filter-command":
        result.filterCommand = p.val

      of "i", "inline-command":
        result.inlineCommand = p.val

      of "args":
        result.args = p.val

      of "include":
        if result.restrictActions:
          warn.log("Ignoring --include option because --exclude was already specified.")
        else:
          result.actions = includeActions(result.validActions, p.val)
          result.restrictActions = true

      of "exclude":
        if result.restrictActions:
          warn.log("Ignoring --exclude option because --include was already specified.")
        else:
          result.actions = excludeActions(result.validActions, p.val)
          result.restrictActions = true

      of "A", "All":
        result.all = true

    of cmdArgument:
      if result.command == "" and p.key in result.validSubcommands:
        result.command = p.key
      else:
        result.filter.add(p.key)

  if result.command == "":
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
