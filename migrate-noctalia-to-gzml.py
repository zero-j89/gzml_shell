#!/usr/bin/env python3
"""
Migrate user-owned Noctalia v4 configuration into GZML Shell safely.

What this does:
- Backs up the existing GZML config before writing.
- Copies/merges safe user data from ~/.config/noctalia to ~/.config/gzml-shell.
- Rewrites old Noctalia paths/IPCs to GZML Shell paths/IPCs.
- Merges plugin state without removing stock GZML plugins, while disabling unsupported Noctalia plugins by default.
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
    "usb-drive-manager",
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


def stable_key(value: Any) -> str:
    """Return a deterministic fallback key for de-duplicating settings list entries."""
    try:
        return json.dumps(value, sort_keys=True, separators=(",", ":"))
    except TypeError:
        return repr(value)


SEMANTIC_LIST_KEYS = (
    "id",
    "pluginId",
    "plugin",
    "name",
    "module",
    "component",
    "widget",
    "card",
    "button",
    "action",
    "command",
    "label",
    "title",
    "type",
)


def semantic_list_key(value: Any) -> str:
    """
    Return a practical identity key for list items.

    This prevents duplicate bar/card/button/plugin entries when the Noctalia item
    and the GZML stock item represent the same thing but differ in extra fields,
    paths, labels, icons, or defaults.
    """
    if isinstance(value, dict):
        for key in SEMANTIC_LIST_KEYS:
            found = value.get(key)
            if isinstance(found, str) and found.strip():
                return f"{key}:{rewrite_string(found).strip().lower()}"
            if isinstance(found, (int, float, bool)):
                return f"{key}:{found}"

        # Common nested shapes used by layout/config entries.
        for nested_key in ("source", "plugin", "item", "data"):
            nested = value.get(nested_key)
            if isinstance(nested, dict):
                nested_identity = semantic_list_key(nested)
                if not nested_identity.startswith("stable:"):
                    return f"{nested_key}.{nested_identity}"

    if isinstance(value, str):
        return f"str:{rewrite_string(value).strip().lower()}"

    return f"stable:{stable_key(value)}"


def merge_lists_preserve_user_then_stock(user_list: list[Any], stock_list: list[Any]) -> list[Any]:
    """
    Merge list-like config sections without creating doubles.

    Noctalia user layout/order is kept first, then missing stock GZML entries
    are appended. Deduping uses semantic identity fields first instead of the
    whole object, because stock GZML buttons/cards may have newer fields.
    """
    merged: list[Any] = []
    seen: set[str] = set()

    for item in user_list + stock_list:
        key = semantic_list_key(item)
        if key in seen:
            continue
        seen.add(key)
        merged.append(copy.deepcopy(item))

    return merged


def deep_merge_user_over_stock(user_value: Any, stock_value: Any) -> Any:
    """
    Recursively merge sanitized Noctalia settings into existing GZML defaults.

    - Dicts are merged recursively.
    - Lists keep the user's Noctalia order and append missing GZML stock entries.
    - Scalars from Noctalia override stock values.
    - Missing Noctalia sections keep stock GZML defaults.
    """
    if isinstance(user_value, dict) and isinstance(stock_value, dict):
        merged = copy.deepcopy(stock_value)
        for key, value in user_value.items():
            if key in merged:
                merged[key] = deep_merge_user_over_stock(value, merged[key])
            else:
                merged[key] = copy.deepcopy(value)
        return merged

    if isinstance(user_value, list) and isinstance(stock_value, list):
        return merge_lists_preserve_user_then_stock(user_value, stock_value)

    return copy.deepcopy(user_value)



PROTECTED_CARD_IDS = {
    "profiles",
    "profile",
    "profile-switcher",
    "profileswitcher",
    "profile-switcher-card",
    "shell-profiles",
    "shellprofiles",
}


def normalized_card_id(value: Any) -> str:
    """Best-effort identity for card/button/widget objects."""
    if isinstance(value, str):
        return rewrite_string(value).strip().lower().replace("_", "-").replace(" ", "-")

    if isinstance(value, dict):
        for key in ("id", "name", "pluginId", "plugin", "module", "component", "widget", "card", "button", "type", "title", "label", "generalTooltipText"):
            found = value.get(key)
            if isinstance(found, str) and found.strip():
                return rewrite_string(found).strip().lower().replace("_", "-").replace(" ", "-")

    return ""


def object_text(value: Any) -> str:
    """Flatten an object to searchable lowercase text for protected custom buttons."""
    if isinstance(value, str):
        return rewrite_string(value).lower()
    if isinstance(value, dict):
        return " ".join(object_text(v) for v in value.values())
    if isinstance(value, list):
        return " ".join(object_text(v) for v in value)
    return str(value).lower()


def is_profile_switcher_card(value: Any) -> bool:
    cid = normalized_card_id(value)
    compact = cid.replace("-", "")
    blob = object_text(value)

    return (
        cid in PROTECTED_CARD_IDS
        or compact in PROTECTED_CARD_IDS
        or ("profile" in cid and ("switch" in cid or "shell" in cid))
        or "plugin:shell-profiles" in blob
        or "toggleprofiles" in blob
        or "profile switcher" in blob
    )


def protect_profile_switcher_order(items: list[Any], max_items: int = 5) -> list[Any]:
    """
    Keep max_items, but never drop profile switcher if present.
    """
    if len(items) <= max_items:
        return items

    protected = [item for item in items if is_profile_switcher_card(item)]
    normal = [item for item in items if not is_profile_switcher_card(item)]

    if not protected:
        return items[:max_items]

    out = [protected[0]]
    for item in normal:
        if len(out) >= max_items:
            break
        out.append(item)
    return out


def fix_profile_switcher_in_card_layouts(obj: Any) -> Any:
    """
    Targeted repair for constrained card/widget/button layout lists.

    It only touches lists that already contain a profile switcher and exceed
    five items. It does not globally dedupe or touch decorative/weather arrays.
    """
    if isinstance(obj, dict):
        fixed: dict[str, Any] = {}
        for key, value in obj.items():
            lower_key = str(key).lower()
            fixed_value = fix_profile_switcher_in_card_layouts(value)

            if (
                isinstance(fixed_value, list)
                and len(fixed_value) > 5
                and any(token in lower_key for token in ("left", "right", "card", "cards", "widget", "widgets", "button", "buttons"))
                and any(is_profile_switcher_card(item) for item in fixed_value)
            ):
                fixed_value = protect_profile_switcher_order(fixed_value, 5)

            fixed[key] = fixed_value
        return fixed

    if isinstance(obj, list):
        return [fix_profile_switcher_in_card_layouts(item) for item in obj]

    return obj



def collect_profile_switcher_list_paths(obj: Any, path: tuple[Any, ...] = ()) -> list[tuple[tuple[Any, ...], list[Any]]]:
    """
    Find stock layout lists containing the profile switcher.

    Returns paths to lists, not individual items, so we can re-add the stock
    profile switcher to the same layout location after migration if it vanished.
    """
    found: list[tuple[tuple[Any, ...], list[Any]]] = []

    if isinstance(obj, dict):
        for key, value in obj.items():
            found.extend(collect_profile_switcher_list_paths(value, path + (key,)))
        return found

    if isinstance(obj, list):
        if any(is_profile_switcher_card(item) for item in obj):
            found.append((path, obj))
        for idx, item in enumerate(obj):
            found.extend(collect_profile_switcher_list_paths(item, path + (idx,)))
        return found

    return found


def get_by_path(obj: Any, path: tuple[Any, ...]) -> Any:
    cur = obj
    for part in path:
        if isinstance(part, int):
            if not isinstance(cur, list) or part >= len(cur):
                return None
            cur = cur[part]
        else:
            if not isinstance(cur, dict) or part not in cur:
                return None
            cur = cur[part]
    return cur


def set_by_path(obj: Any, path: tuple[Any, ...], value: Any) -> bool:
    if not path:
        return False

    cur = obj
    for part in path[:-1]:
        if isinstance(part, int):
            if not isinstance(cur, list) or part >= len(cur):
                return False
            cur = cur[part]
        else:
            if not isinstance(cur, dict) or part not in cur:
                return False
            cur = cur[part]

    last = path[-1]
    if isinstance(last, int):
        if not isinstance(cur, list) or last >= len(cur):
            return False
        cur[last] = value
        return True

    if not isinstance(cur, dict):
        return False
    cur[last] = value
    return True


def restore_stock_profile_switchers(migrated: dict[str, Any], stock_settings: dict[str, Any] | None) -> dict[str, Any]:
    """
    If a fresh GZML stock layout has the profile switcher but the migrated
    result lost it, reinsert the stock profile switcher into that same list.

    This specifically protects the profile switcher shortcut/card from being
    removed by old Noctalia settings that do not know it exists.
    """
    if not isinstance(stock_settings, dict):
        return migrated

    stock_paths = collect_profile_switcher_list_paths(stock_settings)

    for path, stock_list in stock_paths:
        migrated_list = get_by_path(migrated, path)
        if not isinstance(migrated_list, list):
            # If the whole list vanished or changed shape, restore the stock list.
            set_by_path(migrated, path, copy.deepcopy(stock_list))
            continue

        if any(is_profile_switcher_card(item) for item in migrated_list):
            continue

        stock_profile_items = [item for item in stock_list if is_profile_switcher_card(item)]
        if not stock_profile_items:
            continue

        profile_item = copy.deepcopy(stock_profile_items[0])

        # Respect five-card layout limit if this is a constrained card/button/widget list.
        if len(migrated_list) >= 5:
            # Replace the last non-protected item rather than exceeding layout capacity.
            replaced = False
            for idx in range(len(migrated_list) - 1, -1, -1):
                if not is_profile_switcher_card(migrated_list[idx]):
                    migrated_list[idx] = profile_item
                    replaced = True
                    break
            if not replaced:
                migrated_list[0] = profile_item
        else:
            migrated_list.append(profile_item)

        set_by_path(migrated, path, migrated_list)

    return migrated



def collect_profile_switcher_objects(obj: Any) -> list[Any]:
    """Collect exact stock custom button/profile switcher objects from stock settings."""
    found: list[Any] = []
    if isinstance(obj, dict):
        if is_profile_switcher_card(obj):
            found.append(copy.deepcopy(obj))
        for value in obj.values():
            found.extend(collect_profile_switcher_objects(value))
    elif isinstance(obj, list):
        for item in obj:
            found.extend(collect_profile_switcher_objects(item))
    return found


def has_profile_switcher_object(obj: Any) -> bool:
    if isinstance(obj, dict):
        if is_profile_switcher_card(obj):
            return True
        return any(has_profile_switcher_object(v) for v in obj.values())
    if isinstance(obj, list):
        return any(has_profile_switcher_object(v) for v in obj)
    return False


def inject_profile_switcher_into_profile_card(obj: Any, stock_profile_button: Any) -> Any:
    """
    If profile-card survived but its custom profile switcher button was removed,
    inject the stock button into the first plausible child list inside that card.
    """
    if isinstance(obj, dict):
        is_profile_card = normalized_card_id(obj) == "profile-card" or obj.get("id") == "profile-card"

        fixed = {k: inject_profile_switcher_into_profile_card(v, stock_profile_button) for k, v in obj.items()}

        if is_profile_card and not has_profile_switcher_object(fixed):
            # Prefer existing list fields likely to hold custom buttons.
            for key in ("buttons", "customButtons", "items", "widgets", "cards", "actions"):
                if isinstance(fixed.get(key), list):
                    if len(fixed[key]) >= 5:
                        fixed[key][-1] = copy.deepcopy(stock_profile_button)
                    else:
                        fixed[key].append(copy.deepcopy(stock_profile_button))
                    return fixed

            # Fallback: create customButtons if no list exists.
            fixed["customButtons"] = [copy.deepcopy(stock_profile_button)]

        return fixed

    if isinstance(obj, list):
        return [inject_profile_switcher_into_profile_card(item, stock_profile_button) for item in obj]

    return obj


def restore_stock_profile_button(migrated: dict[str, Any], stock_settings: dict[str, Any] | None) -> dict[str, Any]:
    """
    Restore the actual custom button that calls shell-profiles toggleProfiles.

    This handles GZML's setup where the profile switcher is not a native card
    entry but a custom button embedded in the profile-card/card section.
    """
    if not isinstance(stock_settings, dict):
        return migrated

    stock_buttons = [
        item for item in collect_profile_switcher_objects(stock_settings)
        if "plugin:shell-profiles" in object_text(item) or "toggleprofiles" in object_text(item)
    ]

    if not stock_buttons:
        return migrated

    if has_profile_switcher_object(migrated):
        return migrated

    return inject_profile_switcher_into_profile_card(migrated, stock_buttons[0])


def sanitize_settings(settings: dict[str, Any], existing_settings: dict[str, Any] | None = None) -> dict[str, Any]:
    user_settings = recursive_sanitize(copy.deepcopy(settings))

    if isinstance(existing_settings, dict):
        stock_settings = recursive_sanitize(copy.deepcopy(existing_settings))
        migrated = deep_merge_user_over_stock(user_settings, stock_settings)
    else:
        migrated = user_settings

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

    stock_for_restore = stock_settings if isinstance(existing_settings, dict) else None
    migrated = restore_stock_profile_switchers(migrated, stock_for_restore)
    migrated = restore_stock_profile_button(migrated, stock_for_restore)

    return migrated


def sanitize_plugins(
    plugins: dict[str, Any],
    preserve_plugins: set[str],
    existing_plugins: dict[str, Any] | None = None,
) -> dict[str, Any]:
    allowed = GZML_NATIVE_OR_KNOWN_COMPATIBLE_PLUGINS | preserve_plugins

    migrated: dict[str, Any] = {
        "sources": [],
        "states": {},
        "version": plugins.get("version", 2),
    }

    # Start from the freshly installed GZML plugin state so stock plugins remain visible.
    if isinstance(existing_plugins, dict):
        migrated["sources"] = copy.deepcopy(existing_plugins.get("sources", []))
        migrated["states"] = copy.deepcopy(existing_plugins.get("states", {}))
        migrated["version"] = existing_plugins.get("version", migrated["version"])

    states = plugins.get("states", {})
    if not isinstance(states, dict):
        return recursive_sanitize(migrated)

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

        sanitized_state = recursive_sanitize(new_state)

        if plugin_name in migrated["states"]:
            # Stock GZML plugins should keep their stock schema/metadata.
            # Only carry over the enabled flag when the migrated plugin is allowed.
            # This prevents old Noctalia plugin state from breaking newer bundled plugins.
            existing_state = migrated["states"][plugin_name]
            if isinstance(existing_state, dict):
                existing_state["enabled"] = bool(was_enabled and should_preserve)
                if was_enabled and not should_preserve:
                    existing_state["migrationNote"] = "Disabled during Noctalia -> GZML migration until plugin compatibility is confirmed."
                migrated["states"][plugin_name] = recursive_sanitize(existing_state)
            else:
                migrated["states"][plugin_name] = sanitized_state
        else:
            migrated["states"][plugin_name] = sanitized_state

    return recursive_sanitize(migrated)


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
            existing_settings = None
            target_settings_path = target / "settings.json"
            if target_settings_path.exists():
                existing_settings = load_json(target_settings_path)
            write_json(target_settings_path, fix_profile_switcher_in_card_layouts(sanitize_settings(settings, existing_settings)), dry_run=dry_run)
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
            existing_plugins = None
            target_plugins_path = target / "plugins.json"
            if target_plugins_path.exists():
                existing_plugins = load_json(target_plugins_path)
            write_json(target_plugins_path, sanitize_plugins(plugins, preserve_plugins, existing_plugins), dry_run=dry_run)
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
