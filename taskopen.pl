#!/usr/bin/perl -w

###############################################################################
# taskopen - file based notes with taskwarrior
#
# Copyright 2010-2013, Johannes Schlatow.
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the
#
#     Free Software Foundation, Inc.,
#     51 Franklin Street, Fifth Floor,
#     Boston, MA
#     02110-1301
#     USA
#
###############################################################################

use JSON qw( decode_json );     # From CPAN
use POSIX;
use strict;
use warnings;

# DON'T TOUCH THE FOLLOWING LINES
my $VERSION="v1.0-perl-release-31-gf79a915";
my $REVNUM="89";
my $REVHASH="f79a915";
# END-DON'T-TOUCH

my $HOME = $ENV{"HOME"};
my $XDG = "xdg-open";

if ($^O =~ m/.*darwin.*/) { #OSX
   $XDG = "open";
}

my $cfgfile = "$HOME/.taskopenrc";

# find alternative config file specification in argument list
for (my $i = 0; $i <= $#ARGV; ++$i) {
    my $arg = $ARGV[$i];
    if ($arg eq "-c") {
        $cfgfile = $ARGV[++$i];
        $cfgfile =~ s/^~/$HOME/;
        print "Using alternate config file $cfgfile\n";
        last;
    }
}

my %config;
open(CONFIG, "$cfgfile") or die "can't open $cfgfile: $!";
while (<CONFIG>) {
    chomp;
    s/#.*//; # Remove comments
    s/^\s+//; # Remove opening whitespace
    s/\s+$//;  # Remove closing whitespace
    next unless length;
    my ($key, $value) = split(/\s*=\s*/, $_, 2);
    $value =~ s/"(.*)"/$1/;
    $value =~ s/'(.*)'/$1/;
    $config{$key} = $value;
}

my $TASKBIN;
if (exists $config{"TASKBIN"}) {
    $TASKBIN = $config{"TASKBIN"};
}
else {
    $TASKBIN = '/usr/bin/task';
}

my $FOLDER;
if (exists $config{"FOLDER"}) {
    $FOLDER = $config{"FOLDER"};
}
else {
    $FOLDER = "~/tasknotes/";
}

my $EXT;
if (exists $config{"EXT"}) {
    $EXT = $config{"EXT"};
}
else {
    $EXT = ".txt";
}

my $BROWSER;
if (exists $config{"BROWSER"}) {
    $BROWSER = $config{"BROWSER"};
}
else {
    $BROWSER = $XDG;
}

my $EDITOR;
if (exists $config{"EDITOR"}) {
    $EDITOR = $config{"EDITOR"};
}
else {
    $EDITOR = "vim";
}

my $NOTES_FILE;
if (exists $config{"NOTES_FILE"}) {
    $NOTES_FILE = $config{"NOTES_FILE"};
}
else {
    $NOTES_FILE = "${FOLDER}UUID$EXT";
}

my $NOTES_CMD;
if (exists $config{"NOTES_CMD"}) {
    $NOTES_CMD = $config{"NOTES_CMD"};
}
else {
    $NOTES_CMD = "$EDITOR $NOTES_FILE";
}

my $EXCLUDE;
if (exists $config{"EXCLUDE"}) {
    $EXCLUDE = $config{"EXCLUDE"};
}
else {
    $EXCLUDE = "status.is:pending";
}

my $DEBUG;
if (exists $config{"DEBUG"} && $config{"DEBUG"} =~ m/\d+/) {
    $DEBUG = $config{"DEBUG"};
}
else {
    $DEBUG = 0;
}

my $SORT;
if (exists $config{"SORT"}) {
    $SORT = $config{"SORT"};
}
else {
    $SORT = "";
}

my $NOTES_REGEX;
if (exists $config{"NOTES_REGEX"}) {
    $NOTES_REGEX = $config{"NOTES_REGEX"};
}
else {
    $NOTES_REGEX = "Notes";
}

my $BROWSER_REGEX;
if (exists $config{"BROWSER_REGEX"}) {
    $BROWSER_REGEX = $config{"BROWSER_REGEX"};
}
else {
    $BROWSER_REGEX = "www|http";
}

