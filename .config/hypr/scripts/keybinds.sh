#!/usr/bin/env bash

set -euo pipefail

cat <<'KEYS' | rofi -dmenu -i -p "keybinds" -theme-str 'entry { placeholder: "Search keybinds"; }' >/dev/null
SUPER + T                 Terminal
SUPER + Space             App launcher
SUPER + /                 Keybind help
SUPER + V                 Clipboard
SUPER + .                 Emoji picker
SUPER + CTRL + L          Lock
SUPER + M                 Logout menu
SUPER + Q                 Close focused window
SUPER + SHIFT + V         Toggle floating
SUPER + F                 Fullscreen
SUPER + H/J/K/L           Focus window
SUPER + SHIFT + H/J/K/L   Move window
SUPER + 1..5              Switch workspace
SUPER + SHIFT + 1..5      Move window to workspace
Print                     Screenshot menu
SUPER + SHIFT + P         Color picker
Fn + F1 / XF86AudioMute        Mute volume
Fn + F2 / XF86AudioLowerVolume Volume down
Fn + F3 / XF86AudioRaiseVolume Volume up
Fn + F9 / XF86BrightnessDown   Brightness down
Fn + F10 / XF86BrightnessUp    Brightness up
KEYS
