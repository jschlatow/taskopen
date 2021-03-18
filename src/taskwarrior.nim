import osproc
import strutils
import re
import json

const default_args = ["rc.verbose=blank,label,edit", "rc.json.array=on"]

proc concat[I1, I2: static[int]; T](a: array[I1, T], b: array[I2, T]): array[I1 + I2, T] =
  result[0..a.high] = a
  result[a.len..result.high] = b

template exec(taskbin: string, args: openArray[string], res: untyped) =
  res = execProcess(taskbin, args=args, options = {poUsePath})
  res.stripLineEnd()

proc version*(taskbin: string): string =
  let args = concat(default_args, ["_version"])
  exec(taskbin, args, result)

proc current_context*(taskbin: string): string =
  let args = concat(default_args, ["context", "show"])
  exec(taskbin, args, result)
  if result =~ re".*with filter '(.*)' is currently applied.$":
    result = "'(" & matches[0] & ")'"
  else:
    result = ""

proc json*(taskbin: string, filter: openArray[string]): JsonNode =
  let args = @default_args & @filter & @["export"]
  var output: string
  exec(taskbin, args, output)
  result = parseJson(output)
