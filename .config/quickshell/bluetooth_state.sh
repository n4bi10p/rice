#!/usr/bin/env sh

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g'
}

controller_info=$(bluetoothctl show 2>/dev/null || true)
powered=false
discovering=false

if printf '%s\n' "$controller_info" | grep -q 'Powered: yes'; then
    powered=true
fi

if printf '%s\n' "$controller_info" | grep -q 'Discovering: yes'; then
    discovering=true
fi

printf '{"powered":%s,"scanning":%s,"devices":[' "$powered" "$discovering"

first=true
bluetoothctl devices 2>/dev/null |
while read -r _ mac name; do
    [ -n "$mac" ] || continue
    info=$(bluetoothctl info "$mac" 2>/dev/null || true)

    connected=false
    paired=false
    trusted=false
    blocked=false

    printf '%s\n' "$info" | grep -q 'Connected: yes' && connected=true
    printf '%s\n' "$info" | grep -q 'Paired: yes' && paired=true
    printf '%s\n' "$info" | grep -q 'Trusted: yes' && trusted=true
    printf '%s\n' "$info" | grep -q 'Blocked: yes' && blocked=true

    if [ "$first" = true ]; then
        first=false
    else
        printf ','
    fi

    printf '{"mac":"%s","name":"%s","connected":%s,"paired":%s,"trusted":%s,"blocked":%s}' \
        "$(json_escape "$mac")" \
        "$(json_escape "$name")" \
        "$connected" \
        "$paired" \
        "$trusted" \
        "$blocked"
done

printf ']}\n'
