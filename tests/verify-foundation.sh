#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail_count=0

fail() {
    printf 'FAIL: %s\n' "$1"
    fail_count=$((fail_count + 1))
}

pass() {
    printf 'PASS: %s\n' "$1"
}

require_file() {
    local path="$1"
    if [ -f "$repo_root/$path" ]; then
        pass "$path exists"
    else
        fail "$path is missing"
    fi
}

require_executable() {
    local path="$1"
    if [ -x "$repo_root/$path" ]; then
        pass "$path is executable"
    else
        fail "$path is missing or not executable"
    fi
}

require_contains() {
    local path="$1"
    local pattern="$2"
    local label="$3"

    if [ ! -f "$repo_root/$path" ]; then
        fail "$path is missing for $label"
        return
    fi

    if grep -Eq "$pattern" "$repo_root/$path"; then
        pass "$label"
    else
        fail "$label"
    fi
}

require_shell_syntax() {
    local path="$1"
    if [ ! -f "$repo_root/$path" ]; then
        fail "$path is missing for syntax check"
        return
    fi

    if bash -n "$repo_root/$path"; then
        pass "$path shell syntax"
    else
        fail "$path shell syntax"
    fi
}

require_file "scripts/pkg_core.lst"
require_executable "scripts/sync-config.sh"
require_executable "scripts/install-sddm-theme.sh"
require_executable ".config/hypr/scripts/lockscreen.sh"
require_executable ".config/hypr/scripts/logoutlaunch.sh"
require_executable ".config/hypr/scripts/volumecontrol.sh"
require_executable ".config/hypr/scripts/brightnesscontrol.sh"
require_executable ".config/hypr/scripts/resetxdgportal.sh"
require_executable ".config/hypr/scripts/keybinds.sh"
require_executable ".config/hypr/scripts/swayosd-launch.sh"
require_executable ".config/hypr/scripts/screenshot-menu.sh"

for file in \
    ".config/hypr/env.conf" \
    ".config/hypr/startup.conf" \
    ".config/hypr/keybindings.conf" \
    ".config/hypr/windowrules.conf" \
    ".config/hypr/monitors.conf" \
    ".config/hypr/userprefs.conf" \
    ".config/hypr/hypridle.conf" \
    ".config/Code/User/settings.json" \
    ".config/Code - OSS/User/settings.json" \
    ".config/VSCodium/User/settings.json" \
    ".config/vim/vimrc" \
    ".config/vim/colors/terminal-noir.vim" \
    ".config/code-flags.conf" \
    ".config/code-oss-flags.conf" \
    ".config/codium-flags.conf" \
    ".config/spotify-flags.conf" \
    ".config/spicetify/Themes/TerminalNoir/color.ini" \
    ".config/spicetify/Themes/TerminalNoir/user.css" \
    ".config/swayosd/config.toml" \
    ".config/swayosd/style.css" \
    "sddm/terminal-noir/Main.qml" \
    "sddm/terminal-noir/metadata.desktop" \
    "sddm/terminal-noir/Themes/terminal-noir.conf" \
    "sddm/terminal-noir/Components/Clock.qml" \
    "sddm/terminal-noir/Components/LoginForm.qml" \
    "sddm/terminal-noir/Components/Input.qml" \
    "sddm/terminal-noir/Components/SystemButtons.qml" \
    "sddm/terminal-noir/Components/SessionButton.qml" \
    "sddm/terminal-noir/Components/VirtualKeyboard.qml" \
    "sddm/terminal-noir/Components/VirtualKeyboardButton.qml" \
    "sddm/terminal-noir/Assets/User.svg" \
    "sddm/terminal-noir/Assets/Password.svg"; do
    require_file "$file"
done

