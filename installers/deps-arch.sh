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

  local aur_deps=(
  )

  local missing_pacman=()
  local missing_aur=()

  echo
  echo "Checking Arch dependencies..."

  for pkg in "${pacman_deps[@]}"; do
    pacman -Qi "$pkg" >/dev/null 2>&1 || missing_pacman+=("$pkg")
  done

  # matugen may be installed as either repo package "matugen" or AUR package "matugen-bin".
  if ! pacman -Qi matugen >/dev/null 2>&1 && ! pacman -Qi matugen-bin >/dev/null 2>&1; then
    missing_aur+=("matugen-bin")
  fi

  for pkg in "${aur_deps[@]}"; do
    pacman -Qi "$pkg" >/dev/null 2>&1 || missing_aur+=("$pkg")
  done

  if [ "${#missing_pacman[@]}" -eq 0 ] && [ "${#missing_aur[@]}" -eq 0 ]; then
    echo "All dependencies are already installed."
    return
  fi

  echo
  echo "Missing dependencies:"
  for pkg in "${missing_pacman[@]}"; do echo "  pacman: $pkg"; done
  for pkg in "${missing_aur[@]}"; do echo "  AUR:    $pkg"; done
  echo

  if ! ask_yes_no "Install missing dependencies now?"; then
    echo
    echo "Dependency installation skipped."
    echo "GZML Shell will still be installed, but some features may not work until missing dependencies are installed."
    echo
    return
  fi

  if [ "${#missing_pacman[@]}" -gt 0 ]; then
    sudo pacman -S --needed "${missing_pacman[@]}"
  fi

  if [ "${#missing_aur[@]}" -gt 0 ]; then
    if command -v yay >/dev/null 2>&1; then
      yay -S --needed "${missing_aur[@]}"
    elif command -v paru >/dev/null 2>&1; then
      paru -S --needed "${missing_aur[@]}"
    else
      echo "ERROR: Missing AUR deps but yay/paru was not found:"
      printf '  %s\n' "${missing_aur[@]}"
      exit 1
    fi
  fi
}