my $FILE_REGEX;
if (exists $config{"FILE_REGEX"}) {
    $FILE_REGEX = $config{"FILE_REGEX"};
}
else {
    $FILE_REGEX = "\\\.|\\\/|~";
}

my $CUSTOM1_REGEX;
if (exists $config{"CUSTOM1_REGEX"}) {
    $CUSTOM1_REGEX = $config{"CUSTOM1_REGEX"};
}
else {
    $CUSTOM1_REGEX = "";
}

my $CUSTOM2_REGEX;
if (exists $config{"CUSTOM2_REGEX"}) {
    $CUSTOM2_REGEX = $config{"CUSTOM2_REGEX"};
}
else {
    $CUSTOM2_REGEX = "";
}

my $CUSTOM1_CMD;
if (exists $config{"CUSTOM1_CMD"}) {
    $CUSTOM1_CMD = $config{"CUSTOM1_CMD"};
}
else {
    $CUSTOM1_CMD = "";
}

my $CUSTOM2_CMD;
if (exists $config{"CUSTOM2_CMD"}) {
    $CUSTOM2_CMD = $config{"CUSTOM2_CMD"};
}
else {
    $CUSTOM2_CMD = "";
}

my $REGEX_CODE = "fbn";
if ($CUSTOM1_REGEX) {
    $REGEX_CODE = "${REGEX_CODE}1";
}
if ($CUSTOM2_REGEX) {
    $REGEX_CODE = "${REGEX_CODE}2";
}

sub print_version {
    print "\n";
    print "Taskopen, release $VERSION, revision $REVNUM ($REVHASH)\n";
    print "Copyright 2010-2013, Johannes Schlatow.\n";
    print "\n";
}

sub parse_number {
    my $input = $_[0];
    my $max   = $_[1];

    my @items = split(m/[^\d\.-]+/, $input);
    if ($#items >= 0) {
        my @result;
        foreach my $item (@items) {
            if ($item =~ m/(\d+)(?:\.\.|-)(\d+)/) {
                my $start = $1;
                my $end   = $2;
                if ($start < 1 || $end > $max) {
                    print qq/"$item" is an invalid range\n/;
                    exit 1;
                }
                while ($start <= $end) {
                    push(@result, $start);
                    $start++;
                }
            }
            elsif ($item =~ m/\d+/) {
                if ($item < 1 || $item > $max) {
                    print qq/"$item" is an invalid number\n/;
                    exit 1;
                }
                push(@result, $item);
            }
            else {
                print qq/"$item" is not a number\n/;
                exit 1;
            }
        }
        return @result;
    }
    else {
        print qq/Invalid input "$input"\n/;
        exit 1;
    }
}

sub get_filepath {
    my $ann = $_[0];
    my $file = $ann->{"annot"};
    
    if ($file =~ m/$NOTES_REGEX/) {
        $file = $NOTES_FILE;
        $file =~ s/UUID/$ann->{"uuid"}/g;
    }

   $file =~ s/^~/$HOME/;

   return $file;
}

sub raw_edit {
    my $old = $_[0];

    my $filename = tmpnam();
    open(FILE, ">$filename") or die "can't open $filename: $!";
    print(FILE $old);
    close(FILE); 

    system(qq/$EDITOR "$filename"/);

    open(FILE, "<$filename") or die "can't open $filename: $!'";
    my @lines = <FILE>;
    close(FILE);
    unlink($filename);

    # taskwarrior does not support multi-line annotations
    # TODO fix if #1172 has been solved
    
    my $result = $lines[0];
    chomp($result);
    return $result;
}

