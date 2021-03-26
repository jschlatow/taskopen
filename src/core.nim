import os
import re
import strutils
import tables
import strtabs
import json
import sugar
import algorithm

import ./types
import ./config
import ./output
import ./exec
import ./taskwarrior

proc build_env(s: Settings,
               task: JsonNode): StringTableRef =
  result = newStringTable()

  # copy env from parent process
  for k, v in os.envPairs():
    result[k] = v

  if s.pathExt != "":
    result["PATH"] = s.pathExt & ":" & getEnv("PATH")

  if s.editor != "":
    result["EDITOR"] = s.editor

  result["UUID"] = task["uuid"].getStr()

  if task.hasKey("id"):
    result["ID"] = $task["id"].getInt()
  else:
    result["ID"] = ""

  for attr in s.taskAttributes.split(','):
    if task.hasKey(attr):
      result["TASK_" & attr.toUpperAscii()] = task[attr].getStr()


iterator match_actions_label(
  baseenv: StringTableRef,
  text:    string,
  actions: openArray[Action],
  single: bool): (Action, StringTableRef) =

  for act in actions:
    var env = deepCopy(baseenv)
    # split in label and file part
    let splitre = re"((\S+):\s+)?(.*)"
    if text =~ splitre:
      let label = matches[1]
      let file  = matches[2]

      let labelregex = re(act.labelregex)
      let fileregex  = re(act.regex)

      # skip action if label does not match
      if not label.match(labelregex):
        continue

      # skip action if file does not match
      if file =~ fileregex:
        for m in matches:
          if len(m) == 0:
            break
          else:
            env["LAST_MATCH"] = m
      else:
        continue

      env["LABEL"] = label
      if file.startsWith("~"):
        env["FILE"] = file.expandTilde()
      else:
        env["FILE"] = file
      env["ANNOTATION"] = text

      # skip action if filter-command fails
      if act.filtercommand != "":
        if not exec_filter(act.filtercommand, env):
          info.log("Filter command filtered out action ", act.name, " on ", text)
          continue

      yield (act, env)

      if single:
        break
    else:
      error.log("Malformed annotation: ", text)


iterator match_actions_pure(
  baseenv: StringTableRef,
  text:    string,
  actions: openArray[Action],
  single: bool): (Action, StringTableRef) =

  for act in actions:
    var env = deepCopy(baseenv)
    let fileregex  = re(act.regex)
    if text =~ fileregex:
      for m in matches:
        if len(m) == 0:
          break
        else:
          env["LAST_MATCH"] = m
    else:
      continue

    env["FILE"] = text
    env["ANNOTATION"] = text

    # add warning if user specified a labelregex
    if act.labelregex != "":
      warn.log("labelregex is ignored for actions not targetting annotations")

    # skip action if filter-command fails
    if act.filtercommand != "":
      if not exec_filter(act.filtercommand, env):
        info.log("Filter command filtered out action ", act.name, " on ", text)
        continue

    yield (act, env)
    if single:
      break


proc find_actionable_items(
  s:    Settings,
  json: JsonNode,
  mode   = "normal",
  single = true): seq[Actionable] =

  # map attributes to potential actions
  var action_map: Table[string, seq[Action]]
  for actname in s.actions:
    var act = s.validActions[actname]

    # apply overrides
    if s.filterCommand != "":
      act.filtercommand = s.filterCommand
    if s.inlineCommand != "":
      act.inlinecommand = s.inlineCommand
    if s.forceCommand != "":
      act.command = s.forceCommand

    if not (mode in act.modes):
      continue
    if not action_map.hasKey(act.target):
      action_map[act.target] = @[]
    action_map[act.target].add(act)

  # iterate task attributes
  for task in json.items():
    var baseenv = s.build_env(task)
    for attr, val in task.pairs():
      if not action_map.hasKey(attr):
        continue

      if attr == "annotations":
        for ann in val.items():
          let text = ann["description"].getStr()
          for act, env in match_actions_label(baseenv,
                                              text,
                                              action_map[attr],
                                              single=single):
            result.add(Actionable(text: text,
                                  task: task,
                                  action: act,
                                  env: env))
      else:
        let text = val.getStr()
        for act, env in match_actions_pure(baseenv,
                                           text,
                                           action_map[attr],
                                           single=single):
          result.add(Actionable(text: text,
                                task: task,
                                action: act,
                                env: env))


proc sortkeys(sortstr: string): seq[tuple[key: string, desc: bool]] =
  for field in sortstr.split(','):
    if field =~ re"(.*?)(\+|-)?$":
      let key  = matches[0]
      let desc = matches[1] == "-"
      result.add((key: key, desc: desc))


proc run*(settings: Settings, single = true, interactive = true) =
  # construct taskwarrior filter
  let context = current_context(settings.taskbin)
  var filters = @[context] & settings.filter
  if not settings.all:
    filters &= @[settings.basefilter]

  # get json result from taskwarrior
  let json = settings.taskbin.json(filters)

  # find matching actions
  var actionables = settings.find_actionable_items(json, single=single)

  # sort actionables
  let sortkeys = sortkeys(settings.sort)
  actionables.sort do (x, y: Actionable) -> int:
    for field in sortkeys:
      let xhas = x.task.hasKey(field.key)
      let yhas = y.task.hasKey(field.key)

      var res: int
      if field.key == "annot":
        res = cmp(x.text, y.text)
      elif not xhas and not yhas:
        continue
      elif not xhas or not yhas:
        if not xhas:
          res = 1
        else:
          res = -1
      elif field.key in ["id", "urgency"]:
        let xval = x.task[field.key].getInt()
        let yval = y.task[field.key].getInt()
        res = cmp(xval, yval)
      else:
        let xval = x.task[field.key].getStr()
        let yval = y.task[field.key].getStr()
        res = cmp(xval, yval)

      if res == 0:
        continue
      elif field.desc:
        return -1*res
      else:
        return res

    return 0

  if len(actionables) == 0:
    warn.log("No actions applicable.")

  var selected: seq[tuple[cmd: string, env: StringTableRef]]
  if interactive and len(actionables) != 1:
    # run no annotation hook if len(actionables) == 0
    if len(actionables) == 0 and settings.noAnnot != "" and len(json) == 1:
      info.log("Executing no_annotation_hook.")
      if exec_cmd(settings.noAnnot, env=build_env(settings, json[0])) != 0:
        error.log("Failed executing \"", settings.noAnnot, "\".")
      return

    # generate menu
    selected = collect(newSeq):
      for i in menu(actionables):
        (cmd: actionables[i].action.command, env: actionables[i].env)
  else:
    selected = collect(newSeq):
      for a in actionables:
        (cmd: a.action.command, env: a.env)

  # perform selected action(s)
  let res = exec_all(selected)
  if res.exitCode != 0:
    error.log("Command \"", selected[res.num], "\" failed with exit code: ", res.exitCode)
  else:
    info.log(res.num, " commands executed.")
