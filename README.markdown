# Dependencies

This perl script is an enhancement to taskwarrior, i.e. it depends on the task binary. See http://www.taskwarrior.org

It also depends on the JSON module, i.e.

 * _libjson-perl_ on debian
 * _perl-json_ on archlinux
 * _perl-JSON_ on openSUSE
 * to be continued...

The helper scripts are usually run by bash. Some of the scripts also depend on (g)awk.

# What does it do?

It allows you to link almost any file, webpage or command to a taskwarrior task by adding a filepath, web-link or uri as an annotation. Text notes, images, PDF files, web addresses, spreadsheets and many other types of links can then be filtered, listed and opened by using taskopen. Some actions are sane defaults, others can be custom-configured, and everything else will use your systems mime-types to open the link. 

Arbitrary commands can be used with taskopen at the CLI, acting on the link targets, enhancing listings and even executing annotations as commands.

Run 'taskopen -h' or 'man taskopen' for further details.
The following sections show some (very) basic usage examples. 

## Basic usage

Add a task:

	$ task add Example

Add an annotation which links to a file:

	$ task 1 annotate -- ~/checklist.txt

(Note that the "--" instructs taskwarrior to take the following arguments as the description part
without doing any parser magic. This is particularly useful to circumvent bug #819.)

Open the linked file by using the task's ID:

	$ taskopen 1

Or by a filter expression (requires > taskwarrior 2.0):

	$ taskopen Example

## Add default notes

Inspired by Alan Bowens 'tasknote' you can add a default notes file to a task. These files will be
automatically created by the task's UUID and don't require to annotate the task with a specific file
path. The folder in which these files will be stored can be configured in ~/.taskopenrc.

As soon as you annotate a task with 'Notes':

	$ task 1 annotate Notes

...you can open and edit this file by:

	$ taskopen 1

...which, by default, opens a file like "~/tasknotes/5727f1c7-2efe-fb6b-2bac-6ce073ba95ee.txt".

**Note:** You have to create the folder "~/tasknotes" before this works with the default folder.

Automatically annotating tasks with 'Notes' can be achieved with 'NO_ANNOTATION_HOOK' as described in
the manpage taskopenrc(5).

##More complex example
You can also add weblinks to a task and even mix all kinds of annotations:

	$ task 1 annotate www.taskwarrior.org
	$ task 1 annotate I want to consider this
	$ task 1 annotate -- ~/Documents/manual.pdf
	$ taskopen 1

	Please select an annotation:
       1) www.taskwarrior.org
       2) ~/Documents/manual.pdf
    Type number:

# Installation

## Generic

Installation is as easy as:

    $ make PREFIX=/usr
    $ make PREFIX=/usr install

Taskopen also creates a configuration file at '~/.taskopenrc' if it does not already exist.

You can also add 'DESTDIR=/path/to/dir/' to the install command.

You must create the folder '~/tasknotes' when using default notes (e.g. `task 1 annotate Notes`) with the default folder. This folder is not created automatically.

## Linux

### Clone the Repository into your ~/.task directory

```bash
cd $HOME/.task
git clone https://github.com/jschlatow/taskopen.git
```

### Build and Install Taskopen

```bash
make PREFIX=usr
sudo make PREFIX=usr install
```

### Create a Link to the Compiled Taskopen Program

```bash
sudo rm /usr/bin/taskopen
sudo ln -s $HOME/.task/taskopen/taskopen /usr/bin/taskopen
```

*NOTE* if the above steps are not done the below error is printed when trying to envoke taskopen

```bash
-bash: /usr/bin/taskopen: -w: bad interpreter: No such file or directory
```

### Create the tasknotes Directory

```bash
mkdir $HOME/tasknotes
```

*NOTE* that the above uses the default directory, adding NOTES_FOLDER="your_custom_notes_dir" to your ~/.taskopenrc file can change this default directory (you will have to then create that directory as taskopen doesn't by default.

### Finish

You are free to use taskopen (see above for creating notes/default notes/etc)


## Perl version, migration guide
Replace your taskopen binary in /usr/bin or ~/bin with 'taskopen.pl'. Be sure to install all
dependencies.

The perl version is basically backwards compatible with the bash-style taskopenrc files. However,
bash magic must not be used within those files, i.e. only simple 'NAME=VALUE' notations can be
parsed.

## Configuration

Taskopen can be customised by editing your ~/.taskopenrc file, where you can set your favourite text editor
and web browser for instance. Every file that is not considered a text file or URI is going to be opened with
'xdg-open', which picks the corresponding application depending on the mime time (see 'xdg-mime').

A different configuration file can be specified using the TASKOPENRC environment variable.

Please take a look at the manpage taskopenrc(5) for further details.

## Features

  * Arbitrary filters
  * Optional labelling for easier access
  * Execution of arbitrary commands (overriding the default command)
  * Filtering by file type
  * Batch processing and selecting multiple files from a list
  * Deleting and editing of annotations
  * Various customisation options (e.g. sorting)
  * Extensibility

## Arbitrary filters
Instead of providing taskopen with an ID you can also pass arbitrary filters in taskwarrior
notation, like:

    $ taskopen +next

or

    $ taskopen +bug pro:taskwarrior

## Labels
You can label your annotations by using the following syntax:

    $ task 1 annotate tw: www.taskwarrior.org
    $ task 1 annotate notes: Notes

In this way, the annotations will be accessible by providing the label name as the last argument,
escaped with double backslashes:

    $ taskopen 1 \\notes

or even

    $ taskopen pro:taskwarrior +bug \\notes

# Scripts

## attach_vifm (by artur-shaik)

This script helps to attach a file to an existing task or to create a task for an existing file.
The file path can be either given as a command line argument or is interactively selected using `vifm`.

Basic usage:

```
attach_vifm -f file_name -t task_id
```

If you omit `file_name`, `vifm` will be executed. If you omit `task_id`, you will be asked to enter a title for the new task.

Installation with taskwarrior:

```
task config alias.attach "exec '/path/to/attach_vifm' -t"
```

The following commands can be added to vifmrc:

```
command attachnew attach_vifm -f %d/%f
command attach attach_vifm -t %a -f %d/%f
```

# Integration with the `task` command

You can use taskwarrior aliases to create a `task open` command. For example, the below will allow you to open the annotation of a task by typing `task open 123` (where `123` is the id of the task you want to open):

```
alias.open=execute bash -l -x -c "q=($BASH_COMMAND); taskopen \\"\\\\${q[-1]}\\""
```

## Contributions

Thanks to the following:

 * Jostein Bernsten (for adding mutt support)
 * John Hammond (for OSX 10.5+ support)
 * Alan Bowen (for writing tasknote)
 * David J Patrick (for great ideas)
 * Scott Kostyshak (for usability improvements and testing)

Feel free to contribute to this project.
