# GZML Shell

GZML Shell is a standalone desktop shell built with Quickshell, designed to provide a modern, customizable,  desktop experience while maintaining a clear separation between shell components and user configuration.

Unlike traditional dotfile collections or configuration overlays, GZML Shell is packaged as its own shell environment. Updates are designed to preserve user configuration, allowing the shell itself to evolve independently from personal settings, profiles, themes, and customizations.

The project focuses on flexibility, long-term maintainability, and user ownership of configuration while providing an approachable first-run experience for new users.

## Installation

Current development and testing primarily targets Arch-based distributions, with additional installer support planned for Fedora, Debian/Ubuntu, and openSUSE families.

```bash
git clone https://github.com/zero-j89/gzml_shell.git
cd gzml_shell
./install.sh
```

The installer checks for required dependencies, asks before installing missing packages, installs the shell source, creates the initial user configuration when needed, and preserves existing user settings during future updates.

## Profiles

GZML Shell includes a built-in profile system that allows users to maintain multiple independent shell configurations.

Profiles are user-created and user-managed. The project intentionally ships with a clean default experience rather than preloaded personal profiles.

## Plugins

GZML Shell supports optional plugins and modular functionality, including compatibility with Noctalia v4 plugins.

Only the plugins required by the factory default configuration are enabled by default. Additional plugins remain available for users who wish to extend functionality without forcing unnecessary components into every installation.

## IPC Commands

GZML Shell exposes functionality through Quickshell IPC, allowing integration with keybinds, scripts, launchers, automation tools, and external applications.

### Profile Switcher

```bash
qs -p ~/.local/share/gzml-shell ipc call plugin:shell-profiles toggleProfiles
```

### Wallpaper Selector

```bash
qs -p ~/.local/share/gzml-shell ipc call plugin:wallcards toggle
```

### IPC Discovery

```bash
qs -p ~/.local/share/gzml-shell ipc
```

or, depending on the installed Quickshell version:

```bash
qs -p ~/.local/share/gzml-shell ipc list
```

Additional IPC endpoints will be documented as the API stabilizes.

## Automatic Startup

To launch GZML Shell automatically, add the launch command to your compositor or session startup configuration:

```bash
qs -p ~/.local/share/gzml-shell
```

For Hyprland Lua configurations:

```lua
hl.exec_once("qs -p ~/.local/share/gzml-shell")
```

For legacy Hyprland `.conf` configurations(Soon to be outdated)2:

```ini
exec-once = qs -p ~/.local/share/gzml-shell
```

Equivalent startup methods can be used with other compositors and desktop environments.

## Credits

GZML Shell would not exist without the work of the Quickshell project, the Noctalia developers, and the many open-source contributors whose work continues to make projects like this possible.
