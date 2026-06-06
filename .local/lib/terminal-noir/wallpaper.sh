#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$script_dir/common.sh"

action="${1:-help}"
shift || true

usage() {
    cat <<'USAGE'
Usage: tnctl wallpaper <list|current|select|set|next|prev|apply> [path]
USAGE
}

require_wallpaper() {
    local wallpaper="$1"
    if ! wallpaper="$(absolute_file_path "$wallpaper")"; then
        printf 'Wallpaper not found: %s\n' "$1" >&2
        exit 1
    fi
    printf '%s\n' "$wallpaper"
}

apply_wallpaper() {
    local wallpaper="$1"

    if [ "${TNCTL_SKIP_APPLY:-0}" = "1" ]; then
        printf 'skip apply: %s\n' "$wallpaper"
        return 0
    fi

    command -v swaybg >/dev/null 2>&1 || {
        printf 'swaybg is required to apply wallpapers.\n' >&2
        exit 1
    }

    pkill -x swaybg >/dev/null 2>&1 || true
    swaybg -i "$wallpaper" -m fill >/dev/null 2>&1 &
    terminal_noir_notify "Wallpaper applied"
}

set_wallpaper() {
    local wallpaper
    wallpaper="$(require_wallpaper "$1")"
    # common.sh owns the current-wallpaper state file path.
    terminal_noir_set_current_wallpaper "$wallpaper"
    apply_wallpaper "$wallpaper"
    printf '%s\n' "$wallpaper"
}

cycle_wallpaper() {
    local direction="$1"
    mapfile -t wallpapers < <(terminal_noir_list_wallpapers)
    [ "${#wallpapers[@]}" -gt 0 ] || {
        printf 'No wallpapers found in %s\n' "$(terminal_noir_wallpaper_dir)" >&2
        exit 1
    }

    local current
    current="$(terminal_noir_current_wallpaper || true)"
    local index=0
    local i
    for i in "${!wallpapers[@]}"; do
        if [ "${wallpapers[$i]}" = "$current" ]; then
            index="$i"
            break
        fi
    done

    if [ "$direction" = "next" ]; then
        index=$(( (index + 1) % ${#wallpapers[@]} ))
    else
        index=$(( (index + ${#wallpapers[@]} - 1) % ${#wallpapers[@]} ))
    fi

    set_wallpaper "${wallpapers[$index]}"
}

case "$action" in
    list)
        terminal_noir_list_wallpapers
        ;;
    current)
        terminal_noir_current_wallpaper
        ;;
    set)
        wallpaper="${1:-}"
        [ -n "$wallpaper" ] || {
            printf 'Usage: tnctl wallpaper set <path>\n' >&2
            exit 2
        }
        set_wallpaper "$wallpaper"
        ;;
    apply)
        wallpaper="${1:-}"
        if [ -n "$wallpaper" ]; then
            wallpaper="$(require_wallpaper "$wallpaper")"
        else
            wallpaper="$(terminal_noir_current_wallpaper)"
        fi
        apply_wallpaper "$wallpaper"
        printf '%s\n' "$wallpaper"
        ;;
    next|prev)
        cycle_wallpaper "$action"
        ;;
    select)
        command -v rofi >/dev/null 2>&1 || {
            terminal_noir_list_wallpapers
            exit 0
        }
        selection="$(terminal_noir_list_wallpapers | rofi -dmenu -i -p wallpaper)"
        [ -n "$selection" ] || exit 0
        set_wallpaper "$selection"
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        printf 'Unknown wallpaper action: %s\n' "$action" >&2
        usage >&2
        exit 2
        ;;
esac
