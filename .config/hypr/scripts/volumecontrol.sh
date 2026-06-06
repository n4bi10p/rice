#!/usr/bin/env bash

set -euo pipefail

device="${1:-output}"
action="${2:-}"
step="${3:-5}"

notify_volume() {
    local title="$1"
    local body="$2"
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send -a "Terminal Noir" -r 8 -t 900 "$title" "$body"
}

target="@DEFAULT_AUDIO_SINK@"
[ "$device" = "input" ] && target="@DEFAULT_AUDIO_SOURCE@"
osd_volume_arg="--output-volume"
[ "$device" = "input" ] && osd_volume_arg="--input-volume"

case "$action" in
    up)
        if command -v swayosd-client >/dev/null 2>&1 && pgrep -x swayosd-server >/dev/null 2>&1; then
            swayosd-client "$osd_volume_arg" "+$step"
        else
            wpctl set-volume -l 1.0 "$target" "$step%+"
            notify_volume "Volume" "$(wpctl get-volume "$target" 2>/dev/null || true)"
        fi
        ;;
    down)
        if command -v swayosd-client >/dev/null 2>&1 && pgrep -x swayosd-server >/dev/null 2>&1; then
            swayosd-client "$osd_volume_arg" "-$step"
        else
            wpctl set-volume -l 1.0 "$target" "$step%-"
            notify_volume "Volume" "$(wpctl get-volume "$target" 2>/dev/null || true)"
        fi
        ;;
    mute)
        if command -v swayosd-client >/dev/null 2>&1 && pgrep -x swayosd-server >/dev/null 2>&1; then
            swayosd-client "$osd_volume_arg" mute-toggle
        else
            wpctl set-mute "$target" toggle
            notify_volume "Volume" "$(wpctl get-volume "$target" 2>/dev/null || true)"
        fi
        ;;
    get)
        wpctl get-volume "$target"
        ;;
    *)
        printf 'Usage: %s <output|input> <up|down|mute|get> [step]\n' "$(basename "$0")" >&2
        exit 2
        ;;
esac
