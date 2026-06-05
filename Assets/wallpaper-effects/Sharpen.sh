#!/usr/bin/env bash
set -euo pipefail

input="${1:?input wallpaper required}"
output="${2:?output wallpaper required}"

mkdir -p "$(dirname "$output")"

magick "$input" -sharpen 0x5 "$output"
