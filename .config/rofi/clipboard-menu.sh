#!/usr/bin/env bash

set -u

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
rofi_config="$config_home/rofi/config.rasi"
store_dir="$data_home/terminal-noir/clipboard"
items_dir="$store_dir/items"
index_file="$store_dir/pins.tsv"

ensure_store() {
    mkdir -p "$items_dir"
    touch "$index_file"
}

sanitize_label() {
    printf '%s' "$1" \
        | tr '\t' ' ' \
        | tr -d '\r' \
        | sed 's/[[:space:]][[:space:]]*/ /g; s/^ //; s/ $//'
}

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g'
}

encode_line() {
    printf '%s' "$1" | base64 -w0
}

decode_line() {
    printf '%s' "$1" | base64 -d
}

rofi_clipboard() {
    rofi -dmenu -i \
        -config "$rofi_config" \
        -p "clipboard" \
        -theme-str 'entry { placeholder: "Search clipboard"; }' \
        -theme-str 'listview { lines: 8; }' \
        "$@"
}

rofi_action() {
    local message="$1"
    rofi -dmenu -i \
        -config "$rofi_config" \
        -p "clipboard" \
        -mesg "$message" \
        -theme-str 'entry { placeholder: "Select action"; }' \
        -theme-str 'listview { lines: 4; }'
}

build_menu() {
    local menu_file="$1"
    local map_file="$2"
    local id mime label display line payload

    ensure_store

    printf 'Pinned Content\n' >> "$menu_file"
    printf 'Pinned Content\tsection\t\n' >> "$map_file"

    if [ -s "$index_file" ]; then
        while IFS=$'\t' read -r id mime label; do
            [ -n "${id:-}" ] || continue
            [ -f "$items_dir/$id.bin" ] || continue

            display="PINNED  ${label:-$id}"
            printf '%s\n' "$display" >> "$menu_file"
            printf '%s\tpin\t%s\n' "$display" "$id" >> "$map_file"
        done < "$index_file"
    else
        printf 'No pinned content\n' >> "$menu_file"
        printf 'No pinned content\tsection\t\n' >> "$map_file"
    fi

    printf 'Clipboard History\n' >> "$menu_file"
    printf 'Clipboard History\tsection\t\n' >> "$map_file"

    cliphist list | while IFS= read -r line; do
        [ -n "$line" ] || continue

        display="$(sanitize_label "$line")"
        payload="$(encode_line "$line")"
        printf '%s\n' "$display" >> "$menu_file"
        printf '%s\thistory\t%s\n' "$display" "$payload" >> "$map_file"
    done
}

lookup_selection() {
    local map_file="$1"
    local selection="$2"
    awk -F '\t' -v selection="$selection" '$1 == selection { print $2 "\t" $3; exit }' "$map_file"
}

copy_pin() {
    local id="$1"
    local mime

    mime="$(awk -F '\t' -v id="$id" '$1 == id { print $2; exit }' "$index_file")"
    [ -n "$mime" ] || mime="text/plain"
    [ -f "$items_dir/$id.bin" ] || exit 0

    wl-copy --type "$mime" < "$items_dir/$id.bin"
}

unpin_item() {
    local id="$1"
    local tmp_index

    tmp_index="$(mktemp)"
    awk -F '\t' -v id="$id" '$1 != id' "$index_file" > "$tmp_index"
    mv "$tmp_index" "$index_file"
    rm -f "$items_dir/$id.bin"
}

copy_history() {
    local payload="$1"
    decode_line "$payload" | cliphist decode | wl-copy
}

