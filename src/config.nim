#
# Copyright (C) 2021-2022 Johannes Schlatow
#
# This file is part of taskopen, which is distributed under the terms of the
# GNU General Public License version 2.
#

import tables
import os
import parsecfg
import streams
import re
import strutils
import ./types
import ./output

# compile time defaults depending on target system
const EDITOR   {.strdefine.}: string = "vim"
const OPEN     {.strdefine.}: string = "xdg-open"
const PATH_EXT {.strdefine.}: string = ""

type
  Settings* = object
    command*: string
    sort*: string
    basefilter*: string
    filter*: seq[string]
    args*: string
    all*: bool
    validSubcommands*: Table[string, string]
    defaultSubcommand*: string
    validActions*: OrderedTable[string, Action]
    actions*: seq[string]
    actionGroups*: Table[string, string]
    restrictActions*: bool
    inlineCommand*: string
    filterCommand*: string
    forceCommand*: string
    editor*: string
    pathExt*: string
    taskbin*: string
    taskargs*: seq[string]
    noAnnot*: string
    taskAttributes*: string
    debug*: bool
    configfile*: string
    unparsedOptions*: seq[string]

proc findConfig*(): string =
  ## find config file using $TASKOPENRC, $XDG_CONFIG_HOME/taskopen/taskopenrc, $HOME/.config/taskopen/taskopenrc or  ~/.taskopenrc

  result = getHomeDir() / ".taskopenrc"
  if getEnv("TASKOPENRC") != "":
    result = getEnv("TASKOPENRC")
  else:
    let path = getConfigDir() / "taskopen" / "taskopenrc"
    if os.fileExists(path):
      result = path

proc `[]=` (a: var Action, key, val: string) =
  case key
  of "target":
    a.target = val
  of "regex":
    a.regex = val
  of "labelregex":
    a.labelregex = val
  of "command":
    a.command = val
  of "modes":
    a.modes = val.split(',')
  of "filtercommand":
    a.filtercommand = val
  of "inlinecommand":
    a.inlinecommand = val


proc parseFile(filepath: string, settings: var Settings) =
  var f = newFileStream(filepath, fmRead)
  if f != nil:
    var p: CfgParser
    var section: string
    open(p, f, filepath)
    while true:
      var e = next(p)
      case e.kind
      of cfgEof: break
      of cfgSectionStart:   ## a ``[section]`` has been parsed
        section = e.section
      of cfgKeyValuePair:
        case section
        of "General":
          case e.key
          of "EDITOR":
            settings.editor = e.value
          of "taskbin":
            settings.taskbin = e.value
          of "taskargs":
            settings.taskargs = e.value.split(' ')
          of "path_ext":
            settings.pathExt = e.value
          of "task_attributes":
            settings.taskAttributes = e.value
          of "no_annotation_hook":
            settings.noAnnot = e.value
          else:
            warn.log("Invalid config option in [General]: ", e.key, ": ", e.value)

        of "Actions":
          if e.key =~ re"(.*)\.(target|regex|labelregex|command|modes|filtercommand|inlinecommand)":
            let actname  = matches[0]
            let actfield = matches[1]
            if not settings.validActions.hasKey(actname):
              settings.validActions[actname] = Action(name: actname,
                                                      target: "annotations",
                                                      modes: @["batch", "any", "normal"],
                                                      labelregex: ".*",
                                                      regex: ".*")

            settings.validActions[actname][actfield] = e.value
          else:
            warn.log("Invalid config option in [Actions]: ", e.key, ": ", e.value)

        of "CLI":
          if e.key == "default":
            settings.defaultSubcommand = e.value
          elif e.key =~ re"(alias|group)\.([^\.]*)":
            let name = matches[1]
            case matches[0]
            of "alias":
              settings.validSubcommands[name] = e.value
            of "group":
              settings.actionGroups[name] = e.value
          else:
            warn.log("Invalid config option in [CLI]: ", e.key, ": ", e.value)
      of cfgOption:
        if section == "General":
          if e.key == "debug": ## handle --debug to switch output level early
            output.level = debug
            settings.debug = true
          else:
            settings.unparsedOptions.add("--" & e.key & "=" & e.value)
      of cfgError:
        error.log(e.msg)
    close(p)
  else:
    error.log("cannot open: ", filepath)


