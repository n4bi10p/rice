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
require_executable ".config/hypr/scripts/lockscreen.sh"
require_executable ".config/hypr/scripts/logoutlaunch.sh"
require_executable ".config/hypr/scripts/volumecontrol.sh"
require_executable ".config/hypr/scripts/brightnesscontrol.sh"
require_executable ".config/hypr/scripts/resetxdgportal.sh"
require_executable ".config/hypr/scripts/keybinds.sh"
require_executable ".config/hypr/scripts/swayosd-launch.sh"

for file in \
    ".config/hypr/env.conf" \
    ".config/hypr/startup.conf" \
    ".config/hypr/keybindings.conf" \
    ".config/hypr/windowrules.conf" \
    ".config/hypr/monitors.conf" \
    ".config/hypr/userprefs.conf" \
    ".config/hypr/hypridle.conf" \
    ".config/swayosd/config.toml" \
    ".config/swayosd/style.css"; do
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
require_contains ".config/hypr/keybindings.conf" 'volumecontrol\.sh' "keybindings use volume wrapper"
require_contains ".config/hypr/keybindings.conf" 'brightnesscontrol\.sh' "keybindings use brightness wrapper"
require_contains "verify-rice.sh" 'scripts/pkg_core\.lst' "verify-rice reads package manifest"
require_contains "verify-rice.sh" 'xdg-desktop-portal-hyprland' "verify-rice checks hyprland portal"
require_contains "verify-rice.sh" 'hypridle' "verify-rice checks hypridle"

for file in \
    "scripts/sync-config.sh" \
    ".config/hypr/scripts/lockscreen.sh" \
    ".config/hypr/scripts/logoutlaunch.sh" \
    ".config/hypr/scripts/volumecontrol.sh" \
    ".config/hypr/scripts/brightnesscontrol.sh" \
    ".config/hypr/scripts/resetxdgportal.sh" \
    ".config/hypr/scripts/keybinds.sh" \
    ".config/hypr/scripts/swayosd-launch.sh" \
    "verify-rice.sh"; do
    require_shell_syntax "$file"
done

if [ "$fail_count" -gt 0 ]; then
    printf '\n%d foundation check(s) failed.\n' "$fail_count"
    exit 1
fi

printf '\nFoundation checks passed.\n'
