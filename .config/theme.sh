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

# Function to set wallpaper for SDDM (currently ensures theme is set)
set_sddm_wallpaper() {
    # SDDM is currently configured to use a pure black background via Main.qml and theme.conf.
    # If you want to use an actual image, you would modify Main.qml to show the image,
    # and then place the image in /usr/share/sddm/themes/sddm-astronaut-theme/
    # For now, we ensure the SDDM theme is set to our custom one.
    if [ -f /etc/sddm.conf ]; then
        if ! grep -q "Current=sddm-astronaut-theme" /etc/sddm.conf; then
            echo "Updating SDDM theme to sddm-astronaut-theme..."
            sudo sed -i '/^\[Theme\]/,/^\[/ s/^Current=.*/Current=sddm-astronaut-theme/' /etc/sddm.conf
            # Fallback if theme section is missing
            if ! grep -q "Current=sddm-astronaut-theme" /etc/sddm.conf; then
                echo -e "[Theme]\nCurrent=sddm-astronaut-theme" | sudo tee -a /etc/sddm.conf > /dev/null
            fi
            echo "Please restart SDDM for changes to take effect: sudo systemctl restart sddm"
        fi
    fi

    echo "SDDM theme configuration checked."
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
