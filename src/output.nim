import terminal
import tables
import json
import re
import strutils
import ./types
import ./exec

type
  LogLevel* = enum
    debug
    info
    warn
    error

type
  ColorSetting = tuple
    fg: ForegroundColor
    brightfg: bool
    bg: BackgroundColor
    brightbg: bool
    style: set[terminal.Style]

type
  LevelColors* = array[debug..error, ColorSetting]

# TODO add true color support

# default color config
var levelcolors*: LevelColors
levelcolors[debug] = (fgGreen,   false, bgDefault, false, {})
levelcolors[info]  = (fgDefault, false, bgDefault, false, {})
levelcolors[warn]  = (fgBlue,    true,  bgDefault, false, {})
levelcolors[error] = (fgRed,     true,  bgDefault, false, {})

# TODO make colors configurable
var colorstyles = {"action":    (fg: fgYellow,
                                 brightfg: false,
                                 bg: bgDefault,
                                 brightbg: false,
                                 style: {styleUnderscore}),
                   "number":    (fg: fgGreen,
                                 brightfg: false,
                                 bg: bgDefault,
                                 brightbg: false,
                                 style: {}),
                   "annot":     (fg: fgWhite,
                                 brightfg: false,
                                 bg: bgDefault,
                                 brightbg: false,
                                 style: {styleDim}),
                   "desc":      (fg: fgDefault,
                                 brightfg: false,
                                 bg: bgDefault,
                                 brightbg: false,
                                 style: {styleItalic}),
                   "separator": (fg: fgGreen,
                                 brightfg: false,
                                 bg: bgDefault,
                                 brightbg: false,
                                 style: {}),
                   "id":        (fg: fgDefault,
                                 brightfg: false,
                                 bg: bgDefault,
                                 brightbg: false,
                                 style: {})
                  }.newTable()

var level* = warn

let coloredout = isatty(stdout)
let colorederr = isatty(stderr)

template log*(lvl: LogLevel = info, v: varargs[string, `$`]) =
  var f = stdout
  var colored = coloredout
  if lvl >= error:
    f = stderr
    colored = colorederr

  if lvl >= level:
    if colored:
      f.setForegroundColor(levelcolors[lvl].fg, levelcolors[lvl].brightfg)
      f.setBackgroundColor(levelcolors[lvl].bg, levelcolors[lvl].brightbg)
      for s in v:
        f.write(s)
      terminal.styledWriteLine(f, resetStyle)
    else:
      for s in v:
        f.write(s)
      f.write("\n")

template colorout(s: string, v: varargs[string, `$`]) =
  if coloredout and s in colorstyles:
    stdout.setStyle(colorstyles[s].style)
    stdout.setForegroundColor(colorstyles[s].fg, colorstyles[s].brightfg)
    stdout.setBackgroundColor(colorstyles[s].bg, colorstyles[s].brightbg)
    for str in v:
      stdout.write(str)
    terminal.styledWrite(stdout, resetstyle)
  else:
    for str in v:
      stdout.write(str)


proc menu*(items: openArray[Actionable]): seq[int] =
  colorout("default", "Please select one or multiple actions:\n")
  for i, item in items.pairs():
    let indent = " "
    if i+1 >= 10:
      stdout.write(indent[0..^1])
    else:
      stdout.write(indent)

    colorout("number", i+1, ")")
    stdout.write(" ")
    colorout("action",  item.action.name, ":")
    stdout.write(" ")
    colorout("annot", item.text)
    stdout.write("\n", indent, "   ")
    colorout("desc", "(\"", item.task["description"].getStr(), "\")")
    if item.task.hasKey("id"):
      stdout.write(" ")
      colorout("separator", "--")
      stdout.write(" ")
      colorout("id", item.task["id"].getInt())
    stdout.write("\n")

    # output command to be executed
    info.log(indent, "   ", "command: ", item.action.command)

    if item.action.inlinecommand != "":
      for line in exec_inline(item.action.inlinecommand, item.env):
        stdout.write(indent, "   ", line)
      stdout.write("\n")

  stdout.write("Type number(s): ")
  let answer = readLine(stdin)
  let maxid  = len(items)
  for ids in answer.split():
    if ids =~ re"(\d+)(?:\.\.|-)(\d+)":
      let fromid = parseInt(matches[0])
      let toid   = parseInt(matches[1])
      if fromid < 1 or fromid > maxid:
        error.log(fromid, " is an invalid number")
        quit(1)
      if toid < 1 or toid > maxid:
        error.log(toid, " is an invalid number")
        quit(1)
      if fromid >= toid:
        error.log(ids, " is an invalid range")
        quit(1)
      for id in fromid..toid:
        result.add(id-1)
    elif ids =~ re"\d+":
      let id = parseInt(ids)
      if id < 1 or id > maxid:
        error.log(id, " is an invalid number")
        quit(1)
      result.add(id-1)
    else:
      error.log(ids, " is not a number or a range")

when isMainModule:
  warn.log("Warning: ", "This is ", "shown.")
  debug.log("Debug: ", "This ", "is ", "not ", "shown.")
  error.log("Error: ", "This is ", "an error.")
  error.log("Int ", 1)
  var s = @[1,2,3]
  error.log("Seq ", s)
