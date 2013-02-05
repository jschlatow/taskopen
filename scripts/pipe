#!/bin/bash

if [ $# != 3 ]; then
    echo "Usage: $0 cmd1 cmd2 arg-for-cmd1"
    exit 1
fi

# Executes cmd1 with arg-for-cmd1 and pipes into cmd2
#  e.g. pipe.sh catindent.sh "head -n3"
$1 $3 | $2
