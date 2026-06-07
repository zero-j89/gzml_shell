#!/usr/bin/env bash
set -euo pipefail

python3 <<'PY'
import json
from pathlib import Path
from copy import deepcopy

config_dir = Path.home() / ".config" / "gzml-shell"
root_settings = config_dir / "settings.json"
plugin_settings = config_dir / "plugins" / "shell-profiles" / "settings.json"

# Only these user layout sections are synced.
# This copies shortcut cards/buttons, bar/taskbar widgets, and desktop widgets.
# It does not touch wallpaper, colors, bar position, monitor layout, dock,
# audio, weather, notifications, hooks, idle, or other profile-specific settings.
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


def resolve_profiles_dir():
    # Match the shell-profiles plugin configuration.
    # If the plugin is still pointed at legacy Noctalia profiles, use that.
    if plugin_settings.exists():
        try:
            data = load_json(plugin_settings)
            configured = str(data.get("profilesDir", "")).strip()
            if configured:
                return Path(configured).expanduser()
        except Exception as exc:
            print(f"WARNING: Could not read {plugin_settings}: {exc}")

    return config_dir / "profiles"


if not root_settings.exists():
    raise SystemExit(f"ERROR: Missing active settings: {root_settings}")

profiles_dir = resolve_profiles_dir()

if not profiles_dir.exists():
    raise SystemExit(f"ERROR: Missing profiles directory: {profiles_dir}")

src = load_json(root_settings)

missing = [label(path) for path in SYNC_PATHS if get_path(src, path) is None]
if missing:
    raise SystemExit(
        "ERROR: Active settings is missing required sync path(s): "
        + ", ".join(missing)
    )

sync_values = {path: deepcopy(get_path(src, path)) for path in SYNC_PATHS}

profile_files = sorted(
    p for p in profiles_dir.glob("*/settings.json")
    if "_backups" not in p.parts
)

if not profile_files:
    raise SystemExit(f"ERROR: No profile settings.json files found under: {profiles_dir}")

updated = 0
unchanged = 0
skipped = 0

print(f"Source:   {root_settings}")
print(f"Profiles: {profiles_dir}")
print()

for settings_file in profile_files:
    try:
        data = load_json(settings_file)
    except Exception as exc:
        print(f"SKIPPED: {settings_file} ({exc})")
        skipped += 1
        continue

    changed = False

    for path, value in sync_values.items():
        if get_path(data, path) != value:
            set_path(data, path, value)
            changed = True

    if not changed:
        print(f"Unchanged: {settings_file.parent.name}")
        unchanged += 1
        continue

    save_json(settings_file, data)
    print(f"Updated: {settings_file.parent.name}")
    updated += 1

print()
print("Done.")
print(f"Updated:   {updated}")
print(f"Unchanged: {unchanged}")
print(f"Skipped:   {skipped}")
print()
print("Synced only:")
for path in SYNC_PATHS:
    print(f"  - {label(path)}")
PY
