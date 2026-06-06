#!/usr/bin/env bash

set -euo pipefail

action="${1:-status}"

usage() {
    cat <<'USAGE'
Usage: tnctl weather <status>
USAGE
}

case "$action" in
    status)
        if command -v wttrbar >/dev/null 2>&1; then
            wttrbar
        else
            printf 'wttrbar is not installed.\n' >&2
            exit 1
        fi
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        printf 'Unknown weather action: %s\n' "$action" >&2
        usage >&2
        exit 2
        ;;
esac
