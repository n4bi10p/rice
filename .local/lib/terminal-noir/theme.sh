#!/usr/bin/env bash

set -euo pipefail

action="${1:-help}"

usage() {
    cat <<'USAGE'
Usage: tnctl theme <apply|reload>
USAGE
}

case "$action" in
    apply|reload)
        command -v notify-send >/dev/null 2>&1 && notify-send "Terminal Noir" "Theme ${action} is planned for the theme engine phase" || true
        printf 'Theme %s is not implemented yet.\n' "$action" >&2
        exit 1
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
