#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
manifest="$repo_root/scripts/pkg_core.lst"
fail_count=0
warn_count=0

info() {
    printf '%s\n' "$1"
}

pass() {
    printf '[PASS] %s\n' "$1"
}

warn() {
    printf '[WARN] %s\n' "$1"
    warn_count=$((warn_count + 1))
}

fail() {
    printf '[FAIL] %s\n' "$1"
    fail_count=$((fail_count + 1))
}

check_command() {
    local command_name="$1"
    local package_name="$2"
    local level="$3"
    local description="$4"

    if [[ "$command_name" == */* ]]; then
        if [ -e "$command_name" ]; then
            pass "$command_name found"
            return
        fi
    elif command -v "$command_name" >/dev/null 2>&1; then
        pass "$command_name found ($(command -v "$command_name"))"
        return
    fi

    if [ "$level" = "required" ]; then
        fail "$command_name missing; install package: $package_name ($description)"
    else
        warn "$command_name missing; recommended package: $package_name ($description)"
    fi
}

check_manifest() {
    if [ ! -f "$manifest" ]; then
        fail "Package manifest missing: scripts/pkg_core.lst"
        return
    fi

    pass "Package manifest found: scripts/pkg_core.lst"

    while IFS='|' read -r command_name package_name level description || [ -n "${command_name:-}" ]; do
        case "${command_name:-}" in
            ""|\#*) continue ;;
        esac

        [ -n "${package_name:-}" ] || package_name="$command_name"
        [ -n "${level:-}" ] || level="required"
        [ -n "${description:-}" ] || description="$command_name"

        check_command "$command_name" "$package_name" "$level" "$description"
    done < "$manifest"
}

check_font() {
    if command -v fc-list >/dev/null 2>&1 && fc-list | grep -qi "JetBrains.*Nerd"; then
        pass "JetBrains Nerd font detected"
    else
        warn "JetBrains Nerd font not detected; run ./install_fonts.sh"
    fi
}

check_file() {
    local path="$1"
    [ -f "$repo_root/$path" ] && pass "$path exists" || fail "$path missing"
}

check_executable() {
    local path="$1"
    [ -x "$repo_root/$path" ] && pass "$path executable" || fail "$path missing or not executable"
}

check_shell_syntax() {
    local path="$1"
    if [ ! -f "$repo_root/$path" ]; then
        fail "$path missing for syntax check"
        return
    fi

    if bash -n "$repo_root/$path"; then
        pass "$path shell syntax"
    else
        fail "$path shell syntax"
    fi
}

check_hyprland_config() {
    local config="$repo_root/.config/hypr/hyprland.conf"

    check_file ".config/hypr/hyprland.conf"
    for include in env monitors userprefs windowrules keybindings startup; do
        check_file ".config/hypr/${include}.conf"
        if grep -Eq "^source = .*/${include}\.conf$" "$config"; then
            pass "hyprland.conf sources ${include}.conf"
        else
            fail "hyprland.conf does not source ${include}.conf"
        fi
    done
}

check_helpers() {
    for script in \
        "scripts/install.sh" \
        "scripts/backup-config.sh" \
        "scripts/restore-config.sh" \
        "scripts/uninstall.sh" \
        "scripts/sync-config.sh" \
        "scripts/install-sddm-theme.sh" \
        ".local/bin/terminal-noir-zen-theme" \
        ".config/quickshell/control_state.sh" \
        ".config/quickshell/wifi_state.sh" \
        ".config/quickshell/bluetooth_state.sh" \
        ".config/quickshell/apply_waybar_modules.sh" \
        ".config/quickshell/focus_notification_source.sh" \
        ".config/quickshell/hw_stats.sh" \
        ".config/quickshell/sw_stats.sh" \
        ".local/bin/tnctl" \
        ".local/lib/terminal-noir/common.sh" \
        ".local/lib/terminal-noir/wallpaper.sh" \
        ".local/lib/terminal-noir/theme.sh" \
        ".local/lib/terminal-noir/waybar.sh" \
        ".local/lib/terminal-noir/rofi.sh" \
        ".local/lib/terminal-noir/screenshot.sh" \
        ".local/lib/terminal-noir/window.sh" \
        ".local/lib/terminal-noir/media.sh" \
        ".local/lib/terminal-noir/system.sh" \
        ".local/lib/terminal-noir/clipboard.sh" \
        ".local/lib/terminal-noir/weather.sh" \
        ".local/lib/terminal-noir/updates.sh" \
        ".config/rofi/clipboard-menu.sh" \
        ".config/hypr/scripts/lockscreen.sh" \
        ".config/hypr/scripts/logoutlaunch.sh" \
        ".config/hypr/scripts/volumecontrol.sh" \
        ".config/hypr/scripts/brightnesscontrol.sh" \
        ".config/hypr/scripts/resetxdgportal.sh" \
        ".config/hypr/scripts/keybinds.sh" \
        ".config/hypr/scripts/screenshot-menu.sh" \
        ".config/hypr/scripts/swayosd-launch.sh"; do
        check_executable "$script"
        check_shell_syntax "$script"
    done

    check_file ".config/hypr/hypridle.conf"
    check_file ".config/swayosd/config.toml"
    check_file ".config/swayosd/style.css"
}

check_theme_configs() {
    for path in \
        ".gtkrc-2.0" \
        ".config/gtk-3.0/settings.ini" \
        ".config/gtk-3.0/gtk.css" \
        ".config/gtk-4.0/settings.ini" \
        ".config/gtk-4.0/gtk.css" \
        ".config/xsettingsd/xsettingsd.conf" \
        ".config/Trolltech.conf" \
        ".config/qt5ct/qt5ct.conf" \
        ".config/qt5ct/colors/terminal-noir.conf" \
        ".config/qt5ct/qss/terminal-noir.qss" \
        ".config/qt6ct/qt6ct.conf" \
        ".config/qt6ct/colors/terminal-noir.conf" \
        ".config/qt6ct/qss/terminal-noir.qss" \
        ".config/Kvantum/kvantum.kvconfig" \
        ".config/Kvantum/TerminalNoir/TerminalNoir.kvconfig" \
        ".config/Kvantum/TerminalNoir/TerminalNoir.svg" \
        ".local/share/color-schemes/TerminalNoir.colors" \
        ".config/kdeglobals" \
        ".config/dolphinrc"; do
        check_file "$path"
    done
}

check_live_session() {
    if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
        pass "Hyprland socket reachable"
    else
        warn "Hyprland socket not reachable; live reload checks skipped"
    fi

    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet NetworkManager.service 2>/dev/null; then
            pass "NetworkManager service active"
        else
            warn "NetworkManager service not active or not visible"
        fi

        if systemctl is-active --quiet bluetooth.service 2>/dev/null; then
            pass "Bluetooth service active"
        else
            warn "Bluetooth service not active or not visible"
        fi
    fi

    if pgrep -f '(^|/)xdg-desktop-portal-hyprland($| )' >/dev/null 2>&1; then
        pass "xdg-desktop-portal-hyprland is running"
    else
        warn "xdg-desktop-portal-hyprland is not running"
    fi

    if pgrep -x hypridle >/dev/null 2>&1; then
        pass "hypridle is running"
    else
        warn "hypridle is not running"
    fi
}

info "=========================================="
info "Terminal Noir rice verification"
info "=========================================="

check_manifest
check_font
check_hyprland_config
check_helpers
check_theme_configs
check_live_session

info "=========================================="
if [ "$fail_count" -eq 0 ]; then
    info "Verification passed with $warn_count warning(s)."
else
    info "Verification failed with $fail_count failure(s) and $warn_count warning(s)."
fi
info "=========================================="

[ "$fail_count" -eq 0 ]