pin_history() {
    local payload="$1"
    local line label tmp_file mime hash id item_file

    line="$(decode_line "$payload")"
    label="$(sanitize_label "${line#*$'\t'}")"
    [ -n "$label" ] || label="$(sanitize_label "$line")"

    tmp_file="$(mktemp)"
    decode_line "$payload" | cliphist decode > "$tmp_file"

    mime="$(file --mime-type -b "$tmp_file" 2>/dev/null || printf 'text/plain')"
    [ -n "$mime" ] || mime="text/plain"

    hash="$(sha256sum "$tmp_file" | awk '{ print $1 }')"
    id="${hash:0:20}"
    item_file="$items_dir/$id.bin"

    mv "$tmp_file" "$item_file"

    if ! awk -F '\t' -v id="$id" '$1 == id { found = 1 } END { exit found ? 0 : 1 }' "$index_file"; then
        printf '%s\t%s\t%s\n' "$id" "$mime" "$label" >> "$index_file"
    fi
}

delete_history() {
    local payload="$1"
    decode_line "$payload" | cliphist delete
}

list_json() {
    local first id mime label line payload display

    ensure_store

    printf '{"pins":['
    first=true
    if [ -s "$index_file" ]; then
        while IFS=$'\t' read -r id mime label; do
            [ -n "${id:-}" ] || continue
            [ -f "$items_dir/$id.bin" ] || continue

            if [ "$first" = true ]; then
                first=false
            else
                printf ','
            fi

            printf '{"id":"%s","mime":"%s","label":"%s"}' \
                "$(json_escape "$id")" \
                "$(json_escape "${mime:-text/plain}")" \
                "$(json_escape "${label:-$id}")"
        done < "$index_file"
    fi

    printf '],"history":['
    first=true
    while IFS= read -r line; do
        [ -n "$line" ] || continue

        display="$(sanitize_label "${line#*$'\t'}")"
        [ -n "$display" ] || display="$(sanitize_label "$line")"
        payload="$(encode_line "$line")"

        if [ "$first" = true ]; then
            first=false
        else
            printf ','
        fi

        printf '{"label":"%s","payload":"%s"}' \
            "$(json_escape "$display")" \
            "$(json_escape "$payload")"
    done < <(cliphist list)

    printf ']}\n'
}

show_actions() {
    local kind="$1"
    local payload="$2"
    local display="$3"
    local action

    case "$kind" in
        pin)
            action="$(printf 'Copy\nUnpin\n' | rofi_action "$display")"
            case "$action" in
                Copy) copy_pin "$payload" ;;
                Unpin) unpin_item "$payload" ;;
            esac
            ;;
        history)
            action="$(printf 'Copy\nPin\nDelete from History\n' | rofi_action "$display")"
            case "$action" in
                Copy) copy_history "$payload" ;;
                Pin) pin_history "$payload" ;;
                "Delete from History") delete_history "$payload" ;;
            esac
            ;;
    esac
}

main() {
    local menu_file map_file selection lookup kind payload

    case "${1:-}" in
        --list-json)
            list_json
            exit 0
            ;;
        --copy-history)
            copy_history "${2:-}"
            exit 0
            ;;
        --pin-history)
            pin_history "${2:-}"
            exit 0
            ;;
        --delete-history)
            delete_history "${2:-}"
            exit 0
            ;;
        --copy-pin)
            copy_pin "${2:-}"
            exit 0
            ;;
        --unpin)
            unpin_item "${2:-}"
            exit 0
            ;;
    esac

    menu_file="$(mktemp)"
    map_file="$(mktemp)"
    trap 'rm -f "$menu_file" "$map_file"' EXIT

    build_menu "$menu_file" "$map_file"

    if [ "${1:-}" = "--dump-menu" ]; then
        cat "$menu_file"
        exit 0
    fi

    selection="$(rofi_clipboard < "$menu_file")"
    [ -n "$selection" ] || exit 0

    lookup="$(lookup_selection "$map_file" "$selection")"
    [ -n "$lookup" ] || exit 0

    kind="${lookup%%$'\t'*}"
    payload="${lookup#*$'\t'}"

    [ "$kind" != "section" ] || exit 0
    show_actions "$kind" "$payload" "$selection"
}

main "$@"
