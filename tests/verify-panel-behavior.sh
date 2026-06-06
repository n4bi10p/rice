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
        fail "$path missing"
    fi
}

require_executable() {
    local path="$1"
    if [ -x "$repo_root/$path" ]; then
        pass "$path executable"
    else
        fail "$path missing or not executable"
    fi
}

require_shell_syntax() {
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

require_contains() {
    local path="$1"
    local pattern="$2"
    local label="$3"

    if [ ! -f "$repo_root/$path" ]; then
        fail "$path missing for $label"
        return
    fi

    if grep -Eq "$pattern" "$repo_root/$path"; then
        pass "$label"
    else
        fail "$label"
    fi
}

require_file ".config/quickshell/SettingsPanel.qml"
require_file ".config/quickshell/ControlCenter.qml"
require_file ".config/quickshell/NotificationPopups.qml"
require_executable ".config/quickshell/apply_waybar_modules.sh"
require_executable ".config/quickshell/focus_notification_source.sh"
require_shell_syntax ".config/quickshell/apply_waybar_modules.sh"
require_shell_syntax ".config/quickshell/focus_notification_source.sh"

require_contains ".config/quickshell/SettingsPanel.qml" 'function applyWaybarModules\(' "settings panel can apply Waybar module toggles"
require_contains ".config/quickshell/SettingsPanel.qml" 'apply_waybar_modules\.sh' "settings panel calls Waybar module helper"
require_contains ".config/quickshell/SettingsPanel.qml" 'barNotificationsEnabled' "settings panel exposes notification bar toggle"
require_contains ".config/quickshell/SettingsPanel.qml" 'restartShell' "settings panel exposes shell restart action"
require_contains ".config/quickshell/SettingsPanel.qml" 'restartOsd' "settings panel exposes OSD restart action"
require_contains ".config/quickshell/SettingsPanel.qml" 'testNotification' "settings panel exposes notification test action"
require_contains ".config/quickshell/SettingsPanel.qml" 'hypridle\.service' "settings panel controls hypridle service"
require_contains ".config/quickshell/SettingsPanel.qml" 'hyprsunset\.service' "settings panel controls hyprsunset service"

require_contains ".config/quickshell/ControlCenter.qml" 'function dismissAllNotifications\(' "control center dismisses all notifications via backing objects"
require_contains ".config/quickshell/ControlCenter.qml" 'focus_notification_source\.sh' "control center uses notification focus helper"
require_contains ".config/quickshell/ControlCenter.qml" 'desktopEntry.*appName.*title|title.*appName.*desktopEntry' "control center passes notification source fields to focus helper"
require_contains ".config/quickshell/ControlCenter.qml" 'dismissAllNotifications\(\)' "clear notifications button uses dismiss-all helper"
require_contains ".config/quickshell/NotificationPopups.qml" 'root.openNotification\(toast\.modelData\.id\)' "notification popup click opens source notification"

if [ "$fail_count" -gt 0 ]; then
    printf '\n%d panel behavior check(s) failed.\n' "$fail_count"
    exit 1
fi

printf '\nPanel behavior checks passed.\n'
