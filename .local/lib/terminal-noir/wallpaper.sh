#!/usr/bin/env bash

set -euo pipefail

action="${1:-help}"
shift || true

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send "Terminal Noir" "$1" || true
}

usage() {
    cat <<'USAGE'
Usage: tnctl wallpaper <select|next|prev|apply> [path]
USAGE
}

case "$action" in
    apply)
        wallpaper="${1:-}"
        [ -n "$wallpaper" ] || {
            printf 'Usage: tnctl wallpaper apply <path>\n' >&2
            exit 2
        }
        [ -f "$wallpaper" ] || {
            printf 'Wallpaper not found: %s\n' "$wallpaper" >&2
            exit 1
        }
        pkill -x swaybg >/dev/null 2>&1 || true
        swaybg -i "$wallpaper" -m fill >/dev/null 2>&1 &
        notify "Wallpaper applied"
        ;;
    select|next|prev)
        notify "Wallpaper ${action} is planned for the theme engine phase"
        printf 'Wallpaper %s is not implemented yet.\n' "$action" >&2
        exit 1
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        printf 'Unknown wallpaper action: %s\n' "$action" >&2
        usage >&2
        exit 2
        ;;
esac
