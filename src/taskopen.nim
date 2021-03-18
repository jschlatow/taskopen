import parseopt
import os
import system
import strutils
import distros
import json
import re
import tables
import strtabs

# taskopen modules
import ./output
import ./config
import ./taskwarrior as tw

# TODO write module for process execution

type
  Actionable = object
    text: string
    task: JsonNode
    action: Action
    env: StringTableRef

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

template construct_filter(s: Settings, filters: untyped) =
  let context = current_context(s.taskbin)
  var filters = @[context] & s.filter
  if not settings.all:
    filters &= @[s.basefilter]

proc build_env(s: Settings,
               task: JsonNode): StringTableRef =
  result = newStringTable()

  if s.pathExt != "":
    result["PATH"] = s.pathExt & ":" & getEnv("PATH")
  else:
    result["PATH"] = getEnv("PATH")

  if s.editor != "":
    result["EDITOR"] = s.editor

  result["UUID"] = task["uuid"].getStr()

  if task.hasKey("id"):
    result["ID"] = $task["id"].getInt()
  else:
    result["ID"] = ""

  for attr in s.taskAttributes.split(','):
    if task.hasKey(attr):
      result["TASK_" & attr.toUpperAscii()] = task[attr].getStr()

iterator match_actions(
  baseenv: StringTableRef,
  text:    string,
  actions: openArray[Action],
  single: bool): (Action, StringTableRef) =

  for act in actions:
    if act.target == "annotations":
      var env = deepCopy(baseenv)
      # split in label and file part
      let splitre = re"((\S+):\s+)?(.*)"
      if text =~ splitre:
        let label = matches[1]
        let file  = matches[2]
        debug.log("Label: ", label)
        debug.log("File: ", file)

        let labelregex = re(act.labelregex)
        let fileregex  = re(act.regex)

        # skip action if label does not match
        if not label.match(labelregex):
          continue

        # skip action if file does not match
        if file =~ fileregex:
          for m in matches:
            if len(m) == 0:
              break
            else:
              env["LAST_MATCH"] = m
        else:
          continue

        # skip action if filter-command fails
        if act.filterCommand != "":
          # TODO implement filter-command
          error.log("filter-command not implemented")

        yield (act, env)

        if single:
          break
      else:
        error.log("Malformed annotation: ", text)
    else:
      var env = deepCopy(baseenv)
      let fileregex  = re(act.regex)
      if text =~ fileregex:
        for m in matches:
          if len(m) == 0:
            break
          else:
            env["LAST_MATCH"] = m
      else:
        continue

      # add warning if user specified a labelregex
      if act.labelregex != "":
        warn.log("labelregex not supported for actions not targetting annotations")

      # skip action if filter-command fails
      if act.filterCommand != "":
        # TODO implement filter-command
        error.log("filter-command not implemented")

      yield (act, env)
      if single:
        break

proc find_actionable_items(
  s:    Settings,
  json: JsonNode,
  mode   = "normal",
  single = true): seq[Actionable] =

  # map attributes to potential actions
  var action_map: Table[string, seq[Action]]
  for actname in s.actions:
    var act = s.validActions[actname]

    # apply overrides
    if s.filterCommand != "":
      act.filterCommand = s.filterCommand
    if s.inlineCommand != "":
      act.inlineCommand = s.inlineCommand
    if s.forceCommand != "":
      act.command = s.forceCommand

    if not (mode in act.modes):
      continue
    if not action_map.hasKey(act.target):
      action_map[act.target] = @[]
    action_map[act.target].add(act)

  # iterate task attributes
  for task in json.items():
    var baseenv = s.build_env(task)
    for attr, val in task.pairs():
      if not action_map.hasKey(attr):
        continue

      if attr == "annotations":
        for ann in val.items():
          let text = ann["description"].getStr()
          for act, env in match_actions(baseenv,
                                        text,
                                        action_map[attr],
                                        single=single):
            result.add(Actionable(text: text,
                                  task: task,
                                  action: act,
                                  env: env))
      else:
        let text = val.getStr()
        for act, env in match_actions(baseenv,
                                      text,
                                      action_map[attr],
                                      single=single):
          result.add(Actionable(text: text,
                                task: task,
                                action: act,
                                env: env))

proc normal(settings: Settings) =
  let taskbin = settings.taskbin
  settings.construct_filter(filters)
  let json = taskbin.json(filters)

  var actionables = settings.find_actionable_items(json)
  for item in actionables:
    debug.log(item.text, "  command: ", item.action.command)

  error.log("normal not implemented")

proc any(settings: Settings) =
  let taskbin = settings.taskbin
  settings.construct_filter(filters)
  let json = taskbin.json(filters)

  var actionables = settings.find_actionable_items(json)
  for item in actionables:
    debug.log(item.text, "  command: ", item.action.command)

  error.log("any not implemented")

proc batch(settings: Settings) =
  let taskbin = settings.taskbin
  settings.construct_filter(filters)
  let json = taskbin.json(filters)

  var actionables = settings.find_actionable_items(json)
  for item in actionables:
    debug.log(item.text)

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
      normal(settings)
    of "batch":
      batch(settings)
    of "any":
      any(settings)
    of "diagnostics":
      writeDiag(settings)
    of "version":
      echo version()
  except OSError as e:
    error.log(e.msg)
    quit(1)
