#!/bin/bash

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/ /g'
}

wifi_radio=$(nmcli radio wifi 2>/dev/null || true)
wifi_enabled=false
if [ "$wifi_radio" = "enabled" ]; then
    wifi_enabled=true
fi

wifi_ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1 == "yes" { print $2; exit }' || true)
if [ -z "$wifi_ssid" ]; then
    wifi_ssid="Disconnected"
fi

bt_soft=$(rfkill -n -o SOFT list bluetooth 2>/dev/null | head -n 1 | tr -d '[:space:]' || true)
bt_enabled=false
if [ "$bt_soft" = "unblocked" ]; then
    bt_enabled=true
fi

brightness_current=$(brightnessctl get 2>/dev/null || echo 0)
brightness_max=$(brightnessctl max 2>/dev/null || echo 100)
if [ -z "$brightness_max" ] || [ "$brightness_max" -le 0 ] 2>/dev/null; then
    brightness_max=100
fi

brightness_percent=$((brightness_current * 100 / brightness_max))
if [ "$brightness_percent" -lt 0 ] 2>/dev/null; then
    brightness_percent=0
elif [ "$brightness_percent" -gt 100 ] 2>/dev/null; then
    brightness_percent=100
fi

audio_status=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)
audio_volume=$(printf '%s\n' "$audio_status" | awk '{print int(($2 * 100) + 0.5)}')
audio_muted=false
if printf '%s\n' "$audio_status" | grep -q MUTED; then
    audio_muted=true
fi
if [ -z "$audio_volume" ]; then
    audio_volume=0
elif [ "$audio_volume" -lt 0 ] 2>/dev/null; then
    audio_volume=0
elif [ "$audio_volume" -gt 150 ] 2>/dev/null; then
    audio_volume=150
fi

airplane_mode=false
if [ "$wifi_enabled" = false ] && [ "$bt_enabled" = false ]; then
    airplane_mode=true
fi

printf '{"wifiEnabled":%s,"wifiSsid":"%s","btEnabled":%s,"brightness":%s,"airplaneMode":%s,"audioVolume":%s,"audioMuted":%s}\n' \
    "$wifi_enabled" \
    "$(json_escape "$wifi_ssid")" \
    "$bt_enabled" \
    "$brightness_percent" \
    "$airplane_mode" \
    "$audio_volume" \
    "$audio_muted"
