install_dependencies() {
  local pacman_deps=(
    quickshell
    qt6-declarative
    qt6-svg
    qt6-multimedia
    qt6-5compat
    jq
    rsync
    git
    python
    wl-clipboard
    grim
    slurp
    swappy
    brightnessctl
    pamixer
    playerctl
    networkmanager
    bluez
    bluez-utils
    pavucontrol
  )

  local missing_pacman=()
  local missing_aur=()

  echo
  echo "Checking Arch dependencies..."

  for pkg in "${pacman_deps[@]}"; do
    pacman -Qi "$pkg" >/dev/null 2>&1 || missing_pacman+=("$pkg")
  done

  # Accept either package as satisfying the matugen dependency.
  if ! pacman -Qi matugen >/dev/null 2>&1 && ! pacman -Qi matugen-bin >/dev/null 2>&1; then
    missing_aur+=("matugen-bin")
  fi

  if [ "${#missing_pacman[@]}" -eq 0 ] && [ "${#missing_aur[@]}" -eq 0 ]; then
    echo "All required dependencies are already installed."
    return 0
  fi

  echo
  echo "Missing dependencies:"
  for pkg in "${missing_pacman[@]}"; do echo "  pacman: $pkg"; done
  for pkg in "${missing_aur[@]}"; do echo "  AUR:    $pkg"; done
  echo

  if ! ask_yes_no "Install missing dependencies now?"; then
    echo
    echo "Skipping dependency installation."
    echo "Continuing with GZML Shell installation anyway."
    echo "Some features may not work until the missing dependencies are installed."
    echo
    return 0
  fi

  if [ "${#missing_pacman[@]}" -gt 0 ]; then
    echo
    echo "Installing pacman dependencies..."
    if ! sudo pacman -S --needed "${missing_pacman[@]}"; then
      echo
      echo "WARNING: Some pacman dependencies failed to install."
      echo "Continuing with GZML Shell installation anyway."
      echo
    fi
  fi

  if [ "${#missing_aur[@]}" -gt 0 ]; then
    echo
    echo "Installing AUR dependencies..."

    if command -v yay >/dev/null 2>&1; then
      if ! yay -S --needed "${missing_aur[@]}"; then
        echo
        echo "WARNING: Some AUR dependencies failed to install."
        echo "Continuing with GZML Shell installation anyway."
        echo
      fi
    elif command -v paru >/dev/null 2>&1; then
      if ! paru -S --needed "${missing_aur[@]}"; then
        echo
        echo "WARNING: Some AUR dependencies failed to install."
        echo "Continuing with GZML Shell installation anyway."
        echo
      fi
    else
      echo
      echo "WARNING: AUR dependencies are missing, but yay/paru was not found."
      echo "Continuing with GZML Shell installation anyway."
      echo
    fi
  fi
}
