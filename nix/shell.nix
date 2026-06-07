{
  quickshell,
  nixfmt,
  statix,
  deadnix,
  shfmt,
  shellcheck,
  jsonfmt,
  lefthook,
  kdePackages,
  mkShellNoCC,
}:
mkShellNoCC {
  packages = [
    quickshell

    # Nix tooling
    nixfmt
    statix
    deadnix

    # Shell tooling
    shfmt
    shellcheck

    # JSON tooling
    jsonfmt

    # QML tooling
    kdePackages.qtdeclarative

    # Git hooks
    lefthook
  ];
}
