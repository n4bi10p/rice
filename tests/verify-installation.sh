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

require_file ".gitignore"
require_contains ".gitignore" '^sddm-astronaut-theme/$' "reference SDDM clone is ignored"

for script in \
    "scripts/install.sh" \
    "scripts/backup-config.sh" \
    "scripts/restore-config.sh" \
    "scripts/uninstall.sh"; do
    require_executable "$script"
    require_shell_syntax "$script"
done

require_contains "scripts/install.sh" 'scripts/pkg_core\.lst' "installer reads package manifest"
require_contains "scripts/install.sh" 'yay' "installer uses yay"
require_contains "scripts/install.sh" '--required-only' "installer supports required-only package mode"
require_contains "scripts/install.sh" '--all' "installer supports full package mode"
require_contains "scripts/install.sh" '--no-packages' "installer can skip package installation"
require_contains "scripts/install.sh" '--sync-config' "installer can sync user config"
require_contains "scripts/install.sh" '--install-sddm' "installer can install SDDM theme"
require_contains "scripts/install.sh" '--dry-run' "installer supports dry-run"

require_contains "scripts/backup-config.sh" 'terminal-noir/backups' "backup stores state under terminal-noir backups"
require_contains "scripts/backup-config.sh" '\.config/hypr' "backup includes Hyprland config"
require_contains "scripts/backup-config.sh" '\.config/quickshell' "backup includes Quickshell config"
require_contains "scripts/backup-config.sh" '\.config/waybar' "backup includes Waybar config"
require_contains "scripts/restore-config.sh" 'latest' "restore supports latest backup"
require_contains "scripts/restore-config.sh" 'terminal-noir/backups' "restore reads terminal-noir backups"
require_not_contains "scripts/uninstall.sh" 'yay[[:space:]]+-R|pacman[[:space:]]+-R' "uninstaller never removes packages"

for package in \
    "nwg-look" \
    "qt5ct" \
    "qt6ct" \
    "kvantum" \
    "kvantum-qt5" \
    "qt5-wayland" \
    "qt6-wayland" \
    "xdg-user-dirs" \
    "xdg-desktop-portal-gtk" \
    "wl-clip-persist" \
    "starship" \
    "zsh" \
    "fzf" \
    "bat" \
    "eza" \
    "duf" \
    "pacman-contrib" \
    "wttrbar" \
    "ddcui" \
    "nwg-displays"; do
    require_contains "scripts/pkg_core.lst" "\\|${package}\\|" "package manifest includes ${package}"
done

require_contains "scripts/pkg_core.lst" '^/usr/lib/qt6/plugins/platforms/libqwayland\.so\|qt6-wayland\|recommended\|' "package manifest checks current Qt6 Wayland plugin path"

require_contains "verify-rice.sh" 'scripts/install\.sh' "verify-rice checks installer"
require_contains "verify-rice.sh" 'scripts/backup-config\.sh' "verify-rice checks backup script"
require_contains "verify-rice.sh" 'scripts/restore-config\.sh' "verify-rice checks restore script"
require_contains "verify-rice.sh" 'scripts/uninstall\.sh' "verify-rice checks uninstall script"

if [ "$fail_count" -gt 0 ]; then
    printf '\n%d installation check(s) failed.\n' "$fail_count"
    exit 1
fi

printf '\nInstallation checks passed.\n'
