#!/usr/bin/env python3
"""
Migrate user-owned Noctalia v4 configuration into GZML Shell safely.

What this does:
- Backs up the existing GZML config before writing.
- Copies safe user data from ~/.config/noctalia to ~/.config/gzml-shell.
- Rewrites old Noctalia paths/IPCs to GZML Shell paths/IPCs.
- Sanitizes plugin state so unsupported Noctalia plugins do not auto-enable and break IPC.
- Avoids copying cache-generated wallpaper-effect paths as permanent wallpapers.

Run:
  python3 migrate-noctalia-to-gzml.py

Dry run:
  python3 migrate-noctalia-to-gzml.py --dry-run

Preserve extra plugin states:
  python3 migrate-noctalia-to-gzml.py --preserve-plugin arch-updater --preserve-plugin clipper
"""

from __future__ import annotations

import argparse
import copy
import json
import os
import shutil
import sys
import time
from pathlib import Path
from typing import Any

HOME = Path.home()

DEFAULT_SOURCE = HOME / ".config" / "noctalia"
DEFAULT_TARGET = HOME / ".config" / "gzml-shell"

# Edit these as GZML Shell gains native support for more plugins.
# These plugin states are allowed to remain enabled if they were enabled in Noctalia.
GZML_NATIVE_OR_KNOWN_COMPATIBLE_PLUGINS: set[str] = {
    "shell-profiles",
    "clipper",
    "screen-toolkit",
    "wallcards",
    "privacy-indicator",
    "special-workspaces",
    "hyprland-visual-editor",
}

# Plugins that should never be blindly enabled from Noctalia state.
# Users can still enable these manually after testing.
FORCE_DISABLE_BY_DEFAULT: set[str] = {
    "arch-updater",
    "calendar-widget",
    "color-scheme-creator",
    "file-search",
    "hello-world",
    "mpvpaper",
    "network-manager-vpn",
    "sys-info-widget",
    "tamagotchi",
    "usb-drive-manager",
    "video-wallpaper",
}

COPY_FILES = {
    "colors.json",
    "notification-rules.json",
    "user-templates.toml",
}

COPY_DIRS = {
    "colorschemes",
    "profiles",
}

NOCTALIA_PLUGIN_SOURCE = "https://github.com/noctalia-dev/noctalia-plugins"

PATH_REWRITES: tuple[tuple[str, str], ...] = (
    (str(HOME / ".config" / "quickshell-noctalia"), str(HOME / ".config" / "quickshell-gzml")),
    ("~/.config/quickshell-noctalia", "~/.config/quickshell-gzml"),
    (str(HOME / ".config" / "noctalia"), str(HOME / ".config" / "gzml-shell")),
    ("~/.config/noctalia", "~/.config/gzml-shell"),
    ("/home/zer0/.config/quickshell-noctalia", str(HOME / ".config" / "quickshell-gzml")),
    ("/home/zer0/.config/noctalia", str(HOME / ".config" / "gzml-shell")),
)

# If your launcher/config name differs, edit this value.
IPC_PATH_FROM = "qs -p ~/.config/quickshell-noctalia ipc call"
IPC_PATH_TO = "qs -p ~/.config/quickshell-gzml ipc call"


