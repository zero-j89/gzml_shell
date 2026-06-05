cat > install.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

APP_NAME="GZML Shell"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLERS_DIR="$SRC_DIR/installers"

INSTALL_DIR="$HOME/.local/share/gzml-shell"
CONFIG_DIR="$HOME/.config/gzml-shell"
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
  echo "Installing shell source..."

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

verify_install() {
  echo
  echo "Verifying install..."

  [ -d "$INSTALL_DIR" ] || { echo "Missing $INSTALL_DIR"; exit 1; }
  [ -d "$INSTALL_DIR/payload/default-config" ] || { echo "Missing payload/default-config"; exit 1; }
  [ -f "$CONFIG_DIR/settings.json" ] || { echo "Missing $CONFIG_DIR/settings.json"; exit 1; }
  [ -d "$CACHE_DIR" ] || { echo "Missing $CACHE_DIR"; exit 1; }

  echo "Install verified."
}

launch_prompt() {
  echo
  echo "$APP_NAME installed."
  echo "Source: $INSTALL_DIR"
  echo "Config: $CONFIG_DIR"
  echo "Cache:  $CACHE_DIR"
  echo

  if ask_yes_no "Launch GZML Shell now?"; then
    if [ "$FIRST_RUN" = "1" ]; then
      GZML_SHELL_FIRST_RUN=1 qs -p "$INSTALL_DIR"
    else
      qs -p "$INSTALL_DIR"
    fi
  else
    echo "Launch later with:"
    echo "  qs -p $INSTALL_DIR"
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
seed_user_config
verify_install
launch_prompt
EOF

