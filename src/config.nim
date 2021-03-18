import output
import tables

type
  Action* = object
    target*: string
    regex*: string
    labelregex*: string
    command*: string
    modes*: seq[string]
    filtercommand*: string
    inlinecommand*: string

  Settings* = object
    command*: string
    sort*: string
    basefilter*: string
    filter*: seq[string]
    args*: string
    all*: bool
    validSubcommands*: seq[string]
    defaultSubcommand*: string
    validActions*: OrderedTable[string, Action]
    actions*: seq[string]
    restrictActions*: bool
    inlineCommand*: string
    filterCommand*: string
    forceCommand*: string
    editor*: string
    pathExt*: string
    taskbin*: string
    noAnnot*: string
    taskAttributes*: string
    debug*: bool
    configfile*: string

proc findConfig*(): string =
  # TODO if $TASKOPENRC use this file
  #      elif config file is found in XDG use this
  #      else use ~/.taskopenrc
  ""

proc parseConfig*(filepath: string): Settings =
  # set hardcoded defaults
  result.sort = "urgency-,label,annot"
  result.validSubcommands = @["batch", "any", "normal", "version", "diagnostics"]
  result.defaultSubcommand = "normal"
  result.basefilter = "+PENDING"
  result.taskAttributes = "priority,project,tags,description"
  result.noAnnot = "addnote"
  result.configfile = filepath
  result.validActions["notes"] = Action(
    target: "annotations",
    labelregex: ".*",
    regex: "^[\\.\\/~]+.*\\.(.*)",
    modes: @["batch", "any", "normal"],
    command: "$EDITOR $FILE")

  # TODO set these at compile time depending on target system
  result.editor = "vim"
  result.pathExt = "/usr/share/taskopen/scripts"
  result.taskbin = "task"

  #if filepath != "":
    # TODO read config from file

  for a in result.validActions.keys():
    result.actions.add(a)

proc createConfig*(filepath: string, defaults = Settings()) =
  error.log("createConfig() not implemented")