sub create_cmd {
    my $ann = $_[0];
    my $FORCE = $_[1];
    my $file = $ann->{"annot"};

    if ($FORCE->{"action"}) {
        if ($FORCE->{"action"} eq "\\del") {
            # TODO remove as soon as tw bug #819 has been fixed
            if ($ann->{'raw'} =~ m/(\/|\(|\))/) { # match all characters after which tw keeps adding spaces
                return qq/echo "There is a bug in taskwarrior (#819) which prevents doing this."/
            }
            # END REMOVE
            return qq/$TASKBIN $ann->{'uuid'} denotate "$ann->{'raw'}"/;
        }
        elsif ($FORCE->{"action"} eq "\\raw") {
            my $raw = raw_edit($ann->{"raw"});
            if ($raw ne $ann->{"raw"}) {
                # TODO remove as soon as tw bug #1174 has been fixed
                if ($ann->{'raw'} =~ m/\// || $raw =~ m/\//) {
                    return qq{echo "Cannot replace annotations which contain '/'s (see #1174)."}
                }
                # END REMOVE
                return qq%$TASKBIN $ann->{"uuid"} mod /$ann->{"raw"}/$raw/%;
            }
            else {
                return qq/echo "No changes detected"/;
            }
        }
        else {
            $file = get_filepath($ann);
            return qq/$FORCE->{"action"} "$file"/;
        }
    }

    my $cmd;
    if ($file =~ m/$NOTES_REGEX/) {
        $cmd = $NOTES_CMD;
        $cmd =~ s/UUID/$ann->{"uuid"}/g;
        $cmd = qq/$ENV{"SHELL"} -c "$cmd"/;
    }
    elsif ($file =~ m/$BROWSER_REGEX/ ) {
        if ($file =~ m/^www/) {
            # prepend http://
            $cmd = qq{$BROWSER "http://$file"};
        }
        else {
            $cmd = qq{$BROWSER "$file"};
        }
    }
    elsif ($CUSTOM1_REGEX && $file =~ m/$CUSTOM1_REGEX/) {
        $cmd = qq{$CUSTOM1_CMD "$file"};
    }
    elsif ($CUSTOM2_REGEX && $file =~ m/$CUSTOM2_REGEX/) {
        $cmd = qq{$CUSTOM2_CMD "$file"};
    }
    else {
        $file = get_filepath($ann);
        my $filetype = qx{file "$file"};
        if ($filetype =~ m/text/ ) {
            $cmd = qq/$ENV{'SHELL'} -c "$EDITOR '$file'"/;
        }
        else {
            # use XDG for unknown file types
            $cmd = qq{$XDG "$file"};
        }
    }

    return $cmd;
}

sub sort_hasharr
{
    my $arr      = $_[0];
    my $sortkeys = $_[1];

    return sort {
        foreach my $sortkey (@{$sortkeys}) {
            $sortkey =~ m/(.*?)(\+|-)?$/;
            if (!$a->{$1} && !$b->{$1}) {
                next;
            }
            elsif (!$a->{$1}) {
                return 1;
            }
            elsif (!$b->{$1}) {
                return -1;
            }
            if ($a->{$1} eq $b->{$1}) {
                next;
            }
            elsif ($2 && $2 eq "-") {
                return $b->{$1} cmp $a->{$1};
            }
            else {
                return $a->{$1} cmp $b->{$1};
            }
        }
        return 0;
    } @{$arr};
}

sub set_action
{
    my $force = $_[0];
    my $arg   = $_[1];
    my $action= $_[2];

    if ($force->{"action"}) {
        print qq/Cannot use $arg in conjunction with $force->{"arg"}\n/;
        exit 1;
    }
    else {
        $force->{"action"} = $action;
        $force->{"arg"}    = $arg;
    }
}

sub set_mode
{
    my $mode = $_[0];
    my $val  = $_[1];

    if ($$mode && $$mode ne $val) {
        print qq/Cannot use combine arguments -b with -l or -L\n/;
        exit 1;
    }
    else {
        $$mode = $val;
    }
}

