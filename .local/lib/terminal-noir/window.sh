#!/usr/bin/env bash

set -euo pipefail

action="${1:-help}"

usage() {
    cat <<'USAGE'
Usage: tnctl window <pin|mute>
USAGE
}

case "$action" in
    pin)
        hyprctl dispatch pin active
        ;;
    mute)
        command -v notify-send >/dev/null 2>&1 && notify-send "Terminal Noir" "Active-window mute is planned for the workflow phase" || true
        printf 'Active-window mute is not implemented yet.\n' >&2
        exit 1
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        printf 'Unknown window action: %s\n' "$action" >&2
        usage >&2
        exit 2
        ;;
esac
