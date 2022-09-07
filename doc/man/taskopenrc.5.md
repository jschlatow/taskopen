% taskopenrc(5) Taskopen User Manual | Version 2.0

# NAME

taskopenrc - Configuration file for the **taskopen**(1) command

# SYNOPSIS

`~/.taskopenrc`

`~/.config/taskopen/taskopenrc`

`~/$XDG_CONFIG_HOME/taskopen/taskopenrc`

`$TASKOPENRC`

`taskopen -c /path/to/taskopenrc`

# DESCRIPTION

**taskopen** obtains its configuration data from a taskopenrc file from any of
the locations above.

Since version 2.0, taskopen follows a `.ini`-style configuration syntax with
sections, e.g.:

```
[Section]
key=value
```

The config file defines the settings and actions for taskopen. Undefined
settings may be derived from environment variables (e.g. `$EDITOR`). Command
line arguments always take precedence over the config file and environment
variables.

The config file contains three sections specified below: General, Actions and
CLI.


## Section: General

This section defines general (default) settings of taskopen. The following keys
are available in this section and where already present in the perl version of
taskopen.

```
[General]
EDITOR = vim
path_ext = /usr/share/taskopen/scripts
taskbin = task
no_annotation_hook = addnote
task_attributes = "priority,project,tags,description"
```

Note that the config file can be used to specify defaults for any command line
option of taskopen, e.g.:

```
[General]
--sort = "urgency-,label+,annot+"
--active-tasks = "status.is:pending"
--debug = 0
```

## Section: Actions

This section specifies the actions as described **taskopen**(1). An action
consists of a name, a regex, a target, a command, valid modes and, optionally,
a filter command, an inline command and a label regex.

In order to specify these attributes for different actions, taskopen 2.0 uses
`.` in the config keys as separators. The first part then defines the name of
the action, e.g. `name.attribute = value`. The default values are listed below.

```
<name>.target = annotations
<name>.regex = ".*"
<name>.labelregex = ".*"
<name>.command = ""
<name>.modes = "normal,any,batch"
<name>.filtercommand = ""
<name>.inlinecommand = ""
```

Here is an example for specifying the default notes action from earlier
taskopen versions:

```
[Actions]
notes.regex = "Notes"
notes.command = "$EDITOR $HOME/tasknotes/$UUID.txt"
```

Another example shows how to specify commands for editing and deleting
annotations that reference non-existing files:

```
[Actions]
edit.regex = ".*"
edit.command = "raw_edit $ANNOTATION"
edit.filtercommand = "test ! -e $FILE"
delete.regex = ".*"
delete.command = "task $UUID denotate -- \"$ANNOTATION\""
delete.filtercommand = "test ! -e $FILE"
```


Note that taskopen is sensitive to the order in which the actions are specified.
This order determines the priority with which taskopen tries to apply the actions.
This priority can be changed by using the `--include` option.


## Section: CLI

This section can be used to define additional subcommands for the command line
interface of taskopen. It also allows the definition action groups that
simplify referencing multiple actions in the `--include` and `--exclude`
options (see **taskopen**(1)).

As an example, we can specify subcommands as aliases for simple access to the
edit and delete actions via `taskopen edit [filter]` and `taskopen delete
[filter]`, or specify a subcommand `taskopen cleanup [filter]` that includes both:

```
[CLI]
alias.edit = "normal --include=edit"
alias.delete = "normal --include=delete"
alias.cleanup = "any --include=edit,delete"
```

Regarding grouping, we can, e.g., define a group _cleanup_ to combine the edit
and delete action:

```
[CLI]
group.cleanup = "edit,delete"
```

By doing this, we can type `taskopen --include=cleanup` instead of `taskopen
--include=edit,delete`.

Moreover, the default subcommand can be changed:

```
[CLI]
default = any
```

Note that aliases can be used as default subcommand.
Yet, any `--config` within an aliases that is used as a default will be ignored.

## Environment variables

Taskopen evaluates the following environment variables to determine default
settings for some config keys.

* `$TASKOPENRC`: Overrides the default location (`$HOME/.taskopenrc`) of the config file.

# MIGRATION

This sections lists examples of how old taskopen settings from before version
2.0 are converted into the new configuration format. Note that the general
settings only need to be converted into lower case.

| Taskopen 1.x config variable | Taskopen 2.0 config variable |
| :--------------------------- | :----------------------------|
| `EDITOR`                     | `EDITOR`                     |
| `TASK_BIN`                   | `task_bin`                   |
| `PATH_EXT`                   | `path_ext`                   |
| `DEBUG`                      | `--debug`                    |
| `NO_ANNOTATION_HOOK`         | `no_annotation_hook`         |
| `TASK_ATTRIBUTES`            | `task_attributes`            |
| `DEFAULT_FILTER`             | `--active-tasks`             |
| `DEFAULT_SORT`               | `--sort`                     |
| `BROWSER`, `BROWSER_REGEX`   | defined in custom action     |
| `FILE_CMD`, `FILE_REGEX`     | defined in custom action     |
| `NOTES_FOLDER`, `NOTES_EXT`, `NOTES_FILE`, `NOTES_CMD`, `NOTES_REGEX` | defined in custom action |
| `TEXT_REGEX`                 | defined in custom action     |
| `CUSTOM[0-9]+_REGEX`, `CUSTOM[0-9]+_CMD` | defined in custom action     |
| `DEFAULT-i`                  | via action or alias          |
| `DEFAULT-x`                  | via action or alias          |


# CREDITS & COPYRIGHTS

Copyright (C) 2010 - 2022, J. Schlatow

Taskopen is distributed under the GNU General Public License. See
*http://www.opensource.org/licenses/gpl-2.0.php* for more information.

Please also refer to the **AUTHORS** file for a list of contributors.

# SEE ALSO

**taskopen**(1)

For more information regarding taskopen, see the following:

The official site at

:   *\<https://github.com/jschlatow/taskopen/\>*

The official code repository at

:   *\<git://github.com/jschlatow/taskopen.git\>*

The wiki at

:   *\<git://github.com/jschlatow/taskopen.git/wiki\>*

# REPORTING BUGS

Bugs in taskopen may be reported to the issue-tracker at

:   *\<https://github.com/jschlatow/taskopen/issues\>*
