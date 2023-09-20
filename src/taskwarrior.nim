#
# Copyright (C) 2021-2022 Johannes Schlatow
#
# This file is part of taskopen, which is distributed under the terms of the
# GNU General Public License version 2.
#

import osproc
import strutils
import re
import json
import ./output

const default_args = ["rc.verbose=blank,label,edit", "rc.json.array=on", "rc.gc=off"]

proc concat[I1, I2: static[int]; T](a: array[I1, T], b: array[I2, T]): array[I1 + I2, T] =
  result[0..a.high] = a
  result[a.len..result.high] = b

template exec(taskbin: string, args: openArray[string], res: untyped) =
  debug.log("Executing: ", taskbin, " ", args.join(" "))
  res = execProcess(taskbin, args=args, options = {poUsePath})
  res.stripLineEnd()

proc version*(taskbin: string): string =
  let args = concat(default_args, ["_version"])
  exec(taskbin, args, result)

proc current_context*(taskbin: string, taskargs: openArray[string]): string =
  let args = @default_args & @taskargs & @["context", "show"]
  exec(taskbin, args, result)
  for line in splitLines(result):
    if line =~ re".*with filter '(.*)' is currently applied.$":
      return "\\(" & matches[0] & "\\)"
    elif line =~ re".*read filter: '(.*)'$":
      return "\\(" & matches[0] & "\\)"
  return ""

proc json*(taskbin: string, taskargs: openArray[string], filter: openArray[string]): JsonNode =
  let args = @default_args & @taskargs & @filter & @["export"]

  debug.log("Executing: ", taskbin, " ", args.join(" "))
  var p = startProcess(taskbin, args=args, options = {poUsePath})
  result = parseJson(outputStream(p))
  p.close()

