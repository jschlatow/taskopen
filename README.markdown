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

#Installation
Just copy the script to /usr/bin or ~/bin.

#Contribution
Feel free to contribute to this project.
