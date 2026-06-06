#!/bin/bash

# ===========================================================================
# MASTER THEME SCRIPT (theme.sh)
# ===========================================================================

# --- VARIABLES ---
# Path to your wallpaper
WALLPAPER="$HOME/.config/wall/catwall.png"

# --- FUNCTIONS ---

# Function to set wallpaper using swaybg
set_wallpaper() {
    if command -v swaybg > /dev/null; then
        pkill swaybg
        swaybg -i "$WALLPAPER" -m fill &
        echo "Wallpaper set with swaybg."
    else
        echo "swaybg not found, skipping wallpaper set."
    fi
}

# Function to report SDDM theme status.
set_sddm_wallpaper() {
    if [ -f /etc/sddm.conf.d/terminal-noir.conf ] && grep -q "Current=terminal-noir" /etc/sddm.conf.d/terminal-noir.conf; then
        echo "SDDM is configured for terminal-noir."
    else
        echo "Run scripts/install-sddm-theme.sh to install the Terminal Noir SDDM theme."
    fi
}

# Function to restart Waybar
restart_waybar() {
    pkill waybar
    waybar &
    echo "Waybar restarted."
}

# Function to restart Quickshell
restart_quickshell() {
    pkill quickshell
    quickshell -p ~/.config/quickshell/shell.qml &
    echo "Quickshell restarted."
}

# --- MAIN EXECUTION ---

echo "Applying rice settings..."

set_wallpaper
set_sddm_wallpaper

restart_waybar
restart_quickshell

echo "Rice settings applied."
