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
    [ -f "$repo_root/$path" ] && pass "$path exists" || fail "$path is missing"
}

require_executable() {
    local path="$1"
    [ -x "$repo_root/$path" ] && pass "$path is executable" || fail "$path is missing or not executable"
}

require_contains() {
    local path="$1"
    local pattern="$2"
    local label="$3"

    if [ ! -f "$repo_root/$path" ]; then
        fail "$path is missing for $label"
        return
    fi

    if grep -Eq -- "$pattern" "$repo_root/$path"; then
        pass "$label"
    else
        fail "$label"
    fi
}

require_shell_syntax() {
    local path="$1"
    if [ ! -f "$repo_root/$path" ]; then
        fail "$path is missing for shell syntax"
        return
    fi

    if bash -n "$repo_root/$path"; then
        pass "$path shell syntax"
    else
        fail "$path shell syntax"
    fi
}

require_executable ".local/bin/tnctl"
require_file ".config/terminal-noir/config.toml"
require_contains ".config/terminal-noir/config.toml" '^\[terminal_noir\]' "Terminal Noir config has root section"

for helper in \
    "wallpaper" \
    "theme" \
    "waybar" \
    "rofi" \
    "screenshot" \
    "window" \
    "media" \
    "system" \
    "clipboard" \
    "weather" \
    "updates"; do
    require_executable ".local/lib/terminal-noir/${helper}.sh"
    require_shell_syntax ".local/lib/terminal-noir/${helper}.sh"
    require_contains ".local/bin/tnctl" "${helper}" "tnctl exposes ${helper} command group"
done

require_shell_syntax ".local/bin/tnctl"
require_contains ".local/bin/tnctl" 'Usage: tnctl' "tnctl has help output"
require_contains ".local/bin/tnctl" 'TNCTL_LIB_DIR' "tnctl supports library override for tests"
require_contains ".local/bin/tnctl" 'Unknown command group' "tnctl reports unknown command groups"
require_contains ".local/lib/terminal-noir/waybar.sh" 'waybar' "waybar helper controls Waybar"
require_contains ".local/lib/terminal-noir/screenshot.sh" 'screenshot-menu\.sh' "screenshot helper delegates to existing screenshot menu"
require_contains ".local/lib/terminal-noir/clipboard.sh" 'quickshell ipc call clipboard toggle' "clipboard helper opens Quickshell clipboard"
require_contains ".local/lib/terminal-noir/system.sh" 'restart-shell' "system helper exposes shell restart"
require_contains ".config/hypr/keybindings.conf" 'tnctl clipboard open' "clipboard keybind uses tnctl"
require_contains ".config/hypr/keybindings.conf" 'tnctl screenshot menu' "screenshot keybind uses tnctl"

if [ "$fail_count" -gt 0 ]; then
    printf '\n%d control layer check(s) failed.\n' "$fail_count"
    exit 1
fi

printf '\nControl layer checks passed.\n'
