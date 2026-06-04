#!/bin/sh
# backup-configs.sh <cfg_dir> <backup_dir>
# Copies settings.json, colors.json and plugins.json (if present) to backup_dir.
cfg="$1"
backup="$2"
mkdir -p "$backup"
cp -f "${cfg}settings.json" "${backup}/settings.json" 2>/dev/null || true
cp -f "${cfg}colors.json"   "${backup}/colors.json"   2>/dev/null || true
[ -f "${cfg}plugins.json" ] && cp -f "${cfg}plugins.json" "${backup}/plugins.json" || true
