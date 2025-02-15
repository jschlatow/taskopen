% taskopen(1) Taskopen User Manual | Version 2.0

# NAME

taskopen - A companion application for taskwarrior that augments
annotation handling.

# SYNOPSIS

`taskopen [subcommand] [options] [filter1 filter2 .. filterN]`

# DESCRIPTION

Any task in taskwarrior can have zero-or-more annotations. Originally, taskopen
was created to extend the functionality of taskwarrior with respect to
annotations. As taskwarrior lacks multi-line annotations, the idea was to
_attach_ a notes file to a task and make it accessible by taskopen instead. In
more general terms, taskopen is able to perform arbitrary actions on tasks by
executing external commands. The actions applicable to a task are determined by
filtering its annotations (or any other task attribute).

In order to customise this, taskopen is configured with a set of filters,
actions and operation modes, see **taskopenrc**(5). When executed, it passes the
given filter to taskwarrior, and presents the user with a set of actions that
it considers applicable to the returned tasks.

## Filters

Taskwarrior has a large feature set for [filtering] on a task-level basis for
generating the reports (task list). However, as taskopen may offer multiple
(and different) actions for individual task attributes and annotations, it must
perform additional filtering.

In a first stage, the task filter is provided to taskopen on the command line
and passed to taskwarrior to limit the set of considered tasks. In a second
stage, taskopen checks what actions are applicable to these tasks (i.e. their
attributes).

By default, taskopen operates on the task annotations. As a generalisation,
other attributes can be processed and filtered to determine the applicable
actions.

[filtering]: https://taskwarrior.org/docs/filter.html

### Annotations

An annotation in taskwarrior is a single-line of arbitrary text with
a timestamp. A task can have multiple of these annotations. For taskopen, the
following format of annotations has been established:

	label: arbitrary text (e.g. url, file path)

The label part is optional and used for further filtering (e.g. to distinguish
different actions on the same annotation). Taskopen used the following perl
regex for this:

	(?:(\S+):\s+)?(.*)

The first match is called the _label part_ whereas the second match is the _file part_.
Taskopen 2.0 allows filtering of both parts via regular expressions.

### Arbitrary attributes

A task in taskwarrior has various attributes (e.g. project, tags, description).
Taskwarrior even supports user-defined attributes (UDAs), which can for
instance be used to link to an issue id of a bug tracker. It therefore appears
natural to use taskopen also for defining actions on UDAs. In contrast to
annotation filtering, there is only a single regular expression that is matched
against the attribute's value.

## Actions

An action defines what taskopen shall do with the filtered
annotations/attributes. It is defined by four parameters: _target_, _regex_,
_command_ and _modes_. The _target_ specifies for what task attribute the
action is defined. The _regex_ defines the regular expression(s) used for
determining valid annotations/attributes. The _command_ determines the command
line that implements the actual action. The following placeholders for defining
the command line exist:

`$ANNOTATION`
: the undecoded (raw) annotation text

`$LABEL`
: the label part of the annotation text

`$FILE`
: the file part of the annotation text

`$UUID`
: the UUID of the task

`$ID`
: the running ID of the task

`$ENTRY`
: the entry date-time of the annotation

`$LAST_MATCH`
: the last sub-pattern of the regular expression used for filtering

`$TASK_*`
: any task attribute (e.g. `$TASK_PROJECT`) or UDA

`$ARGS`
: user-defined arguments specified on the taskopen command line

The _modes_ of an action is a list of valid modes in which the action is
applicable (see next section). Optionally (for extensibility),
a _filtercommand_ can be specified to implement additional filters such as file
type checking. Furthermore, an _inlinecommand_ can be defined to execute
a particular command for every actionable annotation and display its output
interleaved with the list of actionable annotations. If an action targets
annotations, a _labelregex_ may specify a regular expressions that is applied
to the label part. For a detailed descripton of the configuration, please refer
to **taskopenrc**(5).

## Operation modes

Taskopen implements multiple modes of operation:

normal mode
: In _normal mode_, taskopen shows a list of actionable annotations and
  executes the first matching action for the annotation selected by the user.

batch mode
: In _batch mode_, taskopen performs the first matching action
  on every actionable annotation.

any mode
: Taskopen 2.0 introduced an additional _any mode_ similar to normal mode that
  presents the user with all matching actions to choose from instead of only the
  first matching action.

Note that earlier versions of taskopen also supported modes for editing
annotations and deleting annotations. Since taskopen 2.0, these are implemented
by actions.


# OPTIONS

Options of taskopen are subdivided into four categories: output control, config
overrides, includes/excludes, and filter control.

