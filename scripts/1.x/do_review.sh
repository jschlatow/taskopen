#!/bin/bash

if [ $# != 2 ]; then
    echo "Usage: $0 <path-to-review-file> <UUID>"
    exit 1
fi

task $2 info

echo -n "Continue review? (Y/n): "
read -n 1 input
if [ "$input" == "y" ]; then
    $EDITOR $1
else
    echo $input
fi
