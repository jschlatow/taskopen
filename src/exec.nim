import osproc
import strtabs

proc exec_filter*(cmd: string, env: StringTableRef = nil): bool {.inline.} =
  return execCmdEx(cmd, env=env).exitCode == 0

iterator exec_inline*(cmd: string, env: StringTableRef = nil): string =
  var p = startProcess(cmd, env=env, options={poEvalCommand})
  for line in p.lines:
    yield line
  p.close()

proc exec_cmd*(cmd: string, env: StringTableRef = nil): int {.inline.} =
  let p = startProcess(cmd, env=env, options={poEvalCommand, poParentStreams})
  result= p.waitForExit()
  p.close()

proc exec_all*(cmds: openArray[tuple[cmd: string, env: StringTableRef]]): tuple[num: int, exitCode: int] =
  ## execute all commands and return the number of successfully executed commands

  result.num = 0
  for cmd in cmds:
    let p = startProcess(cmd.cmd, env=cmd.env, options={poEvalCommand, poParentStreams})
    let code = p.waitForExit()
    p.close()
    if code != 0:
      result.exitCode = code
      return result
    inc(result.num)

when isMainModule:
  assert(exec_filter("ls -l"))
  assert(not exec_filter("lasdfasdf -l -a -z"))
  for i in exec_inline("ls -l"):
    echo i
