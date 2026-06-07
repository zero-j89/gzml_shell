#!/usr/bin/env bash
set -euo pipefail

python3 <<'PY'
import json
from pathlib import Path
from copy import deepcopy
from datetime import datetime
import os
import sys

config_dir = Path.home() / ".config" / "gzml-shell"
root_settings = config_dir / "settings.json"
profiles_dir = config_dir / "profiles"

# ONLY these sections are synced.
# This copies the user's actual configured shortcut cards/buttons,
# taskbar/bar widgets, and desktop widgets.
# It does NOT copy wallpaper, colors, bar position, monitors, dock, audio,
# weather, notifications, hooks, idle, or other profile-specific settings.
SYNC_PATHS = [
    ("controlCenter", "shortcuts"),
    ("bar", "widgets"),
    ("desktopWidgets",),
]


def load_json(path: Path):
    return json.loads(path.read_text())


def save_json(path: Path, data):
    path.write_text(json.dumps(data, indent=4, ensure_ascii=False) + "\n")


def get_path(obj, path):
    cur = obj
    for key in path:
        if not isinstance(cur, dict) or key not in cur:
            return None
        cur = cur[key]
    return cur


def set_path(obj, path, value):
    cur = obj
    for key in path[:-1]:
        if key not in cur or not isinstance(cur[key], dict):
            cur[key] = {}
        cur = cur[key]
    cur[path[-1]] = deepcopy(value)


def label(path):
    return ".".join(path)


def has_all_sync_paths(path: Path):
    try:
        data = load_json(path)
    except Exception:
        return False
    return all(get_path(data, p) is not None for p in SYNC_PATHS)


def profile_settings_files():
    if not profiles_dir.exists():
        return []
    return sorted(
        p for p in profiles_dir.glob("*/settings.json")
        if "_backups" not in p.parts
    )


if not root_settings.exists():
    raise SystemExit(f"ERROR: Missing root settings: {root_settings}")

if not profiles_dir.exists():
    raise SystemExit(f"ERROR: Missing profiles directory: {profiles_dir}")

profiles = profile_settings_files()
if not profiles:
    raise SystemExit(f"ERROR: No profile settings found under: {profiles_dir}")

# Source selection:
# 1. If an explicit profile name/path is passed, use it.
# 2. Else if GZML_BUTTON_SYNC_SOURCE points to a file, use it.
# 3. Else use the most recently modified settings.json among root + profile files.
#
# This matters because the active profile's saved settings may live in
# ~/.config/gzml-shell/profiles/<profile>/settings.json, not only root settings.json.
explicit = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("GZML_BUTTON_SYNC_SOURCE", "")

if explicit:
    candidate = Path(explicit).expanduser()
    if candidate.is_dir():
        candidate = candidate / "settings.json"
    elif not candidate.exists():
        # Treat bare value as a profile name.
        candidate = profiles_dir / explicit / "settings.json"

    if not candidate.exists():
        raise SystemExit(f"ERROR: Explicit sync source not found: {candidate}")

    source_file = candidate
else:
    candidates = [root_settings] + profiles
    candidates = [p for p in candidates if p.exists() and has_all_sync_paths(p)]
    if not candidates:
        raise SystemExit("ERROR: No usable source settings file found.")
    source_file = max(candidates, key=lambda p: p.stat().st_mtime)

src = load_json(source_file)

missing = [label(p) for p in SYNC_PATHS if get_path(src, p) is None]
if missing:
    raise SystemExit(
        "ERROR: Source is missing required sync path(s): " + ", ".join(missing)
    )

sync_values = {p: deepcopy(get_path(src, p)) for p in SYNC_PATHS}

backup_root = profiles_dir / "_backups" / ("button-sync-" + datetime.now().strftime("%Y%m%d-%H%M%S"))
backup_root.mkdir(parents=True, exist_ok=True)

targets = [root_settings] + profiles

updated = 0
unchanged = 0
skipped = 0

print(f"Source: {source_file}")
print()

for target in targets:
    try:
        data = load_json(target)
    except Exception as exc:
        print(f"SKIPPED: {target} ({exc})")
        skipped += 1
        continue

    changed = False
    for path, value in sync_values.items():
        if get_path(data, path) != value:
            set_path(data, path, value)
            changed = True

    if not changed:
        print(f"Unchanged: {target}")
        unchanged += 1
        continue

    # Back up profile settings and root settings before editing.
    if target == root_settings:
        backup_file = backup_root / "ROOT-settings.json"
    else:
        backup_dir = backup_root / target.parent.name
        backup_dir.mkdir(parents=True, exist_ok=True)
        backup_file = backup_dir / "settings.json"

    backup_file.write_text(target.read_text())
    save_json(target, data)

    print(f"Updated: {target}")
    updated += 1

print()
print("Done.")
print(f"Updated:   {updated}")
print(f"Unchanged: {unchanged}")
print(f"Skipped:   {skipped}")
print(f"Backups:   {backup_root}")
print()
print("Synced only:")
for path in SYNC_PATHS:
    print(f"  - {label(path)}")
PY
