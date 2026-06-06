install_dependencies() {
  echo
  echo "Debian / Ubuntu support is experimental."
  echo "Dependency installation is currently manual."
  echo
  echo "Please ensure the README dependencies are installed."
  echo

  if ! ask_yes_no "Continue anyway?"; then
    exit 1
  fi
}
