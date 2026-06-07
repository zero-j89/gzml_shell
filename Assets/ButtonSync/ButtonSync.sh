#!/usr/bin/env bash
set -euo pipefail

python3 <<'PY'
import json
from pathlib import Path
from copy import deepcopy
from datetime import datetime

config_dir = Path.home() / ".config" / "gzml-shell"

active = config_dir / "settings.json"
profiles = config_dir / "profiles"
backup_root = profiles / "_backups" / ("button-sync-" + datetime.now().strftime("%Y%m%d-%H%M%S"))

# Only sync user layout objects that should stay consistent across profiles.
# Do NOT copy theme/color/wallpaper/audio/weather/hooks/general/profile-specific settings.
SYNC_PATHS = [
    ("controlCenter", "shortcuts"),   # shortcut cards/buttons
    ("bar", "widgets"),               # taskbar/bar widget items
    ("desktopWidgets",),              # desktop widget layout + enabled state
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
        if not isinstance(cur, dict):
            return False
        if key not in cur or not isinstance(cur[key], dict):
            cur[key] = {}
        cur = cur[key]

    if not isinstance(cur, dict):
        return False

    cur[path[-1]] = deepcopy(value)
    return True


def path_label(path):
    return ".".join(path)


if not active.exists():
    raise SystemExit(f"ERROR: Missing {active}")

if not profiles.exists():
    raise SystemExit(f"ERROR: Missing {profiles}")

src = load_json(active)

sync_values = {}
missing = []

for path in SYNC_PATHS:
    value = get_path(src, path)
    if value is None:
        missing.append(path_label(path))
    else:
        sync_values[path] = deepcopy(value)

if missing:
    raise SystemExit(
        "ERROR: Current settings.json is missing required sync section(s): "
        + ", ".join(missing)
    )

profile_files = sorted(
    p for p in profiles.glob("*/settings.json")
    if "_backups" not in p.parts
)

if not profile_files:
    raise SystemExit(f"ERROR: No profile settings.json files found under {profiles}")

backup_root.mkdir(parents=True, exist_ok=True)

updated = 0
skipped = 0

for settings in profile_files:
    profile_name = settings.parent.name

    try:
        data = load_json(settings)
    except Exception as exc:
        print(f"SKIPPED {profile_name}: could not read JSON: {exc}")
        skipped += 1
        continue

    changed = False

    for path, src_value in sync_values.items():
        old_value = get_path(data, path)
        if old_value != src_value:
            set_path(data, path, src_value)
            changed = True

    if not changed:
        print(f"Unchanged: {profile_name}")
        continue

    backup_dir = backup_root / profile_name
    backup_dir.mkdir(parents=True, exist_ok=True)
    backup_file = backup_dir / "settings.json"
    backup_file.write_text(settings.read_text())

    save_json(settings, data)
    updated += 1
    print(f"Updated: {profile_name}")

print()
print("Done.")
print(f"Synced profile layout sections to {updated} profile(s).")
print(f"Skipped: {skipped}")
print(f"Backups: {backup_root}")
print()
print("Synced sections:")
for path in SYNC_PATHS:
    print(f"  - {path_label(path)}")
PY
