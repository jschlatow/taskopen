import output

type
  Settings* = object
    command*: string
    sort*: string
    basefilter*: string
    filter*: seq[string]
    args*: string
    all*: bool
    validSubcommands*: seq[string]
    defaultSubcommand*: string
    validActions*: seq[string]
    actions*: seq[string]
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
  result.basefilter = "status.is:pending"
  result.taskAttributes = "priority,project,tags,description"
  result.noAnnot = "addnote"
  result.configfile = filepath

  # TODO set these at compile time depending on target system
  result.editor = "vim"
  result.pathExt = "/usr/share/taskopen/scripts"
  result.taskbin = "task"

  #if filepath != "":
    # TODO read config from file

proc createConfig*(filepath: string, defaults = Settings()) =
  error.log("createConfig() not implemented")
