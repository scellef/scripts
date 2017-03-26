#!/bin/bash
# Quick and dirty script to remind how to mess with bash arguments

echo "All of the arguments: $@"
echo "Number of arguments: ${#@}"

echo "First: $1"
echo "Second: $2"
echo "Third: $3"
echo "Fourth: $4"
echo "Fifth: $5"

if [ -z $1 ] ; then
  echo '1st arg is zero-length'
fi

if [ -z "$1" -o -z "$2" ] ; then
  echo '1st or 2nd arg are zero-length'
fi
