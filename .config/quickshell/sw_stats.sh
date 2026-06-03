#!/bin/bash

# Fetch software stats
os_name=$(grep "^NAME=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
wm_name="Hyprland" # Hardcoded as we are in Hyprland config
sh_name=$SHELL

# Return as JSON
printf '{"os": "%s", "wm": "%s", "sh": "%s"}\n' "$os_name" "$wm_name" "$sh_name"