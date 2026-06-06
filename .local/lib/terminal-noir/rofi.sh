#!/usr/bin/env bash

set -euo pipefail

action="${1:-help}"
theme="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/terminal-noir.rasi"

usage() {
    cat <<'USAGE'
Usage: tnctl rofi <apps|windows|files|web|emoji|glyph>
USAGE
}

run_rofi() {
    rofi "$@" -theme "$theme"
}

case "$action" in
    apps)
        run_rofi -show drun
        ;;
    windows)
        run_rofi -show window
        ;;
    files|web|emoji|glyph)
        printf 'Rofi %s menu is planned for the utility menu phase.\n' "$action" >&2
        exit 1
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        printf 'Unknown rofi action: %s\n' "$action" >&2
        usage >&2
        exit 2
        ;;
esac
