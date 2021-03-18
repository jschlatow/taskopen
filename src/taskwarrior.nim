import osproc
import strutils

const default_args = ["rc.verbose=blank,label,edit", "rc.json.array=on"]

proc concat[I1, I2: static[int]; T](a: array[I1, T], b: array[I2, T]): array[I1 + I2, T] =
  result[0..a.high] = a
  result[a.len..result.high] = b

proc version*(taskbin: string): string =
  let args = concat(default_args, ["_version"])
  result = execProcess(taskbin, args=args, options = {poUsePath})
  result.stripLineEnd()

