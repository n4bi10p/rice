#!/usr/bin/env bash

set -euo pipefail

action="${1:-help}"

usage() {
    cat <<'USAGE'
Usage: tnctl waybar <reload|toggle>
USAGE
}

case "$action" in
    reload)
        pkill -x waybar >/dev/null 2>&1 || true
        waybar >/dev/null 2>&1 &
        ;;
    toggle)
        if pgrep -x waybar >/dev/null 2>&1; then
            pkill -x waybar
        else
            waybar >/dev/null 2>&1 &
        fi
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        printf 'Unknown waybar action: %s\n' "$action" >&2
        usage >&2
        exit 2
        ;;
esac
