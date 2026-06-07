#!/usr/bin/env bash
set -euo pipefail

python3 <<'PY'
import json
from pathlib import Path
from copy import deepcopy

config_dir = Path.home() / ".config" / "gzml-shell"

active = config_dir / "settings.json"
profiles = config_dir / "profiles"

if not active.exists():
    raise SystemExit(f"ERROR: Missing {active}")

if not profiles.exists():
    raise SystemExit(f"ERROR: Missing {profiles}")

src = json.loads(active.read_text())

required = [
    ("controlCenter", "shortcuts"),
    ("bar", "widgets"),
    ("desktopWidgets",),
]

for path in required:
    cur = src
    for key in path:
        if key not in cur:
            raise SystemExit(f"ERROR: Missing active setting: {'.'.join(path)}")
        cur = cur[key]

updated = 0

for settings in profiles.glob("*/settings.json"):
    if "_backups" in settings.parts:
        continue

    data = json.loads(settings.read_text())

    data.setdefault("controlCenter", {})
    data["controlCenter"]["shortcuts"] = deepcopy(
        src["controlCenter"]["shortcuts"]
    )

    data.setdefault("bar", {})
    data["bar"]["widgets"] = deepcopy(
        src["bar"]["widgets"]
    )

    data["desktopWidgets"] = deepcopy(
        src["desktopWidgets"]
    )

    settings.write_text(
        json.dumps(data, indent=4, ensure_ascii=False) + "\n"
    )

    updated += 1
    print("Updated:", settings.parent.name)

print(f"\nDone. Synced layouts to {updated} profiles.")
print("Synced:")
print("  - controlCenter.shortcuts")
print("  - bar.widgets")
print("  - desktopWidgets")
PY
