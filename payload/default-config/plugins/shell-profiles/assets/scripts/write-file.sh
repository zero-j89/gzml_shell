#!/bin/sh
# write-file.sh <content> <path>
# Writes $1 verbatim to the file at $2.
printf '%s' "$1" > "$2"
