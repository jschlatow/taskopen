#
# Copyright (C) 2021-2022 Johannes Schlatow
#
# This file is part of taskopen, which is distributed under the terms of the
# GNU General Public License version 2.
#

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
    entry*: string
    action*: Action
    env*: StringTableRef

