#!/usr/bin/env bash

set -euo pipefail

action="${1:-open}"

usage() {
    cat <<'USAGE'
Usage: tnctl clipboard <open>
USAGE
}

case "$action" in
    open|toggle)
        quickshell ipc call clipboard toggle
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        printf 'Unknown clipboard action: %s\n' "$action" >&2
        usage >&2
        exit 2
        ;;
esac
