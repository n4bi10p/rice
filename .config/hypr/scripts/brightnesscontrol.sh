#!/usr/bin/env bash

set -euo pipefail

action="${1:-}"
step="${2:-5}"

notify_brightness() {
    command -v notify-send >/dev/null 2>&1 || return 0
    local pct
    pct="$(brightnessctl info 2>/dev/null | sed -n 's/.*(\([0-9]\+\)%).*/\1/p' | head -n 1)"
    [ -n "$pct" ] || pct="?"
    notify-send -a "Terminal Noir" -r 7 -t 900 "Brightness" "${pct}%"
}

case "$action" in
    up)
        if command -v swayosd-client >/dev/null 2>&1 && pgrep -x swayosd-server >/dev/null 2>&1; then
            swayosd-client --brightness "+$step"
        else
            brightnessctl set +"$step"%
            notify_brightness
        fi
        ;;
    down)
        if command -v swayosd-client >/dev/null 2>&1 && pgrep -x swayosd-server >/dev/null 2>&1; then
            swayosd-client --brightness "-$step"
        else
            brightnessctl set "$step"%-
            notify_brightness
        fi
        ;;
    get)
        brightnessctl info
        ;;
    *)
        printf 'Usage: %s <up|down|get> [step]\n' "$(basename "$0")" >&2
        exit 2
        ;;
esac
