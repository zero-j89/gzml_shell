{
  version ? "dirty",
  extraPackages ? [ ],
  runtimeDeps ? [
    brightnessctl
    cliphist
    ddcutil
    wlsunset
    wl-clipboard
    wlr-randr
    imagemagick
    wget
    (python3.withPackages (pp: lib.optional calendarSupport pp.pygobject3))
  ],

  lib,
  stdenvNoCC,
  # build
  qt6,
  quickshell,
  makeWrapper,
  # runtime deps
  brightnessctl,
  cliphist,
  ddcutil,
  wlsunset,
  wl-clipboard,
  wlr-randr,
  imagemagick,
  wget,
  python3,
  wayland-scanner,
  # calendar support
  calendarSupport ? false,
  evolution-data-server,
  libical,
  glib,
  libsoup_3,
  json-glib,
  gobject-introspection,
}:
let
  src = lib.cleanSourceWith {
    src = ../.;
    filter =
      path: type:
      !(builtins.any (prefix: lib.path.hasPrefix (../. + prefix) (/. + path)) [
        /.github
        /.git
        /.gitignore
        /Assets/Screenshots
        /Scripts/dev
        /nix
        /LICENSE
        /README.md
        /flake.nix
        /flake.lock
        /shell.nix
        /lefthook.yml
        /CLAUDE.md
        /CREDITS.md
      ]);
  };

  giTypelibPath = lib.makeSearchPath "lib/girepository-1.0" [
    evolution-data-server
    libical
    glib.out
    libsoup_3
    json-glib
    gobject-introspection
  ];
in
stdenvNoCC.mkDerivation {
  pname = "gzml-shell";
  inherit version src;

  nativeBuildInputs = [
    qt6.wrapQtAppsHook
    makeWrapper
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtmultimedia
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/gzml-shell $out/bin
    cp -r . $out/share/gzml-shell

    makeWrapper ${quickshell}/bin/qs $out/bin/gzml-shell \
      --add-flags "-p $out/share/gzml-shell" \
      --prefix PATH : ${lib.makeBinPath (runtimeDeps ++ extraPackages)} \
      --prefix XDG_DATA_DIRS : ${wayland-scanner}/share \
      --prefix QML2_IMPORT_PATH : ${qt6.qtmultimedia}/lib/qt-6/qml \
      --prefix QML_IMPORT_PATH : ${qt6.qtmultimedia}/lib/qt-6/qml \
      --prefix QT_PLUGIN_PATH : ${qt6.qtmultimedia}/lib/qt-6/plugins \
      --set-default QS_CONFIG_PATH "$out/share/gzml-shell" \
      --set-default GZML_SHELL_SOURCE "$out/share/gzml-shell" \
      --set-default GZML_SHELL_QS_CONFIG "$out/share/gzml-shell" \
      --run 'export GZML_SHELL_CONFIG="''${XDG_CONFIG_HOME:-$HOME/.config}/gzml-shell"' \
      --run 'export GZML_SHELL_CACHE="''${XDG_CACHE_HOME:-$HOME/.cache}/gzml-shell"'

    runHook postInstall
  '';

  preFixup = ''
    qtWrapperArgs+=(
      ${lib.optionalString calendarSupport "--prefix GI_TYPELIB_PATH : ${giTypelibPath}"}
    )
  '';

  meta = {
    description = "GZML Shell - a Wayland desktop shell built with Quickshell.";
    homepage = "https://github.com/zero-j89/gzml_shell";
    license = lib.licenses.mit;
    mainProgram = "gzml-shell";
    platforms = lib.platforms.linux;
  };
}
