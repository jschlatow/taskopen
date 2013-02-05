#!/bin/bash
# Usage: headindent.sh [<head arg1> <head arg2> <head argN>] <file>

# pass the last argument to catindent.sh and all the other arguments to 'head'
catindent.sh ${@:$#} | head ${@:1:$(($#-1))}
