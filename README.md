Taskopen was original developed as a simple wrapper script for taskwarrior that enables interaction with annotations (e.g. open, edit, execute files).
The current version is a pretty powerful customisable tool that supports a variety of use cases.
This README serves as a basic getting-started guide including install instructions and examples.
If your are interested in more details, please have a look at the [wiki] or the [man page].

[wiki]: https://github.com/jschlatow/taskopen/wiki/2.0
[man page]: doc/man/taskopen.1.md

# Dependencies

This tool is an enhancement to taskwarrior, i.e. it depends on the task binary. See http://www.taskwarrior.org

Taskopen is implemented in nim (requires at least version 1.4) and does not require any additional modules for compilation.

The helper scripts are usually run by bash. Some of the scripts also depend on (g)awk.

# What does it do?

It allows you to link almost any file, webpage or command to a taskwarrior task by adding a filepath, web-link or uri as an annotation. Text notes, images, PDF files, web addresses, spreadsheets and many other types of links can then be filtered, listed and opened by using taskopen.

Arbitrary actions can be configured with taskopen to filter and act on the annotations or other task attributes.

Run `taskopen -h` or `man taskopen` for further details.
The following sections show some (very) basic usage examples.


## Basic usage

Add a task:

	$ task add Example

Add an annotation which links to a file:

	$ task 1 annotate -- ~/checklist.txt

(Note that the "--" instructs taskwarrior to take the following arguments as the description part
without doing any parser magic.)

Open the linked file by using the task's ID:

	$ taskopen 1

Or by a filter expression:

	$ taskopen Example

## Add default notes

Inspired by Alan Bowens 'tasknote' you can add a default notes file to a task. These files will be
automatically created by the task's UUID and don't require to annotate the task with a specific file path.

As soon as you annotate a task with 'Notes':

	$ task 1 annotate Notes

...you can open and edit this file by:

	$ taskopen 1

...which, by default, opens a file like "~/tasknotes/5727f1c7-2efe-fb6b-2bac-6ce073ba95ee.txt".

**Note:** You have to create the folder "~/tasknotes" before this works with the default folder.

Automatically annotating tasks with 'Notes' can be achieved with 'NO_ANNOTATION_HOOK' as described in
the manpage taskopenrc(5).

## Multiple annotations

You can also add weblinks to a task and even mix all kinds of annotations:

	$ task 1 annotate www.taskwarrior.org
	$ task 1 annotate I want to consider this
	$ task 1 annotate -- ~/Documents/manual.pdf
	$ taskopen 1

Taskopen will determine the actionable annotations and will show a menu to let the user choose what to do:

	Please select an annotation:
       1) www.taskwarrior.org
       2) ~/Documents/manual.pdf
    Type number:

Note, that the default (`normal`) mode of taskopen is to only show the first applicable action for every annotation.
There is also an `any` mode, which presents a menu with _every_ possible action for each annotation.
In `batch` mode, it executes the first applicable action for all annotations.

# Installation

## With Makefile
Installation is as easy as:

```bash
git clone https://github.com/jschlatow/taskopen.git
cd taskopen
make PREFIX=/usr
sudo make PREFIX=/usr install
```

This will install the taskopen binary at `/usr/bin/taskopen`.
For packaging, you can add `DESTDIR=/path/to/dir/` to the install command.

By default, taskopen will recognise any filenames in annotations and open them with `xdg-open` or `open` (on OS X).
Further actions must be specified in a configuration file at `~/.config/taskopen/taskopenrc` or `~/.taskopenrc`.

A default configuration file can be created with `taskopen --config ~/.config/taskopen/taskopenrc`.

## With nimble

t.b.d.


## Migration from taskopen < 2.0 to taskopen >= 2.0

Due to changes in the command line interface and the configuration file, manual intervention is required.
Please have a look at [CLI migration] and [Config migration].

[CLI migration]: https://github.com/jschlatow/taskopen/wiki/CLI#migration
[Config migration]: https://github.com/jschlatow/taskopen/wiki/Configuration#migration

## Configuration basics

In order to customise taskopen to your needs, you may need to adapt its configuration file.

Taskopen tries to find a configuration file at the following locations:

* the path specified in `$TASKOPENRC` environment variable
* `$XDG_CONFIG_HOME/taskopen/taskopenrc` if `$XDG_CONFIG_HOME` is set
* `~/.config/taskopen/taskopenrc`
* `~/.taskopenrc`.

Please also take a look at the manpage [taskopenrc(5)] for the config file syntax.

[taskopenrc(5)]: doc/man/taskopenrc.5.md

# Feature highlights

  * Selecting multiple actions from a list
  * Arbitrary task filters
  * Customised annotation filtering
  * Label-based filtering
  * Filter command hook
  * Inline commands
  * Scripts

## Selecting multiple actions from a list

When presented with a menu of actionable annotations, you can select multiple entries (separated by space) or even ranges, e.g.


	Please select one or multiple actions:
       1) www.taskwarrior.org
       2) ~/Documents/manual.pdf
       3) Notes
       3) ~/Documents/foobar.txt
       3) https://www.github.com
    Type number(s): 1 3-5

## Arbitrary filters

Instead of providing taskopen with an ID you can also pass arbitrary filters in taskwarrior
notation, like:

    $ taskopen +next

or

    $ taskopen +bug pro:taskwarrior

## Customised annotation filtering

Taskopen determines the applicability of an action by matching the annotation against the action's regex.
For instance, multiple file extensions for default notes may be supported by the following action:

```
[Actions]
notes.regex = "^Notes\\.(.*)"
notes.command = "$EDITOR ~/Notes/tasknotes/$UUID.$LAST_MATCH"
```

Note, that taskopen fills the environment variable `$LAST_MATCH` with the part that matches `(.*)`.


## Label-based filtering

You can label your annotations by using the following syntax:

    $ task 1 annotate view: /path/to/file.html
    $ task 1 annotate edit: /path/to/file.html

When specifying an action, a label regex can be distinguish/filter annotations by their label.
A configuration example is found in [examples/label_regex].

[examples/label_regex]: ./examples/label_regex

##Filter command hook

You can specify a filter command that will be executed after the regex matching to determine whether the action really applies to the annotion.
A simple example is to check for file existence:

```
[Actions]
files.regex = "^[\\.\\/~]+.*\\.(.*)"
files.command = "$EDITOR $FILE"
files.filtercommand = "test -e $FILE"
```

An override for all actions can also be provided at the command line.

##Inline commands

Similar to the filter command, the inline command can be used for adding information to the menu.
For instance, to peek show the first five lines of each file with each menu entry, you can add the following to your config file:

```
files.inlinecommand = "head -n5 $FILE"
```

An override for all actions can also be provided at the command line.

## Scripts

Taskopen comes with a bunch of [scripts] that serve as examples to perform more advanced actions, inline commands or filter commands.
Most notably are [addnote] and [editnote].
The former is used by default as the NO_ANNOTATION_HOOK and annotates the task with the given ID with 'Notes'.
The latter can be used to automatically add a header to new notes files.
Please have a look at the scripts or `man taskopen` to find more documentation.

[scripts]: ./scripts
[addnote]: ./scripts/addnote
[editnote]: ./scripts/editnote

## Contributions

Feel free to contribute to this project by opening issues or creating pull requests.
If you are keen to fix any open issues, please have a look at ones labelled with _help wanted_.
