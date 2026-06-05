#!/usr/bin/env bash

python3 <<'PY'
import json
from pathlib import Path
from copy import deepcopy

config_dir = Path.home() / ".config" / "gzml-shell"

active = config_dir / "settings.json"
profiles = config_dir / "profiles"

def find_shortcuts_parent(obj):
    if isinstance(obj, dict):
        if (
            "shortcuts" in obj
            and isinstance(obj["shortcuts"], dict)
            and isinstance(obj["shortcuts"].get("left"), list)
            and isinstance(obj["shortcuts"].get("right"), list)
        ):
            return obj

        for value in obj.values():
            found = find_shortcuts_parent(value)
            if found is not None:
                return found

    elif isinstance(obj, list):
        for value in obj:
            found = find_shortcuts_parent(value)
            if found is not None:
                return found

    return None

if not active.exists():
    raise SystemExit(f"ERROR: Missing {active}")

if not profiles.exists():
    raise SystemExit(f"ERROR: Missing {profiles}")

src = json.loads(active.read_text())
src_parent = find_shortcuts_parent(src)

if src_parent is None:
    raise SystemExit(
        "ERROR: Could not find shortcuts.left/right in current settings.json"
    )

src_shortcuts = deepcopy(src_parent["shortcuts"])

updated = 0

for settings in profiles.glob("*/settings.json"):
    if "_backups" in settings.parts:
        continue

    data = json.loads(settings.read_text())
    target_parent = find_shortcuts_parent(data)

    if target_parent is None:
        print("SKIPPED:", settings.parent.name)
        continue

    target_parent["shortcuts"] = deepcopy(src_shortcuts)

    settings.write_text(
        json.dumps(data, indent=4, ensure_ascii=False) + "\n"
    )

    updated += 1
    print("Updated:", settings.parent.name)

print(f"\nDone. Synced shortcuts to {updated} profiles.")
PY
