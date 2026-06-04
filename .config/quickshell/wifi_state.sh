#!/usr/bin/env sh

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g'
}

wifi_radio=$(nmcli radio wifi 2>/dev/null || true)
enabled=false
if [ "$wifi_radio" = "enabled" ]; then
    enabled=true
fi

connected=$(nmcli -t -e no -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1 == "yes" { print $2; exit }' || true)
saved_connections=$(nmcli -t -e no -f NAME,TYPE connection show 2>/dev/null || true)

printf '{"enabled":%s,"connectedSsid":"%s","networks":[' "$enabled" "$(json_escape "$connected")"

first=true
nmcli -t -e no -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan yes 2>/dev/null |
while IFS=: read -r in_use ssid signal security rest; do
    [ -n "$ssid" ] || continue
    [ "$ssid" != "--" ] || continue

    saved=false
    if printf '%s\n' "$saved_connections" | awk -F: -v ssid="$ssid" '$1 == ssid && $2 == "802-11-wireless" { found = 1 } END { exit found ? 0 : 1 }'; then
        saved=true
    fi

    secured=true
    if [ -z "$security" ] || [ "$security" = "--" ]; then
        secured=false
    fi

    connected_item=false
    if [ "$in_use" = "*" ] || [ "$ssid" = "$connected" ]; then
        connected_item=true
    fi

    if [ "$first" = true ]; then
        first=false
    else
        printf ','
    fi

    printf '{"ssid":"%s","signal":%s,"security":"%s","secured":%s,"saved":%s,"connected":%s}' \
        "$(json_escape "$ssid")" \
        "${signal:-0}" \
        "$(json_escape "$security")" \
        "$secured" \
        "$saved" \
        "$connected_item"
done

printf ']}\n'
