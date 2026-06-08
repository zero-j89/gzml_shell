install_dependencies() {
  local deps=(
    quickshell
    git
    rsync
    jq
    python3
    wl-clipboard
    grim
    slurp
    swappy
    brightnessctl
    playerctl
    NetworkManager
    bluez
    bluez-tools
    pavucontrol
    qt6-qtdeclarative
    qt6-qtsvg
    qt6-qtmultimedia
    adw-gtk3-theme
  )

  local missing=()

  echo
  echo "Checking Fedora dependencies..."

  for pkg in "${deps[@]}"; do
    rpm -q "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done

  if [ "${#missing[@]}" -eq 0 ]; then
    echo "All required dependencies are already installed."
    return 0
  fi

  echo
  echo "Missing dependencies:"
  for pkg in "${missing[@]}"; do
    echo "  dnf: $pkg"
  done
  echo

  echo "NOTE: If quickshell is missing, Fedora users may need the Quickshell COPR:"
  echo "  sudo dnf copr enable errornointernet/quickshell"
  echo

  if ! ask_yes_no "Install missing dependencies now?"; then
    echo
    echo "Skipping dependency installation."
    echo "Continuing with GZML Shell installation anyway."
    echo "Some features may not work until the missing dependencies are installed."
    echo
    return 0
  fi

  if ! sudo dnf install -y "${missing[@]}"; then
    echo
    echo "WARNING: Some Fedora dependencies failed to install."
    echo "If quickshell failed, try:"
    echo "  sudo dnf copr enable errornointernet/quickshell"
    echo "  sudo dnf install quickshell"
    echo
    echo "Continuing with GZML Shell installation anyway."
    echo
  fi
}