proc createConfig*(filepath: string, defaults = Settings()) =
  var dict=newConfig()

  dict.setSectionKey("General", "taskbin",            defaults.taskbin)
  dict.setSectionKey("General", "taskargs",           defaults.taskargs.join(""))
  dict.setSectionKey("General", "no_annotation_hook", defaults.noAnnot)
  dict.setSectionKey("General", "task_attributes",    defaults.taskAttributes)
  dict.setSectionKey("General", "--sort",             defaults.sort)
  dict.setSectionKey("General", "--active-tasks",     defaults.basefilter)

  if defaults.editor != "":
    dict.setSectionKey("General", "EDITOR",   defaults.editor)

  if defaults.pathExt != "":
    dict.setSectionKey("General", "path_ext", defaults.pathExt)

  if defaults.args != "":
    dict.setSectionKey("General", "--args",   defaults.args)

  if defaults.all:
    dict.setSectionKey("General", "--All",    "on")

  if defaults.inlineCommand != "":
    dict.setSectionKey("General", "--inline-command", defaults.inlineCommand)

  if defaults.filterCommand != "":
    dict.setSectionKey("General", "--filter-command", defaults.filterCommand)

  if defaults.forceCommand != "":
    dict.setSectionKey("General", "--execute",        defaults.forceCommand)

  if defaults.debug:
    dict.setSectionKey("General", "--debug", "on")

  for a in defaults.validActions.keys():
    dict.setSectionKey("Actions", a & ".target",     defaults.validActions[a].target)
    dict.setSectionKey("Actions", a & ".labelregex", defaults.validActions[a].labelregex)
    dict.setSectionKey("Actions", a & ".regex",      defaults.validActions[a].regex)
    dict.setSectionKey("Actions", a & ".command",    defaults.validActions[a].command)
    dict.setSectionKey("Actions", a & ".modes",      defaults.validActions[a].modes.join(","))

  dict.writeConfig(filepath)


proc parseConfig*(filepath: string): Settings =
  # set hardcoded defaults
  result.sort = "urgency-,annot"
  result.validSubcommands["batch"] = ""
  result.validSubcommands["any"] = ""
  result.validSubcommands["normal"] = ""
  result.validSubcommands["version"] = ""
  result.validSubcommands["diagnostics"] = ""
  result.defaultSubcommand = "normal"
  result.basefilter = "+PENDING"
  result.taskAttributes = "priority,project,tags,description"
  result.noAnnot = "addnote $ID"
  result.configfile = filepath
  result.validActions["files"] = Action(
    name: "files",
    target: "annotations",
    labelregex: ".*",
    regex: "^[\\.\\/~]+.*\\.(.*)",
    modes: @["batch", "any", "normal"],
    command: OPEN & " $FILE")
  result.validActions["notes"] = Action(
    name: "notes",
    target: "annotations",
    labelregex: ".*",
    regex: "^Notes(\\..*)?",
    modes: @["batch", "any", "normal"],
    command: "editnote ~/Notes/tasknotes/$UUID$LAST_MATCH \"$TASK_DESCRIPTION\" $UUID")
  result.validActions["url"] = Action(
    name: "url",
    target: "annotations",
    labelregex: ".*",
    regex: "((?:www|http).*)",
    modes: @["batch", "any", "normal"],
    command: OPEN & " $LAST_MATCH")

  result.editor = EDITOR
  result.pathExt = PATH_EXT
  result.taskbin = "task"
  result.taskargs = @[]

  # read config from file
  if filepath != "":
    if fileExists(filepath):
      parseFile(filepath, result)
    else:
      stdout.write("Config file '", filepath, "' does not exist, create it? [y/N]: ")
      let answer = readLine(stdin)
      if answer == "y" or answer == "Y":
        createConfig(filepath, result)

  for a in result.validActions.keys():
    result.actions.add(a)

