#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$script_dir/common.sh"

action="${1:-help}"

usage() {
    cat <<'USAGE'
Usage: tnctl window <pin|mute>
USAGE
}

case "$action" in
    pin)
        if [ "${TNCTL_SKIP_APPLY:-0}" = "1" ]; then
            printf 'Would pin active window\n'
        else
            hyprctl dispatch pin active
        fi
        ;;
    mute)
        if [ "${TNCTL_SKIP_APPLY:-0}" = "1" ]; then
            printf 'Active-window mute would inspect active Hyprland window audio streams\n'
            exit 0
        fi

        command -v hyprctl >/dev/null 2>&1 || {
            printf 'hyprctl is required for active-window mute.\n' >&2
            exit 1
        }
        command -v jq >/dev/null 2>&1 || {
            printf 'jq is required for active-window mute.\n' >&2
            exit 1
        }
        command -v pactl >/dev/null 2>&1 || {
            printf 'pactl is required for active-window mute.\n' >&2
            exit 1
        }

        pid="$(hyprctl activewindow -j | jq -r '.pid // empty')"
        [ -n "$pid" ] || {
            printf 'No active Hyprland window PID found.\n' >&2
            exit 1
        }

        mapfile -t sink_inputs < <(
            pactl list sink-inputs | awk -v pid="$pid" '
                /^Sink Input #[0-9]+/ {
                    id = $3
                    sub(/^#/, "", id)
                }
                /application.process.id =/ {
                    value = $3
                    gsub(/"/, "", value)
                    if (value == pid && id != "") {
                        print id
                    }
                }
            '
        )

        [ "${#sink_inputs[@]}" -gt 0 ] || {
            printf 'No audio streams found for active window PID %s.\n' "$pid" >&2
            exit 1
        }

        for input_id in "${sink_inputs[@]}"; do
            pactl set-sink-input-mute "$input_id" toggle
        done
        terminal_noir_notify "Toggled active-window audio"
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        printf 'Unknown window action: %s\n' "$action" >&2
        usage >&2
        exit 2
        ;;
esac
