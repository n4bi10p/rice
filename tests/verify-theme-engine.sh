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

require_file() {
    local path="$1"
    [ -f "$repo_root/$path" ] && pass "$path exists" || fail "$path is missing"
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

require_file ".local/lib/terminal-noir/common.sh"
require_shell_syntax ".local/lib/terminal-noir/common.sh"
require_executable ".local/lib/terminal-noir/wallpaper.sh"
require_shell_syntax ".local/lib/terminal-noir/wallpaper.sh"
require_executable ".local/lib/terminal-noir/theme.sh"
require_shell_syntax ".local/lib/terminal-noir/theme.sh"

require_contains ".local/lib/terminal-noir/common.sh" 'terminal_noir_state_dir' "common helper exposes state directory"
require_contains ".local/lib/terminal-noir/common.sh" 'expand_path' "common helper expands home-relative paths"
require_contains ".local/lib/terminal-noir/wallpaper.sh" 'TNCTL_SKIP_APPLY' "wallpaper helper supports safe apply skipping"
require_contains ".local/lib/terminal-noir/wallpaper.sh" 'current-wallpaper' "wallpaper helper persists current wallpaper state"
require_contains ".local/lib/terminal-noir/theme.sh" 'wallpaper\.sh' "theme helper delegates wallpaper application"
require_not_contains ".local/lib/terminal-noir/wallpaper.sh" 'not implemented yet' "wallpaper helper has no placeholder actions"
require_not_contains ".local/lib/terminal-noir/theme.sh" 'not implemented yet' "theme helper has no placeholder actions"

if output="$(run_tnctl wallpaper list 2>&1)" && grep -q 'catwall.png' <<<"$output"; then
    pass "wallpaper list finds bundled wallpaper"
else
    printf '%s\n' "$output"
    fail "wallpaper list finds bundled wallpaper"
fi

if output="$(run_tnctl wallpaper current 2>&1)" && grep -q 'catwall.png' <<<"$output"; then
    pass "wallpaper current falls back to config wallpaper"
else
    printf '%s\n' "$output"
    fail "wallpaper current falls back to config wallpaper"
fi

if output="$(run_tnctl wallpaper set "$repo_root/.config/wall/catwall.png" 2>&1)" && grep -q 'catwall.png' <<<"$output"; then
    pass "wallpaper set stores selected wallpaper without live apply"
else
    printf '%s\n' "$output"
    fail "wallpaper set stores selected wallpaper without live apply"
fi

if grep -q 'catwall.png' "$tmp_home/state/terminal-noir/current-wallpaper" 2>/dev/null; then
    pass "wallpaper state file records selected wallpaper"
else
    fail "wallpaper state file records selected wallpaper"
fi

if output="$(run_tnctl wallpaper next 2>&1)" && grep -q 'catwall.png' <<<"$output"; then
    pass "wallpaper next cycles through available wallpapers"
else
    printf '%s\n' "$output"
    fail "wallpaper next cycles through available wallpapers"
fi

if output="$(run_tnctl wallpaper prev 2>&1)" && grep -q 'catwall.png' <<<"$output"; then
    pass "wallpaper prev cycles through available wallpapers"
else
    printf '%s\n' "$output"
    fail "wallpaper prev cycles through available wallpapers"
fi

if output="$(run_tnctl theme status 2>&1)" && grep -q 'catwall.png' <<<"$output"; then
    pass "theme status reports current wallpaper"
else
    printf '%s\n' "$output"
    fail "theme status reports current wallpaper"
fi

if output="$(run_tnctl theme reload 2>&1)" && grep -q 'Theme reload complete' <<<"$output"; then
    pass "theme reload completes in safe mode"
else
    printf '%s\n' "$output"
    fail "theme reload completes in safe mode"
fi

if [ "$fail_count" -gt 0 ]; then
    printf '\n%d theme engine check(s) failed.\n' "$fail_count"
    exit 1
fi

printf '\nTheme engine checks passed.\n'
