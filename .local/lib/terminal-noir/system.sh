#!/usr/bin/env bash

set -euo pipefail

action="${1:-help}"

usage() {
    cat <<'USAGE'
Usage: tnctl system <restart-shell|restart-waybar|restart-osd|monitor|status>
USAGE
}

case "$action" in
    restart-shell)
        pkill -x quickshell >/dev/null 2>&1 || true
        quickshell --daemonize -p "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/shell.qml"
        ;;
    restart-waybar)
        "$HOME/.local/bin/tnctl" waybar reload
        ;;
    restart-osd)
        pkill -x swayosd-server >/dev/null 2>&1 || true
        "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/swayosd-launch.sh"
        ;;
    monitor)
        if command -v btop >/dev/null 2>&1; then
            kitty -e btop
        elif command -v htop >/dev/null 2>&1; then
            kitty -e htop
        else
            kitty -e top
        fi
        ;;
    status)
        printf 'waybar: %s\n' "$(pgrep -x waybar >/dev/null 2>&1 && printf running || printf stopped)"
        printf 'quickshell: %s\n' "$(pgrep -x quickshell >/dev/null 2>&1 && printf running || printf stopped)"
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        printf 'Unknown system action: %s\n' "$action" >&2
        usage >&2
        exit 2
        ;;
esac
