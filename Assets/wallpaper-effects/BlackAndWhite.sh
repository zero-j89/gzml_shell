#!/usr/bin/env bash
set -euo pipefail

input="${1:?input wallpaper required}"
output="${2:?output wallpaper required}"

mkdir -p "$(dirname "$output")"

magick "$input" -colorspace gray -sigmoidal-contrast 10,40% "$output"
