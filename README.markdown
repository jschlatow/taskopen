#Dependencies

This script is an enhancement to taskwarrior, i.e. it depends on the task binary. See http://www.taskwarrior.org

#What does it do?
It enables you to add file based notes to tasks.

##Basic usage
Add a task:

	$ task add Example

Add an annotation which links to a file:

	$ task 1 annotate ~/notes.txt

Open the linked file:

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

#Contribution
Feel free to contribute to this project.
