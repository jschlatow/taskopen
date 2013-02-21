#Dependencies

This perl script is an enhancement to taskwarrior, i.e. it depends on the task binary. See http://www.taskwarrior.org

It also depends on the JSON module, i.e.

 * _libjson-perl_ on debian
 * _perl-json_ on archlinux
 * to be continued...

#What does it do?
It allows you to link almost any file, webpage or command to a taskwarrior task by adding a filepath, web-link or uri as an annotation. Text notes, images, PDF files, web addresses, spreadsheets and many other types of links can then be filtered, listed and opened by using taskopen. Some actions are sane defaults, others can be custom-configured, and everything else will use your systems mime-types to open the link. 

Arbitrary commands can be used with taskopen at the CLI, acting on the link targets, enhancing listings and even executing annotations as commands.

Run 'taskopen -h' or 'man taskopen' for further details.
The following sections show some (very) basic usage examples. 

##Basic usage
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

#Installation

Installation is as easy as:

    $ make PREFIX=/usr
    $ make PREFIX=/usr install

Taskopen also creates a configuration file at '~/.taskopenrc' if it does not already exist.

You can also add 'DESTDIR=/path/to/dir/' to the install command.

#Perl version, migration guide
Replace your taskopen binary in /usr/bin or ~/bin with 'taskopen.pl'. Be sure to install all
dependencies.

The perl version is basically backwards compatible with the bash-style taskopenrc files. However,
bash magic must not be used within those files, i.e. only simple 'NAME=VALUE' notations can be
parsed.

#Configuration

Taskopen can be customised by editing your ~/.taskopenrc file, where you can set your favourite text editor
and web browser for instance. Every file that is not considered a text file or URI is going to be opened with
'xdg-open', which picks the corresponding application depending on the mime time (see 'xdg-mime').

Please take a look at the manpage taskopenrc(5) for further details.

#Features

  * Arbitrary filters
  * Optional labelling for easier access
  * Execution of arbitrary commands (overriding the default command)
  * Filtering by file type
  * Batch processing and selecting multiple files from a list
  * Deleting and editing of annotations
  * Various customisation options (e.g. sorting)
  * Extensibility

##Arbitrary filters
Instead of providing taskopen with an ID you can also pass arbitrary filters in taskwarrior
notation, like:

    $ taskopen +next

or

    $ taskopen +bug pro:taskwarrior

##Labels
You can label your annotations by using the following syntax:

    $ task 1 annotate tw: www.taskwarrior.org
    $ task 1 annotate notes: Notes

In this way, the annotations will be accessible by providing the label name as the last argument,
escaped with double backslashes:

    $ taskopen 1 \\notes

or even

    $ taskopen pro:taskwarrior +bug \\notes

#Contributions

Thanks to the following:

 * Jostein Bernsten (for adding mutt support)
 * John Hammond (for OSX 10.5+ support)
 * Alan Bowen (for writing tasknote)
 * David J Patrick (for great ideas)

Feel free to contribute to this project.
