#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$script_dir/common.sh"

action="${1:-help}"
shift || true
theme="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/terminal-noir.rasi"

usage() {
    cat <<'USAGE'
Usage: tnctl rofi <apps|windows|files|web|emoji|glyph> [query]
USAGE
}

run_rofi() {
    rofi "$@" -theme "$theme"
}

run_dmenu() {
    rofi -dmenu -i -theme "$theme" "$@"
}

open_target() {
    local target="$1"
    if [ "${TNCTL_SKIP_APPLY:-0}" = "1" ]; then
        printf '%s\n' "$target"
        return 0
    fi

    command -v xdg-open >/dev/null 2>&1 || {
        printf 'xdg-open is required to open %s\n' "$target" >&2
        exit 1
    }
    xdg-open "$target" >/dev/null 2>&1 &
}

urlencode() {
    local query="$1"
    if command -v jq >/dev/null 2>&1; then
        jq -rn --arg query "$query" '$query|@uri'
    else
        printf '%s\n' "${query// /%20}"
    fi
}

file_candidates() {
    find "$HOME" -maxdepth 5 -type f \
        ! -path '*/.cache/*' \
        ! -path '*/.local/share/Trash/*' \
        | sort
}

copy_selection() {
    local kind="$1"
    local value="$2"

    if [ "${TNCTL_SKIP_APPLY:-0}" = "1" ]; then
        printf 'Copied %s: %s\n' "$kind" "$value"
        return 0
    fi

    command -v wl-copy >/dev/null 2>&1 || {
        printf 'wl-copy is required to copy %s selections.\n' "$kind" >&2
        exit 1
    }
    printf '%s' "$value" | wl-copy
    terminal_noir_notify "Copied ${kind}"
}

emoji_items() {
    if command -v perl >/dev/null 2>&1 && perl -Mcharnames=:full -CS -e '
        binmode STDOUT, ":encoding(UTF-8)";
        my %seen;
        for my $cp (0x2600..0x1FAFF) {
            my $char = chr($cp);
            next unless $char =~ /\p{Emoji_Presentation}|\p{Extended_Pictographic}/;
            my $name = charnames::viacode($cp) // next;
            $name = lc $name;
            $name =~ s/\s+/ /g;
            next if $seen{$char}++;
            print "$char\t$name\n";
        }
    '; then
        return 0
    fi

    printf '%s\t%s\n' \
        "✓" "check" \
        "✕" "cross" \
        "★" "star" \
        "→" "arrow right" \
        "↑" "arrow up" \
        "↓" "arrow down" \
        "♥" "heart" \
        "☕" "coffee"
}

glyph_items() {
    printf '%s\t%s\n' \
        "" "arch" \
        "" "terminal" \
        "󰖟" "wifi" \
        "󰂯" "bluetooth" \
        "󰕾" "volume" \
        "󰃠" "brightness" \
        "󰌾" "lock" \
        "󰐥" "power"
}

pick_from_items() {
    local kind="$1"
    local selection
    local placeholder="Search ${kind}"

    if [ "${TNCTL_LIST_ITEMS:-0}" = "1" ]; then
        "$kind"_items
        return
    fi

    if [ "${TNCTL_SKIP_APPLY:-0}" = "1" ]; then
        selection="$("$kind"_items)"
        selection="${selection%%$'\n'*}"
    else
        selection="$("$kind"_items | run_dmenu -p "$kind" -theme-str "entry { placeholder: \"${placeholder}\"; }")"
    fi

    [ -n "$selection" ] || exit 0
    copy_selection "$kind" "${selection%%	*}"
}

case "$action" in
    apps)
        run_rofi -show drun
        ;;
    windows)
        run_rofi -show window
        ;;
    files)
        if [ "${TNCTL_SKIP_APPLY:-0}" = "1" ]; then
            file_candidates
            exit 0
        fi
        selection="$(file_candidates | run_dmenu -p files)"
        [ -n "$selection" ] || exit 0
        open_target "$selection"
        ;;
    web)
        query="${*:-}"
        if [ -z "$query" ]; then
            query="$(printf '' | run_dmenu -p web)"
        fi
        [ -n "$query" ] || exit 0

        case "$query" in
            http://*|https://*) url="$query" ;;
            *) url="https://www.google.com/search?q=$(urlencode "$query")" ;;
        esac
        open_target "$url"
        ;;
    emoji)
        pick_from_items emoji
        ;;
    glyph)
        pick_from_items glyph
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        printf 'Unknown rofi action: %s\n' "$action" >&2
        usage >&2
        exit 2
        ;;
esac
