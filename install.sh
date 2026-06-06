#!/usr/bin/env bash
set -euo pipefail

APP_NAME="GZML Shell"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLERS_DIR="$SRC_DIR/installers"

# Hard installed / update-replaced source copy.
# This is the immutable source artifact and keeps payload/default-config.
INSTALL_DIR="$HOME/.local/share/gzml-shell"

# User profile/config payload seeded from payload/default-config.
# This is user-owned and must not be blindly overwritten.
CONFIG_DIR="$HOME/.config/gzml-shell"

# Quickshell-facing runnable user layer, equivalent to quickshell-noctalia.
# This mirrors the installed shell tree EXCEPT payload/ and is what qs launches.
QS_CONFIG_DIR="$HOME/.config/quickshell-gzml"

# Runtime/cache data.
CACHE_DIR="$HOME/.cache/gzml-shell"

detect_distro() {
  if [ ! -f /etc/os-release ]; then
    echo "unknown"
    return
  fi

  . /etc/os-release

  case "${ID_LIKE:-$ID}" in
    *arch*) echo "arch" ;;
    *fedora*|*rhel*) echo "fedora" ;;
    *debian*|*ubuntu*) echo "debian" ;;
    *suse*) echo "opensuse" ;;
    *)
      case "$ID" in
        arch|endeavouros|cachyos|manjaro) echo "arch" ;;
        fedora) echo "fedora" ;;
        ubuntu|debian|linuxmint|pop) echo "debian" ;;
        opensuse*|sles) echo "opensuse" ;;
        *) echo "unknown" ;;
      esac
      ;;
  esac
}

