import parseopt
import os
import system
import strutils

# taskopen modules
import output
import config

# TODO write module for process execution

# TODO write module for taskwarrior execution

proc writeDiag() =
  echo "Diagnostics not implemented"

proc writeVersion() =
  echo "Version not implemented"

proc writeHelp() =
  echo "Help not implemented"

proc includeActions(valid: openArray[string], includes: string): seq[string] =
  for a in includes.split(','):
    if a in valid:
      result.add(a)

proc excludeActions(valid: openArray[string], excludes: string): seq[string] =
  var excluded = excludes.split(',')
  for a in valid:
    if not (a in excluded):
      result.add(a)

proc normal() =
  error.log("normal not implemented")

proc any() =
  error.log("any not implemented")

proc batch() =
  error.log("batch not implemented")

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
        if len(result.actions) > 0:
          warn.log("Ignoring --include option because --exclude was already specified.")
        else:
          result.actions = includeActions(result.validActions, p.val)

      of "exclude":
        if len(result.actions) > 0:
          warn.log("Ignoring --exclude option because --include was already specified.")
        else:
          result.actions = excludeActions(result.validActions, p.val)

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

  case settings.command
  of "normal":
    normal()
  of "batch":
    batch()
  of "any":
    any()
  of "diagnostics":
    writeDiag()
  of "version":
    writeVersion()