def log(msg: str) -> None:
    print(f"[migrate] {msg}")


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def write_json(path: Path, data: Any, dry_run: bool = False) -> None:
    if dry_run:
        log(f"DRY RUN: would write {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=4)
        f.write("\n")


def rewrite_string(value: str) -> str:
    out = value
    out = out.replace(IPC_PATH_FROM, IPC_PATH_TO)
    for old, new in PATH_REWRITES:
        out = out.replace(old, new)
    return out


def sanitize_wallpaper_path(value: str) -> str:
    # Never persist generated effect/cache wallpapers into the migrated config.
    bad_fragments = (
        "/.cache/gzml/wallpaper-effects/",
        "/.cache/noctalia/wallpaper-effects/",
        "wallpaper-effects/",
    )
    if any(fragment in value for fragment in bad_fragments):
        return ""
    return value


def recursive_sanitize(obj: Any) -> Any:
    if isinstance(obj, dict):
        return {k: recursive_sanitize(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [recursive_sanitize(v) for v in obj]
    if isinstance(obj, str):
        return sanitize_wallpaper_path(rewrite_string(obj))
    return obj


def sanitize_settings(settings: dict[str, Any]) -> dict[str, Any]:
    migrated = recursive_sanitize(copy.deepcopy(settings))

    # Ensure GZML-specific known settings don't accidentally get disabled by older Noctalia files.
    general = migrated.setdefault("general", {})
    if isinstance(general, dict):
        general.setdefault("telemetryEnabled", False)

    # Keep wallpaper settings, but strip any generated effect output paths.
    # GZML Shell always uses optimized/resized wallpaper cache paths by default.
    # This avoids very large original images being decoded per monitor.
    wallpaper = migrated.get("wallpaper")
    if isinstance(wallpaper, dict):
        wallpaper["useOriginalImages"] = False
        if isinstance(wallpaper.get("directory"), str):
            wallpaper["directory"] = sanitize_wallpaper_path(wallpaper["directory"])
        for item in wallpaper.get("monitorDirectories", []) or []:
            if isinstance(item, dict) and isinstance(item.get("wallpaper"), str):
                item["wallpaper"] = sanitize_wallpaper_path(item["wallpaper"])

    return migrated


def sanitize_plugins(plugins: dict[str, Any], preserve_plugins: set[str]) -> dict[str, Any]:
    allowed = GZML_NATIVE_OR_KNOWN_COMPATIBLE_PLUGINS | preserve_plugins

    migrated: dict[str, Any] = {
        "sources": [],
        "states": {},
        "version": plugins.get("version", 2),
    }

    states = plugins.get("states", {})
    if not isinstance(states, dict):
        return migrated

    for plugin_name, state in states.items():
        if not isinstance(state, dict):
            state = {}

        new_state = copy.deepcopy(state)
        new_state.pop("sourceUrl", None)

        was_enabled = bool(state.get("enabled", False))
        should_preserve = plugin_name in allowed and plugin_name not in FORCE_DISABLE_BY_DEFAULT
        new_state["enabled"] = bool(was_enabled and should_preserve)

        if was_enabled and not should_preserve:
            new_state["migrationNote"] = "Disabled during Noctalia -> GZML migration until plugin compatibility is confirmed."

        migrated["states"][plugin_name] = recursive_sanitize(new_state)

    return migrated


def copy_path(src: Path, dst: Path, dry_run: bool = False) -> None:
    if not src.exists():
        return
    if dry_run:
        log(f"DRY RUN: would copy {src} -> {dst}")
        return
    if src.is_dir():
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst)
    else:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)


def backup_existing(target: Path, dry_run: bool = False) -> Path | None:
    if not target.exists():
        return None
    stamp = time.strftime("%Y%m%d-%H%M%S")
    backup = target.with_name(f"{target.name}.backup-before-noctalia-migration.{stamp}")
    if dry_run:
        log(f"DRY RUN: would backup {target} -> {backup}")
        return backup
    shutil.copytree(target, backup)
    return backup


def migrate(source: Path, target: Path, preserve_plugins: set[str], dry_run: bool = False) -> int:
    if not source.exists():
        log(f"Noctalia config not found: {source}")
        return 1

    log(f"Source: {source}")
    log(f"Target: {target}")

    backup = backup_existing(target, dry_run=dry_run)
    if backup:
        if dry_run:
            log(f"DRY RUN: backup would be created at: {backup}")
        else:
            log(f"Backed up existing GZML config to: {backup}")

    if not dry_run:
        target.mkdir(parents=True, exist_ok=True)

    # Copy safe static files.
    for name in COPY_FILES:
        copy_path(source / name, target / name, dry_run=dry_run)

    # Copy safe directories.
    for name in COPY_DIRS:
        copy_path(source / name, target / name, dry_run=dry_run)

    # settings.json needs path/IPC/cache sanitization.
    settings_path = source / "settings.json"
    if settings_path.exists():
        try:
            settings = load_json(settings_path)
            write_json(target / "settings.json", sanitize_settings(settings), dry_run=dry_run)
            if dry_run:
                log("DRY RUN: settings.json would be sanitized and migrated")
            else:
                log("Migrated sanitized settings.json")
        except Exception as exc:
            log(f"Failed to migrate settings.json: {exc}")
            return 1

    # plugins.json needs compatibility-aware conversion.
    plugins_path = source / "plugins.json"
    if plugins_path.exists():
        try:
            plugins = load_json(plugins_path)
            write_json(target / "plugins.json", sanitize_plugins(plugins, preserve_plugins), dry_run=dry_run)
            if dry_run:
                log("DRY RUN: plugins.json would be sanitized and migrated")
            else:
                log("Migrated sanitized plugins.json")
        except Exception as exc:
            log(f"Failed to migrate plugins.json: {exc}")
            return 1

    if dry_run:
        log("DRY RUN complete. No files were changed.")
    else:
        log("Migration complete.")
        log("Unknown/unsafe Noctalia plugins were disabled by default. Re-enable them manually after testing IPC compatibility.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Safely migrate Noctalia v4 user config into GZML Shell.")
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE, help="Noctalia config path")
    parser.add_argument("--target", type=Path, default=DEFAULT_TARGET, help="GZML Shell config path")
    parser.add_argument("--dry-run", action="store_true", help="Show actions without writing files")
    parser.add_argument(
        "--preserve-plugin",
        action="append",
        default=[],
        help="Plugin ID to preserve as enabled if it was enabled in Noctalia. Can be repeated.",
    )
    args = parser.parse_args()

    return migrate(
        source=args.source.expanduser(),
        target=args.target.expanduser(),
        preserve_plugins=set(args.preserve_plugin),
        dry_run=args.dry_run,
    )


if __name__ == "__main__":
    raise SystemExit(main())
