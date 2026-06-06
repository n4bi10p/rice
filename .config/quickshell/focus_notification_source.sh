#!/usr/bin/env bash

set -euo pipefail

desktop_entry="${1:-}"
app_name="${2:-}"
summary="${3:-}"

normalize() {
    printf '%s' "$1" \
        | sed -E 's/[.]desktop$//I' \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/[^a-z0-9._ -]+/ /g; s/[[:space:]]+/ /g; s/^ //; s/ $//'
}

terms=()

add_term() {
    local raw="$1"
    local normalized
    normalized="$(normalize "$raw")"
    [ "${#normalized}" -gt 1 ] || return 0

    terms+=("$normalized")
    terms+=("${normalized// /-}")
    terms+=("${normalized// /}")

    local first="${normalized%% *}"
    [ "${#first}" -gt 2 ] && terms+=("$first")
}

add_term "$desktop_entry"
add_term "$app_name"
add_term "$summary"

[ "${#terms[@]}" -gt 0 ] || exit 0

clients="$(hyprctl clients -j 2>/dev/null || true)"
[ -n "$clients" ] || exit 0

while IFS=$'\t' read -r address class initial_class title; do
    [ -n "$address" ] || continue

    combined="$(normalize "$class $initial_class $title")"
    combined_hyphen="${combined// /-}"
    combined_compact="${combined// /}"

    for term in "${terms[@]}"; do
        [ "${#term}" -gt 1 ] || continue
        if [[ "$combined" == *"$term"* || "$combined_hyphen" == *"$term"* || "$combined_compact" == *"$term"* ]]; then
            hyprctl dispatch focuswindow "address:$address" >/dev/null 2>&1 || true
            exit 0
        fi
    done
done < <(printf '%s' "$clients" | jq -r '.[] | [.address, .class, .initialClass, .title] | @tsv')

exit 0
