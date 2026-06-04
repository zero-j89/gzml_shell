#!/bin/sh
# save-profile.sh <cfg_dir> <profile_dir>
# Copies the current config files into a profile directory.
cfg="$1"
profile="$2"
mkdir -p "$profile"
cp -f "${cfg}settings.json" "${profile}/settings.json"
cp -f "${cfg}colors.json"   "${profile}/colors.json"
[ -f "${cfg}plugins.json" ] && cp -f "${cfg}plugins.json" "${profile}/plugins.json" || true