require_contains ".config/hypr/hyprland.conf" '^source = .*/env\.conf$|^source = \./env\.conf$' "hyprland sources env.conf"
require_contains ".config/hypr/hyprland.conf" '^source = .*/startup\.conf$|^source = \./startup\.conf$' "hyprland sources startup.conf"
require_contains ".config/hypr/hyprland.conf" '^source = .*/keybindings\.conf$|^source = \./keybindings\.conf$' "hyprland sources keybindings.conf"
require_contains ".config/hypr/hyprland.conf" '^source = .*/windowrules\.conf$|^source = \./windowrules\.conf$' "hyprland sources windowrules.conf"
require_contains ".config/hypr/startup.conf" 'dbus-update-activation-environment' "startup imports dbus environment"
require_contains ".config/hypr/startup.conf" 'wl-paste --type text --watch cliphist store' "startup runs text clipboard watcher"
require_contains ".config/hypr/startup.conf" 'swayosd-server' "startup runs swayosd server"
require_contains ".config/hypr/startup.conf" 'hypridle' "startup runs hypridle"
require_contains ".config/hypr/startup.conf" 'hyprsunset' "startup runs hyprsunset"
require_contains ".config/hypr/keybindings.conf" 'slash, exec, .*keybinds\.sh' "keybindings include help overlay"
require_contains ".config/hypr/keybindings.conf" '^bind = , Print, exec, .*tnctl screenshot menu$' "print key opens screenshot menu"
require_contains ".config/hypr/keybindings.conf" 'volumecontrol\.sh' "keybindings use volume wrapper"
require_contains ".config/hypr/keybindings.conf" 'brightnesscontrol\.sh' "keybindings use brightness wrapper"
require_contains ".config/hypr/scripts/keybinds.sh" 'Print[[:space:]]+Screenshot menu' "keybind help shows screenshot menu"
require_contains ".config/hypr/scripts/screenshot-menu.sh" 'Area to clipboard' "screenshot menu has area clipboard action"
require_contains ".config/hypr/scripts/screenshot-menu.sh" 'Area to file' "screenshot menu has area file action"
require_contains ".config/hypr/scripts/screenshot-menu.sh" 'Area annotate' "screenshot menu has annotation action"
require_contains ".config/hypr/scripts/screenshot-menu.sh" 'Fullscreen to clipboard' "screenshot menu has fullscreen clipboard action"
require_contains ".config/hypr/scripts/screenshot-menu.sh" 'Fullscreen to file' "screenshot menu has fullscreen file action"
require_contains ".config/hypr/scripts/screenshot-menu.sh" 'Monitor to file' "screenshot menu has monitor file action"
require_contains ".config/hypr/scripts/screenshot-menu.sh" 'Color picker' "screenshot menu has color picker action"
require_contains ".config/hypr/scripts/screenshot-menu.sh" 'wf-recorder' "screenshot menu supports recording toggle"
require_contains "scripts/pkg_core.lst" '^wf-recorder\|wf-recorder\|recommended\|' "package manifest includes screenshot recorder"
require_contains "scripts/pkg_core.lst" '^vim\|vim\|recommended\|' "package manifest includes vim"
require_contains "scripts/pkg_core.lst" '^code\|code\|recommended\|' "package manifest includes code"
require_contains "scripts/pkg_core.lst" '^spotify\|spotify\|recommended\|' "package manifest includes spotify"
require_contains "scripts/pkg_core.lst" '^spicetify\|spicetify-cli\|recommended\|' "package manifest includes spicetify"
require_contains "scripts/pkg_core.lst" '^sddm\|sddm\|recommended\|' "package manifest includes sddm"
require_contains "scripts/pkg_core.lst" '^magick\|imagemagick\|recommended\|' "package manifest includes imagemagick for SDDM blur"
require_contains ".config/hypr/windowrules.conf" 'match:class \^\(\.\*Code\.\*\)\$, opacity' "window rules add Code transparency"
require_contains ".config/hypr/windowrules.conf" 'match:class \^\(Spotify\)\$, opacity' "window rules add Spotify transparency"
require_contains ".config/hypr/windowrules.conf" 'match:class \^\(kitty\)\$, opacity' "window rules add Kitty transparency"
require_contains ".config/Code/User/settings.json" 'workbench\.colorCustomizations' "Code settings include monochrome color customizations"
require_contains ".config/vim/vimrc" 'colorscheme terminal-noir' "vim uses Terminal Noir colorscheme"
require_contains ".config/spicetify/Themes/TerminalNoir/user.css" 'rgba\(10, 10, 10' "spicetify theme uses translucent monochrome surfaces"
require_contains "sddm/terminal-noir/Main.qml" 'import "Components"' "SDDM theme uses astronaut-style component directory"
require_contains "sddm/terminal-noir/Main.qml" 'MultiEffect' "SDDM theme uses QtQuick blur effect"
require_contains "sddm/terminal-noir/Main.qml" 'config\.Background' "SDDM theme reads background from theme config"
require_contains "sddm/terminal-noir/metadata.desktop" 'ConfigFile=Themes/terminal-noir\.conf' "SDDM metadata points at Terminal Noir config"
require_contains "sddm/terminal-noir/metadata.desktop" 'Theme-Id=terminal-noir' "SDDM metadata declares terminal-noir id"
require_contains "sddm/terminal-noir/Themes/terminal-noir.conf" 'Background="background\.png"' "SDDM theme declares wallpaper background"
require_contains "sddm/terminal-noir/Themes/terminal-noir.conf" 'PartialBlur="true"' "SDDM theme enables partial blur"
require_contains "sddm/terminal-noir/Components/Input.qml" 'import QtQuick\.Controls 2\.15 as QQC2' "SDDM input aliases QtQuick Controls"
require_contains "sddm/terminal-noir/Components/Input.qml" 'QQC2\.Button' "SDDM login button uses QtQuick Controls button"
require_contains "sddm/terminal-noir/Components/SystemButtons.qml" 'QQC2\.Button' "SDDM system buttons use QtQuick Controls button"
require_contains "sddm/terminal-noir/Components/SessionButton.qml" 'QQC2\.ComboBox' "SDDM session selector uses QtQuick Controls combo box"
require_contains "sddm/terminal-noir/Main.qml" 'function suppressVirtualKeyboard' "SDDM theme suppresses automatic virtual keyboard"
require_contains "sddm/terminal-noir/Main.qml" 'Components/VirtualKeyboard\.qml' "SDDM theme loads manual virtual keyboard panel"
require_contains "sddm/terminal-noir/Components/Input.qml" 'root\.suppressVirtualKeyboard' "SDDM input fields suppress automatic keyboard on focus"
require_contains "sddm/terminal-noir/Components/VirtualKeyboard.qml" 'InputPanel' "SDDM virtual keyboard uses Qt input panel"
require_contains "sddm/terminal-noir/Components/VirtualKeyboardButton.qml" 'virtualKeyboard\.switchState' "SDDM virtual keyboard button toggles manual keyboard"
require_contains "sddm/terminal-noir/Themes/terminal-noir.conf" 'HideVirtualKeyboard="false"' "SDDM theme exposes virtual keyboard toggle"
require_contains "scripts/install-sddm-theme.sh" 'terminal-noir\.conf' "SDDM installer writes Terminal Noir theme config"
require_contains "scripts/install-sddm-theme.sh" 'magick|convert' "SDDM installer can generate blurred wallpaper"
require_contains "scripts/install-sddm-theme.sh" '/etc/sddm\.conf' "SDDM installer updates main sddm.conf override"
require_contains "scripts/install-sddm-theme.sh" 'Current=terminal-noir' "SDDM installer selects terminal-noir theme"
require_contains "verify-rice.sh" 'scripts/pkg_core\.lst' "verify-rice reads package manifest"
require_contains "verify-rice.sh" 'xdg-desktop-portal-hyprland' "verify-rice checks hyprland portal"
require_contains "verify-rice.sh" 'hypridle' "verify-rice checks hypridle"

for file in \
    "scripts/sync-config.sh" \
    "scripts/install-sddm-theme.sh" \
    ".config/hypr/scripts/lockscreen.sh" \
    ".config/hypr/scripts/logoutlaunch.sh" \
    ".config/hypr/scripts/volumecontrol.sh" \
    ".config/hypr/scripts/brightnesscontrol.sh" \
    ".config/hypr/scripts/resetxdgportal.sh" \
    ".config/hypr/scripts/keybinds.sh" \
    ".config/hypr/scripts/screenshot-menu.sh" \
    ".config/hypr/scripts/swayosd-launch.sh" \
    "verify-rice.sh"; do
    require_shell_syntax "$file"
done

if [ "$fail_count" -gt 0 ]; then
    printf '\n%d foundation check(s) failed.\n' "$fail_count"
    exit 1
fi

printf '\nFoundation checks passed.\n'
