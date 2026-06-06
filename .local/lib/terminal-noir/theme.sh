#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$script_dir/common.sh"

action="${1:-help}"

usage() {
    cat <<'USAGE'
Usage: tnctl theme <apply|reload|status>
USAGE
}

reload_theme() {
    "$script_dir/wallpaper.sh" apply

    if [ "${TNCTL_SKIP_APPLY:-0}" != "1" ]; then
        command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1 || true
        "$script_dir/waybar.sh" reload >/dev/null 2>&1 || true
    fi

    terminal_noir_notify "Theme reload complete"
    printf 'Theme reload complete\n'
}

case "$action" in
    apply|reload)
        reload_theme
        ;;
    status)
        printf 'theme: %s\n' "$(terminal_noir_config_value theme 2>/dev/null || printf 'terminal-noir')"
        printf 'wallpaper: %s\n' "$(terminal_noir_current_wallpaper)"
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        printf 'Unknown theme action: %s\n' "$action" >&2
        usage >&2
        exit 2
        ;;
esac
