#!/usr/bin/env bash

set -euo pipefail

action="${1:-count}"

usage() {
    cat <<'USAGE'
Usage: tnctl updates <count|list>
USAGE
}

case "$action" in
    count)
        if command -v checkupdates >/dev/null 2>&1; then
            checkupdates 2>/dev/null | wc -l
        else
            printf '0\n'
        fi
        ;;
    list)
        command -v checkupdates >/dev/null 2>&1 && checkupdates || true
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        printf 'Unknown updates action: %s\n' "$action" >&2
        usage >&2
        exit 2
        ;;
esac
