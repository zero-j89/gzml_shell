#!/bin/sh
# list-profiles.sh <profiles_dir>
# Prints one line per profile: "<name>\t<savedAt>"
d="$1"
[ -d "$d" ] || exit 0
for fullpath in "$d"/*/; do
    [ -d "$fullpath" ] || continue
    name=$(basename "$fullpath")
    case "$name" in _*|.*) continue ;; esac
    savedAt=""
    if [ -f "${fullpath}meta.json" ]; then
        savedAt=$(awk -F'"' '/"savedAt"/{for(i=1;i<=NF;i++) if ($i=="savedAt") {print $(i+2); break}}' \
            "${fullpath}meta.json" 2>/dev/null || true)
    fi
    printf '%s\t%s\n' "$name" "$savedAt"
done
