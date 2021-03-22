import strtabs
import json

type
  Action* = object
    name*: string
    target*: string
    regex*: string
    labelregex*: string
    command*: string
    modes*: seq[string]
    filtercommand*: string
    inlinecommand*: string

  Actionable* = object
    text*: string
    task*: JsonNode
    action*: Action
    env*: StringTableRef

