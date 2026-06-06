#!/usr/bin/env bash

set -euo pipefail

network_enabled="${1:-true}"
audio_enabled="${2:-true}"
bluetooth_enabled="${3:-true}"
notifications_enabled="${4:-true}"
config_path="${5:-${XDG_CONFIG_HOME:-$HOME/.config}/waybar/config.jsonc}"

is_true() {
    case "${1,,}" in
        1|true|yes|on) return 0 ;;
        *) return 1 ;;
    esac
}

modules=("cpu" "memory" "battery")
optional=()

is_true "$network_enabled" && optional+=("network")
is_true "$audio_enabled" && optional+=("pulseaudio")
is_true "$bluetooth_enabled" && optional+=("bluetooth")
is_true "$notifications_enabled" && optional+=("custom/notification")

if [ "${#optional[@]}" -gt 0 ]; then
    modules+=("custom/separator")
    modules+=("${optional[@]}")
fi

[ -f "$config_path" ] || {
    printf 'Waybar config not found: %s\n' "$config_path" >&2
    exit 1
}

modules_json="$(printf '%s\n' "${modules[@]}" | jq -R . | jq -s .)"
tmp_file="$(mktemp "${config_path}.XXXXXX")"

jq --argjson modules "$modules_json" '."modules-right" = $modules' "$config_path" >"$tmp_file"
mv "$tmp_file" "$config_path"

if [ "${TN_SKIP_WAYBAR_RESTART:-0}" != "1" ]; then
    pkill -x waybar >/dev/null 2>&1 || true
    waybar >/tmp/terminal-noir-waybar.log 2>&1 &
fi
