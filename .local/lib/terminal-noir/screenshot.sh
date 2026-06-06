#!/usr/bin/env bash

set -euo pipefail

action="${1:-help}"
script="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/screenshot-menu.sh"

usage() {
    cat <<'USAGE'
Usage: tnctl screenshot <menu>
USAGE
}

case "$action" in
    menu)
        exec "$script"
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        printf 'Unknown screenshot action: %s\n' "$action" >&2
        usage >&2
        exit 2
        ;;
esac
