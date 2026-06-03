# Project Context: Monochrome Linux Rice ("Terminal Noir")

## 1. Project Goal
The objective of this project is to build a highly customized, visually striking Linux desktop environment (a "rice") on **EndeavourOS (Arch Linux)** using the **Hyprland** window manager. 

The design philosophy is strictly **"Monochrome & Sharp"** (referred to as the `Terminal Noir` theme in `designs/DESIGN.md`). 
*   **Palette:** Pitch black (`#000000`, `#0a0a0a`), shades of grey (`#1c1c1c`, `#333333`, `#555555`, `#888888`), and pure white (`#ffffff`, `#e0e0e0`) for active states.
*   **Geometry:** Strictly 0px border radius (sharp corners) everywhere. No drop shadows. No blur.
*   **Typography:** JetBrains Mono Nerd Font exclusively.

## 2. Core Stack & Packages Used
We transitioned from basic GTK tools to a high-performance, scriptable stack:
*   **Window Manager:** `hyprland`
*   **Status Bar:** `waybar`
*   **Wallpaper Daemon:** `swaybg` (Replaced `swww`/`awww` and `hyprpaper` for maximum stability).
*   **Widgets & Control Center:** `quickshell-git` (Qt6/QML based, installed from AUR, replacing AGS v1 due to deprecation/build issues).
*   **Notifications:** `dunst`
*   **Launcher:** `rofi-wayland` (Replacing `wofi` for better multi-line layout support).
*   **Terminal:** `kitty`
*   **Hardware/System Utilities:** `brightnessctl`, `pavucontrol`, `bluez`, `networkmanager`.

## 3. Work Completed

### A. Hyprland Configuration (`hyprland.conf`)
*   Fixed breaking changes from Hyprland v0.40+ and v0.55+.
*   Moved `drop_shadow` to the nested `shadow { enabled = false }` block.
*   Removed deprecated `vfr` setting from the `misc` block.
*   Updated window rules to the unified v0.55+ syntax: `windowrule = match:class ^(wlogout)$, float on`.
*   Set `exec-once = swaybg -i ~/.config/wall/catwall.png -m fill` for the wallpaper.
*   Set `exec-once = quickshell -p ~/.config/quickshell/shell.qml` to boot the widget engine.

### B. Waybar (`config.jsonc` & `style.css`)
*   **Visuals:** Rebuilt the CSS to match the reference design perfectly. Implemented square, contiguous workspace buttons with a 1px right border for subtle separation.
*   **Clock Fix:** Fixed a crash caused by improper formatting strings. Waybar now uses `{0:%a}`, `{0:%I:%M}`, and `{0:%p}` to format the single time object correctly.
*   **Icons & Tooltips:** Enabled dynamic application icons for the window module (`"icon": true`) and disabled the raw HTML tooltips (`"tooltip": false`).
*   **Interactivity:** Replaced direct GTK app launches on the right-side modules. Clicking Network, Bluetooth, or Volume now sends an IPC command: `"on-click": "quickshell ipc call controlcenter toggle"`.

### C. Quickshell Implementation (`shell.qml`)
We pivoted to Quickshell (QML) to build custom, floating widgets that stick to the desktop layer (`WlrLayer.Bottom`) so they don't overlap application windows.

1.  **Spotify Capsule (Bottom-Left):**
    *   Uses native `Quickshell.Services.Mpris`.
    *   Displays album art, title, artist, and playback controls (Prev/Play/Pause/Next).
2.  **System Dashboard (Bottom-Right):**
    *   Uses `Quickshell.Io.Process` to run `hw_stats.sh` and `sw_stats.sh` every 5 seconds, parsing the JSON output.
    *   Uses `textFormat: Text.RichText` to achieve a two-tone text effect (e.g., `<font color='#555555'>CPU</font> Ryzen 7`).
3.  **Unified Control Center (Top-Right):**
    *   Created `ControlCenter.qml` to replace individual GTK settings menus.
    *   Features a 2x2 grid for Wi-Fi and Bluetooth toggles (executing `nmcli` and `rfkill` via `Quickshell.Io.Process`).
    *   Features custom linear sliders for Volume (using native `Quickshell.Services.Pipewire`) and Brightness (wrapping `brightnessctl`).
    *   Exposes a `toggle()` function via `IpcHandler` mapped to the target "controlcenter".

### D. Setup Scripts
*   **`theme.sh`:** Updated to gracefully restart `waybar`, `dunst`, `quickshell`, and apply the wallpaper using `swaybg`.
*   **`verify-rice.sh`:** Refactored to use Arch Linux (`pacman`/`yay`) package names instead of Debian/Ubuntu (`apt`).

## 4. Current State
The system is fully functional, styled correctly, and all configuration errors have been resolved. The next agent can focus on expanding the Quickshell QML widgets, refining the Rofi/SwayNC implementations, or adding application-specific theming (e.g., Firefox, Discord) to match the Terminal Noir aesthetic.