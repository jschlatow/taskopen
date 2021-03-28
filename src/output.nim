import terminal
import tables
import json
import re
from strutils import split, parseInt, spaces, center, strip
from unicode import runeLen, runeSubStr, alignLeft, align
import ./types
import ./exec

type
  LogLevel* = enum
    debug
    info
    warn
    error

  ColorSetting = tuple
    fg: ForegroundColor
    brightfg: bool
    bg: BackgroundColor
    brightbg: bool
    style: set[terminal.Style]

  LevelColors* = array[debug..error, ColorSetting]

  Align* = enum
    Left
    Center
    Right

  Column* = object
    align*: Align
    width*: Natural


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
        stdout.writeline(indent, "   ", line)

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

proc splitColumn(s: string, w: Positive): seq[string] =
  let length = runeLen(s)

  var i = 0
  while i < length:
    # TODO preferably split at whitespaces
    #      e.g. find whitespace in reverse from i to i-w/2
    #           if none found, cut at i
    var substr = s.runeSubStr(i, w)
    if i > 0:
      substr = substr.strip()
    result.add(substr)
    i += w


proc columnise*(coldef: openArray[Column], indent: Natural, values: varargs[string, `$`]) =

  # first, split input into multiple rows
  var multicols: seq[seq[string]]
  var rowNum = 0

  var col = 0
  for s in values:
    var width = 0
    if len(coldef) > col:
      width = coldef[col].width

    if width == 0:
      width = runeLen(s)

    multicols.add(splitColumn(s, width))
    rowNum = max(len(multicols[^1]), rowNum)
    col += 1

  # flip dimensions of multicols
  var rows: seq[seq[string]]
  for i in 0..rowNum-1:
    var row: seq[string]
    for c in multicols:
      if len(c) > i:
        row.add(c[i])
      else:
        row.add("")

    rows.add(row)

  for row in rows:
    stdout.write(spaces(indent))

    col = 0
    for field in row:
      var style = Column(align: Left, width: 0)
      if len(coldef) > col:
        style = coldef[col]

      if style.width == 0:
        style.width = runeLen(field)

      case style.align
      of Left:
        if col < len(multicols)-1:
          stdout.write(alignLeft(field, style.width))
        else:
          stdout.write(field)
      of Center:
        # FIXME center() is missing in unicode module
        stdout.write(center(field, style.width))
      of Right:
        stdout.write(align(field, style.width))

      col += 1
    stdout.writeline("")


when isMainModule:
  warn.log("Warning: ", "This is ", "shown.")
  debug.log("Debug: ", "This ", "is ", "not ", "shown.")
  error.log("Error: ", "This is ", "an error.")
  error.log("Int ", 1)
  var s = @[1,2,3]
  error.log("Seq ", s)
  let columns = @[Column(align: Left, width: 10), Column(align: Left, width: 3), Column(align: Right, width: 12)]
  columns.columnise(2, "Test", " = " ,"Asdf")
  columns.columnise(2, "Test1234 asdf asdf asdf", " = ", "Asdf")
  columns.columnise(2, "Test1234", " = ", "Asdf foobar foobar foobar foobar")
