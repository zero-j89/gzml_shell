# Special Workspaces (Hyprland)

A widget to track Hyprland special workspaces.

### Requirements

* Hyprland
* Noctalia (duh.)

## Features

- The widget appears as a single dimmed button (Drawer) while no special workspace is active. It restores its opacity when any special workspace is active, focused or not.
- It expands and shows special workspaces when a special workspace is focused.
- Inactive special workspaces are shown dimmed.
- When the expand direction is perpendicular to the bar (e.g. left/right on a vertical bar), the workspaces open in a floating panel instead of expanding inline. The panel also auto-opens and closes as you switch in and out of special workspaces.
- Fully customizable:
  * Drawer toggle, hide the workspace buttons until a special workspace is active
  * Hide empty workspaces, only show buttons for workspaces that currently exist in Hyprland
  * Expanding direction (up/down/left/right)
  * Panel background toggle and color (panel mode only)
  * Pill toggles, color and size (independent for drawer/workspace buttons)
  * Icon color (independent for drawer/workspace buttons)
  * Focus button color
  * Border radius
  * Add/remove workspace entries and assign icons to them

**The widget doesn't actually add/remove special workspaces to Hyprland. The add/remove function only changes if a special workspace has a button on the widget or not. The widget expands even if a special workspace isn't added to it but is focused. I recommend adding all of the special workspaces defined in your Hyprland config to the widget to make full use of this plugin.**

### Usage

The widget expands when a special workspace is focused. The workspace buttons also function as toggle shortcuts, e.g. clicking one switches to that workspace or hides it if it's already focused.