ask_yes_no() {
  local prompt="$1"
  local answer
  read -rp "$prompt [y/N]: " answer
  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

install_shell_source() {
  echo
  echo "Installing hard shell source..."

  mkdir -p "$(dirname "$INSTALL_DIR")"
  rm -rf "$INSTALL_DIR"
  mkdir -p "$INSTALL_DIR"

  rsync -a \
    --exclude '.git' \
    --exclude '.gitignore' \
    --exclude 'install.sh' \
    "$SRC_DIR/" "$INSTALL_DIR/"

  if [ ! -d "$INSTALL_DIR/payload/default-config" ]; then
    echo "ERROR: payload/default-config missing after install."
    exit 1
  fi

  echo "$SRC_DIR" > "$INSTALL_DIR/repo-path"
}

install_quickshell_layer() {
  echo
  echo "Installing Quickshell runnable layer..."

  mkdir -p "$QS_CONFIG_DIR"

  # Preserve user-owned runtime plugin folder if it already exists.
  # The rest of quickshell-gzml mirrors the installed shell source without payload/.
  if [ -d "$QS_CONFIG_DIR/plugins" ] && [ ! -L "$QS_CONFIG_DIR/plugins" ]; then
    tmp_plugins="$(mktemp -d)"
    rsync -a "$QS_CONFIG_DIR/plugins/" "$tmp_plugins/plugins/"
  else
    tmp_plugins=""
  fi

  rsync -a --delete \
    --exclude 'payload' \
    --exclude 'repo-path' \
    --exclude '.git' \
    --exclude '.gitignore' \
    --exclude 'install.sh' \
    --exclude 'plugins' \
    "$INSTALL_DIR/" "$QS_CONFIG_DIR/"

  if [ -n "${tmp_plugins:-}" ]; then
    mkdir -p "$QS_CONFIG_DIR/plugins"
    rsync -a "$tmp_plugins/plugins/" "$QS_CONFIG_DIR/plugins/"
    rm -rf "$tmp_plugins"
  else
    mkdir -p "$QS_CONFIG_DIR/plugins"
  fi

  cat > "$QS_CONFIG_DIR/source-path" <<EOF2
$INSTALL_DIR
EOF2

  cat > "$QS_CONFIG_DIR/config-path" <<EOF2
$CONFIG_DIR
EOF2

  cat > "$QS_CONFIG_DIR/cache-path" <<EOF2
$CACHE_DIR
EOF2

  cat > "$QS_CONFIG_DIR/env" <<EOF2
GZML_SHELL_SOURCE="$INSTALL_DIR"
GZML_SHELL_CONFIG="$CONFIG_DIR"
GZML_SHELL_QS_CONFIG="$QS_CONFIG_DIR"
GZML_SHELL_CACHE="$CACHE_DIR"
EOF2
}

install_noctalia_plugin_compat() {
  echo
  echo "Installing Noctalia plugin compatibility layer..."

  mkdir -p "$HOME/.config/noctalia"
  mkdir -p "$QS_CONFIG_DIR/plugins"

  if [ -e "$HOME/.config/noctalia/plugins" ] && [ ! -L "$HOME/.config/noctalia/plugins" ]; then
    echo "Existing ~/.config/noctalia/plugins detected."
    echo "Leaving it untouched to avoid data loss."
    return 0
  fi

  ln -sfn "$QS_CONFIG_DIR/plugins" "$HOME/.config/noctalia/plugins"
}

seed_user_config() {
  echo
  echo "Checking user config..."

  mkdir -p "$CACHE_DIR"

  if [ -f "$CONFIG_DIR/settings.json" ]; then
    echo "Existing user config found. Leaving untouched:"
    echo "  $CONFIG_DIR"
    FIRST_RUN=0
    return
  fi

  echo "Creating first-run config from payload/default-config..."
  mkdir -p "$CONFIG_DIR"
  cp -a "$INSTALL_DIR/payload/default-config/." "$CONFIG_DIR/"
  FIRST_RUN=1
}

install_launcher() {
  echo
  echo "Installing launcher command..."

  mkdir -p "$HOME/.local/bin"

  cat > "$HOME/.local/bin/gzml-shell" <<'LAUNCHER'
#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$HOME/.local/share/gzml-shell"
CONFIG_DIR="$HOME/.config/gzml-shell"
QS_CONFIG_DIR="$HOME/.config/quickshell-gzml"
CACHE_DIR="$HOME/.cache/gzml-shell"

export GZML_SHELL_SOURCE="$INSTALL_DIR"
export GZML_SHELL_CONFIG="$CONFIG_DIR"
export GZML_SHELL_QS_CONFIG="$QS_CONFIG_DIR"
export GZML_SHELL_CACHE="$CACHE_DIR"

exec qs -p "$QS_CONFIG_DIR" "$@"
LAUNCHER

  chmod +x "$HOME/.local/bin/gzml-shell"
}

install_updater() {
  echo
  echo "Installing updater command..."

  mkdir -p "$HOME/.local/bin"

  cat > "$HOME/.local/bin/gzml-shell-update" <<'UPDATER'
#!/usr/bin/env bash
set -euo pipefail

REPO_FILE="$HOME/.local/share/gzml-shell/repo-path"

if [ ! -f "$REPO_FILE" ]; then
    echo "Repository path file not found:"
    echo "  $REPO_FILE"
    echo
    echo "Please reinstall GZML Shell."
    exit 1
fi

REPO="$(cat "$REPO_FILE")"

if [ ! -d "$REPO/.git" ]; then
    echo "GZML Shell repository not found:"
    echo "  $REPO"
    echo
    echo "Please reinstall GZML Shell."
    exit 1
fi

echo "Updating GZML Shell from:"
echo "  $REPO"
echo

git -C "$REPO" fetch origin
git -C "$REPO" reset --hard origin/main

echo
echo "Running installer..."
bash "$REPO/install.sh"

echo
echo "Update complete."
UPDATER

  chmod +x "$HOME/.local/bin/gzml-shell-update"
}

verify_install() {
  echo
  echo "Verifying install..."

  [ -d "$INSTALL_DIR" ] || { echo "Missing $INSTALL_DIR"; exit 1; }
  [ -d "$INSTALL_DIR/payload/default-config" ] || { echo "Missing payload/default-config"; exit 1; }
  [ -f "$CONFIG_DIR/settings.json" ] || { echo "Missing $CONFIG_DIR/settings.json"; exit 1; }
  [ -d "$QS_CONFIG_DIR" ] || { echo "Missing $QS_CONFIG_DIR"; exit 1; }
  [ -f "$QS_CONFIG_DIR/shell.qml" ] || { echo "Missing $QS_CONFIG_DIR/shell.qml"; exit 1; }
  [ ! -d "$QS_CONFIG_DIR/payload" ] || { echo "ERROR: payload should not exist in $QS_CONFIG_DIR"; exit 1; }
  [ -d "$CACHE_DIR" ] || { echo "Missing $CACHE_DIR"; exit 1; }

  echo "Install verified."
}

launch_prompt() {
  echo
  echo "$APP_NAME installed."
  echo "Source:           $INSTALL_DIR"
  echo "Config:           $CONFIG_DIR"
  echo "Quickshell layer: $QS_CONFIG_DIR"
  echo "Cache:            $CACHE_DIR"
  echo

  if ask_yes_no "Launch GZML Shell now?"; then
    if [ "$FIRST_RUN" = "1" ]; then
      GZML_SHELL_FIRST_RUN=1 "$HOME/.local/bin/gzml-shell"
    else
      "$HOME/.local/bin/gzml-shell"
    fi
  else
    echo "Launch later with:"
    echo "  gzml-shell"
  fi
}

echo "================================="
echo "        $APP_NAME Installer"
echo "================================="
echo

DISTRO="$(detect_distro)"
echo "Detected distro family: $DISTRO"

case "$DISTRO" in
  arch)
    source "$INSTALLERS_DIR/deps-arch.sh"
    ;;
  fedora)
    source "$INSTALLERS_DIR/deps-fedora.sh"
    ;;
  debian)
    source "$INSTALLERS_DIR/deps-debian.sh"
    ;;
  opensuse)
    source "$INSTALLERS_DIR/deps-opensuse.sh"
    ;;
  *)
    echo "Unsupported or unknown distro."
    echo "You can still install the shell source, but dependencies must be installed manually."
    if ! ask_yes_no "Continue without dependency installation?"; then
      exit 1
    fi
    install_dependencies() { echo "Skipping dependency installation."; }
    ;;
esac

FIRST_RUN=0

install_dependencies
install_shell_source
install_quickshell_layer
install_noctalia_plugin_compat
install_launcher
install_updater
seed_user_config
verify_install
launch_prompt
