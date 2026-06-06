#!/usr/bin/env bash

set -euo pipefail

action="${1:-help}"

usage() {
    cat <<'USAGE'
Usage: tnctl media <play-pause|next|prev|status>
USAGE
}

case "$action" in
    play-pause)
        playerctl play-pause
        ;;
    next)
        playerctl next
        ;;
    prev|previous)
        playerctl previous
        ;;
    status)
        playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || true
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        printf 'Unknown media action: %s\n' "$action" >&2
        usage >&2
        exit 2
        ;;
esac
