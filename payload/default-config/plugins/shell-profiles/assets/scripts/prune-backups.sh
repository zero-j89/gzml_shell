#!/bin/sh
# prune-backups.sh <backups_dir> <max_count>
# Deletes the oldest backup directories, keeping at most max_count.
backups="$1"
max="$2"
find "$backups" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | head -n -"$max" | xargs -r rm -rf
