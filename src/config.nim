import output
import tables
import ./types

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
  result.validActions["notes"] = Action(
    name: "notes",
    target: "annotations",
    labelregex: ".*",
    regex: "^[\\.\\/~]+.*\\.(.*)",
    modes: @["batch", "any", "normal"],
    inlinecommand: "echo \"$EDITOR $FILE\"",
    filtercommand: "file $FILE | egrep text",
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
