import terminal

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

type
  LevelColors* = array[debug..error, ColorSetting]

# TODO add true color support

# default color config
var levelcolors*: LevelColors
levelcolors[debug] = (fgGreen,   false, bgDefault, false)
levelcolors[info]  = (fgDefault, false, bgDefault, false)
levelcolors[warn]  = (fgBlue,    true,  bgDefault, false)
levelcolors[error] = (fgRed,     true,  bgDefault, false)

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

when isMainModule:
  warn.log("Warning: ", "This is ", "shown.")
  debug.log("Debug: ", "This ", "is ", "not ", "shown.")
  error.log("Error: ", "This is ", "an error.")
  error.log("Int ", 1)
  var s = @[1,2,3]
  error.log("Seq ", s)