# argument parsing
my $FILTER = "";
my $ID_CMD = "ids";
my $LABEL;
my $HELP;
my $LIST_ANN;
my $LIST_EXEC;
my %FORCE;
my $MATCH;
my $TYPE;
my $MODE;
for (my $i = 0; $i <= $#ARGV; ++$i) {
    my $arg = $ARGV[$i];
    if ($arg eq "-h") {
        $HELP = 1;
    }
    elsif ($arg eq "-v") {
        print_version;
        exit 0;
    }
    elsif ($arg eq "-l") {
        set_mode(\$MODE, "list");
        $LIST_ANN = 1;
    }
    elsif ($arg eq "-L") {
        set_mode(\$MODE, "list");
        $LIST_EXEC = 1;
    }
    elsif ($arg eq "-n") {
        if ($REGEX_CODE =~ m/N/) {
            print "Cannot combine argument -n with -N\n";
            exit 1;
        }
        if (length($REGEX_CODE) == 1) {
            print "Cannot combine argument -n with -f\n";
            exit 1;
        }
        $REGEX_CODE = "n";
    }
    elsif ($arg eq "-N") {
        if ($REGEX_CODE eq "n") {
            print "Cannot combine argument -N with -n\n";
            exit 1;
        }
        $REGEX_CODE =~ s/n/N/;
    }
    elsif ($arg eq "-f") {
        if ($REGEX_CODE =~ m/F/) {
            print "Cannot combine argument -f with -F\n";
            exit 1;
        }
        if (length($REGEX_CODE) == 1) {
            print "Cannot combine argument -f with -n\n";
            exit 1;
        }
        $REGEX_CODE = "f";
    }
    elsif ($arg eq "-F") {
        if ($REGEX_CODE eq "f") {
            print "Cannot combine argument -F with -f\n";
            exit 1;
        }
        $REGEX_CODE =~ s/f/F/;
    }
    elsif ($arg eq "-a") {
        $EXCLUDE = "";
    }
    elsif ($arg eq "-aa") {
        $EXCLUDE = "";
        $ID_CMD  = "uuids";
    }
    elsif ($arg eq "-b") {
        set_mode(\$MODE, "batch");
    }
    elsif ($arg eq "-D") {
        set_action(\%FORCE, "-D", "\\del");
    }
    elsif ($arg eq "-r") {
        set_action(\%FORCE, "-r", "\\raw");
    }
    elsif ($arg eq "-s") {
        $SORT = $ARGV[++$i];
        if (!$SORT || $SORT =~ m/^-/) {
            print "Missing argument after $arg\n";
            exit 1;
        }
    }
    elsif ($arg eq "-m") {
        $MATCH = $ARGV[++$i];
        if (!$MATCH || $MATCH =~ m/^-/) {
            print "Missing expression after -m\n";
            exit 1;
        }
    }
    elsif ($arg eq "-t") {
        $TYPE = $ARGV[++$i];
        if (!$TYPE || $TYPE =~ m/^-/) {
            printf "Missing expression after -t\n";
            exit 1;
        }
    }
    elsif ($arg eq "-e") {
        set_action(\%FORCE, "-e", $EDITOR);
    }
    elsif ($arg eq "-x") {
        my $action;
        if ($i >= $#ARGV || $ARGV[$i+1] =~ m/^-/) {
            $action = qq/$ENV{"SHELL"} -c/;
        }
        else {
            $action = $ARGV[++$i];
        }
        set_action(\%FORCE, "-x", $action);
    }
    elsif ($arg =~ m/\\+(.+)/) {
        $LABEL = $1;
    }
    elsif ($arg eq "-c") {
        # just skip (handled above)
        $i++;
    }
    else {
        $FILTER = "$FILTER $arg";
    }
}

my $tmpregex="";
foreach my $code (split("", $REGEX_CODE)) {
    if ($code eq "n") {
        $tmpregex = "${tmpregex}${NOTES_REGEX}|";
    }
    elsif ($code eq "f") {
        $tmpregex = "${tmpregex}${FILE_REGEX}|";
    }
    elsif ($code eq "b") {
        $tmpregex = "${tmpregex}${BROWSER_REGEX}|";
    }
    elsif ($code eq "1") {
        $tmpregex = "${tmpregex}${CUSTOM1_REGEX}|";
    }
    elsif ($code eq "2") {
        $tmpregex = "${tmpregex}${CUSTOM2_REGEX}|";
    }
}
chop($tmpregex);
my $FILEREGEX = qr{^(?:(\S*):\s)?((?:$tmpregex).*)};

