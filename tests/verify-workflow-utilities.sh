#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_home="$(mktemp -d)"
fail_count=0

cleanup() {
    rm -rf "$tmp_home"
}
trap cleanup EXIT

fail() {
    printf 'FAIL: %s\n' "$1"
    fail_count=$((fail_count + 1))
}

pass() {
    printf 'PASS: %s\n' "$1"
}

require_executable() {
    local path="$1"
    [ -x "$repo_root/$path" ] && pass "$path executable" || fail "$path is missing or not executable"
}

require_shell_syntax() {
    local path="$1"
    if [ ! -f "$repo_root/$path" ]; then
        fail "$path missing for shell syntax"
        return
    fi

    if bash -n "$repo_root/$path"; then
        pass "$path shell syntax"
    else
        fail "$path shell syntax"
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

    if grep -Eq -- "$pattern" "$repo_root/$path"; then
        pass "$label"
    else
        fail "$label"
    fi
}

require_not_contains() {
    local path="$1"
    local pattern="$2"
    local label="$3"

    if [ ! -f "$repo_root/$path" ]; then
        fail "$path is missing for $label"
        return
    fi

    if grep -Eq -- "$pattern" "$repo_root/$path"; then
        fail "$label"
    else
        pass "$label"
    fi
}

run_tnctl() {
    HOME="$tmp_home" \
    XDG_CONFIG_HOME="$repo_root/.config" \
    XDG_STATE_HOME="$tmp_home/state" \
    TNCTL_LIB_DIR="$repo_root/.local/lib/terminal-noir" \
    TNCTL_SKIP_APPLY=1 \
    "$repo_root/.local/bin/tnctl" "$@"
}

mkdir -p "$tmp_home/Documents"
printf 'terminal noir test file\n' > "$tmp_home/Documents/noir-note.txt"

require_executable ".local/lib/terminal-noir/rofi.sh"
require_shell_syntax ".local/lib/terminal-noir/rofi.sh"
require_executable ".local/lib/terminal-noir/window.sh"
require_shell_syntax ".local/lib/terminal-noir/window.sh"

require_not_contains ".local/lib/terminal-noir/rofi.sh" 'planned for|not implemented yet' "rofi helper has no placeholder actions"
require_not_contains ".local/lib/terminal-noir/window.sh" 'planned for|not implemented yet' "window helper has no placeholder actions"
require_contains ".local/lib/terminal-noir/rofi.sh" 'xdg-open' "rofi helper can open files or web targets"
require_contains ".local/lib/terminal-noir/rofi.sh" 'wl-copy' "rofi helper can copy emoji and glyph selections"
require_contains ".local/lib/terminal-noir/window.sh" 'hyprctl activewindow -j' "window mute inspects active Hyprland window"
require_contains ".local/lib/terminal-noir/window.sh" 'application\.process\.id' "window mute maps audio streams by process id"
require_contains ".local/lib/terminal-noir/window.sh" 'pactl set-sink-input-mute' "window mute toggles matched sink inputs"

if output="$(run_tnctl rofi files 2>&1)" && grep -q 'noir-note.txt' <<<"$output"; then
    pass "rofi files lists home files in safe mode"
else
    printf '%s\n' "$output"
    fail "rofi files lists home files in safe mode"
fi

if output="$(run_tnctl rofi web 'terminal noir rice' 2>&1)" && grep -q 'https://www.google.com/search?q=terminal%20noir%20rice' <<<"$output"; then
    pass "rofi web builds escaped search URL in safe mode"
else
    printf '%s\n' "$output"
    fail "rofi web builds escaped search URL in safe mode"
fi

if output="$(run_tnctl rofi emoji 2>&1)" && grep -q 'Copied emoji' <<<"$output"; then
    pass "rofi emoji has safe copy path"
else
    printf '%s\n' "$output"
    fail "rofi emoji has safe copy path"
fi

if output="$(run_tnctl rofi glyph 2>&1)" && grep -q 'Copied glyph' <<<"$output"; then
    pass "rofi glyph has safe copy path"
else
    printf '%s\n' "$output"
    fail "rofi glyph has safe copy path"
fi

if output="$(run_tnctl window mute 2>&1)" && grep -q 'Active-window mute' <<<"$output"; then
    pass "window mute has safe inspection path"
else
    printf '%s\n' "$output"
    fail "window mute has safe inspection path"
fi

if [ "$fail_count" -gt 0 ]; then
    printf '\n%d workflow utility check(s) failed.\n' "$fail_count"
    exit 1
fi

printf '\nWorkflow utility checks passed.\n'
