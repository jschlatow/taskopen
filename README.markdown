#Dependencies

This script is an enhancement to taskwarrior, i.e. it depends on the task binary. See http://www.taskwarrior.org

The perl version also depends on the JSON module, i.e.

 * _libjson-perl_ on debian
 * _perl-json_ on archlinux
 * to be continued...

#What does it do?
It enables you to add file based notes to tasks.

##Basic usage
Add a task:

	$ task add Example

Add an annotation which links to a file:

	$ task 1 annotate ~/notes.txt

Open the linked file by ID:

	$ taskopen 1

Or by a filter expression (requires taskwarrior 2.0):

	$ taskopen Example

## Add default notes

Inspired by Alan Bowens 'tasknote' you can add a default notes file to a task. The folder in which these files will be stored
can be configured in ~/.taskopenrc.

As soon as you annotate a task with 'Notes':

	$ task 1 annotate Notes

...you can edit this file:

	$ taskopen 1

##More complex example
You can also add weblinks to a task and even mix all kinds of annotations:
	
	$ task 1 annotate www.taskwarrior.org
	$ task 1 annotate I want to consider this
	$ task 1 annotate ~/tasknotes/1.txt
	$ taskopen 1
	2 annotation(s) found.

	Please select an annotation:
       1) www.taskwarrior.org
       2) ~/tasknotes/1.txt
    Type number: 

##Link to emails with mutt
Thanks to the contribution of Jostein Berntsen you can use taskopen with mutt. The message ID is used as an identifier for the mutt mail. Here is the basic workflow:

1. Add an email to task with 'mutt2task'
1. Use 'mess2task' to add the message ID from this mail to the recently added task.

taskopen then uses muttjump to open the mutt mailboxes natively or in a screen window (very quick and effective). The muttjump script is made by 
Johannes Weissl:

https://github.com/weisslj/muttjump

You can also use 'mess2task2' which copies the message ID to the clipboard, so that you can add the mail ID to any task manually.

These macros should then be added to mutt:

	macro index ,k "<pipe-message>mutt2task<enter>\  
	<copy-message>+TODO<enter>"
	macro index ,m "<pipe-message>mess2task<enter>"
	macro index ,t "<pipe-message>mess2task2<enter>"

#Installation
Just copy the scripts to /usr/bin or ~/bin.

#Perl version, migration guide
Replace your taskopen binary in /usr/bin or ~/bin with 'taskopen.pl'. Be sure to install all
dependencies.

The perl version is basically backwards compatible with the bash-style taskopenrc files. However,
bash magic must not be used within those files, i.e. only simple 'NAME=VALUE' notations can be
parsed.

#Bash version (deprecated)

You should also copy one of the taskopenrc files to ~/.taskopenrc and modify it to your needs.

Currently there are two different taskopenrc files delivered with taskopen:

1. taskopenrc: default configuration example
1. taskopenrc_vimnotes: configuration to use taskopen with [notes.vim](http://peterodding.com/code/vim/notes/) plugin

#Features (perl version)

##Arbitrary filters
Instead of providing taskopen with an ID you can also pass arbitrary filters in taskwarrior
notation, like:

    $ taskopen +next

or

    $ taskopen +todo pro:taskwarrior

##Labels
You can label your annotations by using the following syntax:

    $ task 1 annotate tw: www.taskwarrior.org
    $ task 1 annotate notes: Notes

In this way, the annotations will be accessible by providing the label name as the last argument,
escaped with double backslashes:

    $ taskopen 1 \\notes

or even

    $ taskopen pro:taskwarrior +bug \\notes

##Options

Only list the files and commands to be executed:

    $ taskopen -l

Open file with editor:

    $ taskopen -e

Execute file:

    $ taskopen -x

Open file with arbitrary command:

    $ taskopen -x 'command arguments'

Show/open only 'Notes':

    $ taskopen -n

Query all active tasks (still excluding deleted and completed ones):

    $ taskopen -a

Query all tasks (including deleted and completed tasks):

    $ taskopen -aa

Please consider that completed and deleted tasks does not have an ID anymore. However, those tasks
are still accessible by their UUID. Using '-aa' might be VERY slow depending on the size of your
database.

Only include files whose filetype (as returned by 'file') match a given regular expression:

    $ taskopen -t 'regex'

Only include annotations that match a given regular expression (excluding labels):

    $ taskopen -m 'regex'

Sorting by taskwarrior fields (as provided by 'task _query'), 'annot' or 'label':

    $ taskopen -s 'label,project,urgency-'

Delete annotation with label 'notes' from task 1:

    $ taskopen -D 1 \\notes

## Even more advanced taskopen fu (examples)

Count lines by executing 'wc -l':

    $ taskopen -x 'wc -l'

Delete orphaned 'Notes'-files, i.e. all files in FOLDER that correspond to deleted or completed
tasks:

    $ taskopen -n -aa -x rm status.is:deleted status.is:completed

**This is a dangerous command which might go wrong if your taskopenrc is not carefully configured.
Please consider adding '-l' to the command line in order to have a dry-run first.**

Or only delete files if the corresponding task has been deleted (not completed):

    $ taskopen -n -aa -x rm status.is:deleted

#Contributions

Thanks to the following:

 * Jostein Bernsten (for adding mutt support)
 * John Hammond (for OSX 10.5+ support)
 * Alan Bowen (for writing tasknote)
 * David J Patrick (for great ideas)

Feel free to contribute to this project.