if ($HELP) {
	print "Usage: $0 [options] [id|filter1 filter2 ... filterN] [\\\\label]\n\n";

    print "Available options:\n";
    print "-h                Show this text\n";
    print "-v                Print version information\n";
    print "-l                List-only mode, does not open any file; shows annotations\n";
    print "-L                List-only mode, does not open any file; shows command line\n";
    print "-b                Batch mode, processes every file in the list\n";
    print "-n                Only show/open notes file, i.e. annotations matching '$NOTES_REGEX'\n";
    print "-N                Show all but notes files; inverse of -n\n";
    print "-f                Only show/open real files, i.e. annotations matching '$FILE_REGEX'\n";
    print "-F                Show all but real files; inverse of -f\n";
    print "-a                Query all active tasks; clears the EXCLUDE filter\n";
    print "-aa               Query all tasks, i.e. completed and deleted tasks as well (very slow)\n";
    print "-D                Delete the annotation rather than opening it\n";
    print "-r                Raw mode, opens the annotation text with your EDITOR\n";
    print "-m 'regex'        Only include annotations that match 'regex'\n";
    print "-t 'regex'        Only open files whose type (as returned by 'file') matches 'regex'\n";
    print "-s 'key1+,key2-'  Sort annotations by the given key which can be a taskwarrior field or\n";
    print "                  'annot', 'label', 'entry', 'size', 'type', 'time', 'mtime' or 'atime'\n";
    print "-e                Force to open file with EDITOR\n";
    print "-x ['cmd']        Execute file, optionally prepend cmd to the command line\n";
    print "-c filepath       Use alternate taskopenrc file as specified by 'filepath'\n";

    print "\nCurrent configuration:\n";
    print "BROWSER       = $BROWSER\n";
    print "TASKBIN       = $TASKBIN\n";
    print "FOLDER        = $FOLDER\n";
    print "EXT           = $EXT\n";
    print "EDITOR        = $EDITOR\n";
    print "NOTES_FILE    = $NOTES_FILE\n";
    print "NOTES_CMD     = $NOTES_CMD\n";
    print "EXCLUDE       = $EXCLUDE\n";
    print "SORT          = $SORT\n";
    print "DEBUG         = $DEBUG\n";
    print "NOTES_REGEX   = $NOTES_REGEX\n";
    print "BROWSER_REGEX = $BROWSER_REGEX\n";
    print "FILE_REGEX    = $FILE_REGEX\n";
    print "CUSTOM1_REGEX = $CUSTOM1_REGEX\n";
    print "CUSTOM1_CMD   = $CUSTOM1_CMD\n";
    print "CUSTOM2_REGEX = $CUSTOM2_REGEX\n";
    print "CUSTOM2_CMD   = $CUSTOM2_CMD\n";

	exit 1;
}

my @SORT_KEYS;
if ($SORT) {
    @SORT_KEYS = split(',', $SORT);
}

if ($DEBUG > 0) {
    printf("[DEBUG] Applying filter: $EXCLUDE$FILTER\n");
}
my $ID = qx{$TASKBIN $ID_CMD $EXCLUDE$FILTER};
chop($ID);

# query IDs and parse json
my $json = qx{$TASKBIN $ID _query};
my @decoded_json = @{decode_json("[$json]")};