A special case for `--config` is when the config file does not exist. Taskopen
will ask the user whether the config file with default values shall be created.

For some options, there exists a short variant (`-`) and a long variant (`--`).
Provided values must be separated by a `:` or `=` when using the short variant.

## Output control

`-v/--verbose`
: Prints additional info messages (e.g. the command line to be executed by taskopen).

`--debug`
: Prints debug messages (includes `-v`).

`-h/--help`
: Prints help message.

## Config overrides

`-s=/--sort=key1+,key2-`
: Changes the default sort order of annotations.

`-c=/--config=filepath`
: Use a different config file.

`-a=/--active-tasks=filter`
: Changes the filter used by taskopen to determine active tasks.

`-x=/--execute=cmd`
: Overrides the command executed by taskopen for every action.

`-f=/--filter-command=cmd`
: Overrides filter command for every action.

`-i=/--inline-command=cmd`
: Overrides inline command for every action.

`--args=arguments`
: Allows definition of arguments that will be available as `$ARGS` in taskopen actions.

## Includes/excludes

`--include=action1,action2`
: Only consider the listed actions. Also determines their priority.

`--exclude=action1,action2`
: Consider all but the listed actions.

## Filter control

`-A/--All`
: Query all tasks, including completed and deleted tasks.


# SUBCOMMANDS

The modes of taskopen are made accessible via subcommands. By default, taskopen
operates in normal mode. In addition to the following subcommands, custom aliases
can be defined in order to provide a short hand for common command line options.

`batch`
:  Switches into batch mode.

`any`
:  Switches into any mode.

`version`
:  Prints version information.

`diagnostics`
:  Prints diagnostics (e.g. configured actions, aliases, etc.)


# MIGRATION FROM TASKOPEN 1.x

The following table compares command line arguments of taskopen 1.x with taskopen 2.0.
Note that the `--include/--exclude` options require the definition of the appropriate actions
in your config file. Moreover, you are able to define aliases for convenience
(see **taskopenrc**(5)).


|         Taskopen 1.x         |         Taskopen 2.0         |
| :--------------------------- | :--------------------------- |
| `-h`                         | `-h` or `--help`             |
| `-v`                         | `version`                    |
| `-V`                         | `diagnostics`                |
| `-l`                         | `-x` or `--execute`          |
| `-L`                         | `-v` or `--verbose`          |
| `-b`                         | `batch`                      |
| `-n`                         | `--include=notes`            |
| `-N`                         | `--exclude=notes`            |
| `-f`                         | `--include=files`            |
| `-F`                         | `--exclude=files`            |
| `-B`                         | `-f='test ! -e $FILE`        |
| `-t`                         | `--include=text`             |
| `-T`                         | `--exclude=text`             |
| `-a`                         | `-a`                         |
| `-A`                         | `-A`                         |
| `-D`                         | `--include=delete`           |
| `-r`                         | `--include=raw`              |
| `-m 'regex'`                 | `/regex/`                    |
| `--type 'regex'`             | `-f="file $FILE \| perl -ne 'if($_ !~ m/regex/){exit 1}'"` |
| `-s key1+,key2-`             | `-s=key1+,key2-`             |
| `-e`                         | `-x='vim $FILE'`             |
| `-x 'cmd'`                   | `-x='cmd'`                   |
| `-i 'cmd'`                   | `-i='cmd'`                   |
| `-c filepath`                | `-c=filepath`                |
| `-p cmd`                     | automatic detection          |


# FILES

`~/.taskopenrc`

:   User configuration file - see also **taskopenrc**(5).

`~/.config/taskopen/taskopenrc`

:   Alternative location of user configuration file. Takes precedence over the locations listed above.

`~/$XDG_CONFIG_HOME/taskopen/taskopenrc`

:   Alternative location of user configuration file. Takes precedence over the locations listed above.

`$TASKOPENRC`

:   If set, the configuration file is loaded from the location specified by the environment variable `$TASKOPENRC`.


# HISTORY

**2010 - 2012**

:   The first release of taskopen was a quite simple bash script.

**early 2013**

:   Re-implementation of taskopen in perl.

**early 2021**

:   Re-implementation of taskopen in nim.

**mid 2022**

:   Release of taskopen 2.0.


# CREDITS & COPYRIGHTS

Copyright (C) 2010 - 2022, J. Schlatow

Taskopen is distributed under the GNU General Public License. See
*http://www.opensource.org/licenses/gpl-2.0.php* for more information.

Please also refer to the **AUTHORS** file for a list of contributors.


# SEE ALSO

**taskopenrc**(5)

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