# Reorganize data
my @annotations;
foreach my $task (@decoded_json) {
    if (exists $task->{"annotations"}) {
        foreach my $ann (@{$task->{"annotations"}}) {
            if ($ann->{"description"} =~ m/$FILEREGEX/) {
                my $file = $2;
                my $label = $1;
                if (!$MATCH || ($file =~ m/$MATCH/)) {
                    if (!$label) {
                        $label = "";
                    }
                    if (!$LABEL || ($LABEL eq $label) ) {
                        my %entry = ( "annot"       => $file,
                                      "uuid"        => $task->{"uuid"},
                                      "id"          => $task->{"id"},
                                      "raw"         => $ann->{"description"},
                                      "label"       => $label,
                                      "description" => $task->{"description"});

                        # Copy sort keys
                        foreach my $key (@SORT_KEYS) {
                            $key =~ m/(.*?)(\+|-)?$/;
                            if (!exists $entry{$1}) {
                                if (exists $ann->{$1})
                                {
                                    $entry{$1} = $ann->{$1};
                                }
                                elsif (exists $task->{$1})
                                {
                                    $entry{$1} = $task->{$1};
                                }
                                elsif ($1 eq "size") {
                                    my $filepath = get_filepath(\%entry);
                                    $entry{$1} = qx{stat -c "%s" "$filepath"};
                                }
                                elsif ($1 eq "mtime") {
                                    my $filepath = get_filepath(\%entry);
                                    $entry{$1} = qx{stat -c "%Y" "$filepath"};
                                }
                                elsif ($1 eq "time") {
                                    my $filepath = get_filepath(\%entry);
                                    $entry{$1} = qx{stat -c "%W" "$filepath"};
                                }
                                elsif ($1 eq "atime") {
                                    my $filepath = get_filepath(\%entry);
                                    $entry{$1} = qx{stat -c "%X" "$filepath"};
                                }
                                elsif ($1 eq "type") {
                                    my $filepath = get_filepath(\%entry);
                                    $entry{$1} = qx{file "$filepath"};
                                }
                                else {
                                    print qq/Unknown sort key "$1"\n/;
                                    exit 1;
                                }
                            }
                        }
                        
                        if ($TYPE) {
                            my $filetype;
                            if (!$entry{"type"}) {
                                my $filepath = get_filepath(\%entry);
                                $filetype = qx{file "$filepath"};
                            }
                            else {
                                $filetype = $entry{"type"};
                            }
                            if ($filetype =~ m/$TYPE/) {
                                push(@annotations, \%entry);
                            }
                            elsif ($DEBUG > 0) {
                                printf(qq/[DEBUG] Skipping file "$entry{'file'}" whose type doesn't match '$TYPE'\n/);
                            }
                        }
                        else {
                            push(@annotations, \%entry);
                        }
                    }
                    elsif ($DEBUG > 0) {
                        if (!$label) {
                            printf(qq/[DEBUG] Skipping unlabeled annotation "$ann->{"description"}"\n/);
                        }
                        else {
                            printf(qq/[DEBUG] Skipping label "$label"\n/);
                        }
                    }
                }
                elsif ($MATCH && ($DEBUG > 0)) {
                    printf(qq/[DEBUG] Skipping annotation which doesn't match '$MATCH': $ann->{"description"}\n/);
                }
            }
            elsif ($DEBUG > 0) {
                printf(qq/[DEBUG] Skipping annotation "$ann->{"description"}"\n/);
            }
        }
    }
}

if ($#annotations < 0) {
    print "No annotation found.\n";
    exit 1;
}

if ($#SORT_KEYS >= 0) {
    @annotations = sort_hasharr(\@annotations, \@SORT_KEYS);
}

# choose an annotation/file to open
my @choices = (0);
if ($#annotations > 0 || ($MODE && $MODE eq "list")) {
    print "\n";
    if (!$MODE) {
        print "Please select an annotation:\n";
    }

    my $i = 1;
    foreach my $ann (@annotations) {
        print "    $i)";
        if (!$MODE || $MODE ne "list" || $LIST_ANN) {
            my $id = $ann->{'id'};
            if ($id == 0) {
                $id = $ann->{'uuid'};
            }
            my $text = qq/$ann->{'raw'} ("$ann->{'description'}") -- $id/;
            print " $text\n";
        }

        if ($LIST_EXEC) {
            if ($LIST_ANN) {
                print "       executes:";
            }
            my $cmd = create_cmd($ann, \%FORCE);
            print " $cmd\n";
        }
        $i++;
    }

    if ($MODE && $MODE eq "list") {
        exit 0;
    }
    elsif ($MODE && $MODE eq "batch") {
        @choices = (1..$#annotations+1);
    }
    else {
        # read input
        print "Type number(s): ";
        my $choice = <STDIN>;
        chomp ($choice);

        @choices = parse_number($choice, $#annotations+1);
    }
}

##############################################
#open annotations[$choice] with an appropriate program

if ($#choices > 0) {
    my $tmp = join(",", @choices);
    print "\n";
    print qq/Do you really want to process files $tmp? (y\/N)\n/;
    my $choice = <STDIN>;
    chomp ($choice);
    if ($choice !~ m/^y/i) {
        exit 0;
    }

    foreach my $choice (@choices) {
        my $ann = $annotations[$choice-1];
        system(create_cmd($ann, \%FORCE));
    }
}
else {
    my $ann = $annotations[$choices[0]-1];
    exec(create_cmd($ann, \%FORCE));
}

