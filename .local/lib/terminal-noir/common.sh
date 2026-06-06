#!/usr/bin/env bash

terminal_noir_config_file() {
    printf '%s/terminal-noir/config.toml\n' "${XDG_CONFIG_HOME:-$HOME/.config}"
}

terminal_noir_state_dir() {
    printf '%s/terminal-noir\n' "${XDG_STATE_HOME:-$HOME/.local/state}"
}

terminal_noir_state_file() {
    printf '%s/%s\n' "$(terminal_noir_state_dir)" "$1"
}

terminal_noir_config_value() {
    local key="$1"
    local config
    config="$(terminal_noir_config_file)"
    [ -f "$config" ] || return 1

    awk -F= -v key="$key" '
        $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
            value = $2
            sub(/^[[:space:]]*/, "", value)
            sub(/[[:space:]]*$/, "", value)
            sub(/^"/, "", value)
            sub(/"$/, "", value)
            print value
            exit
        }
    ' "$config"
}

expand_path() {
    local path="$1"

    case "$path" in
        "~") printf '%s\n' "$HOME" ;;
        "~/"*) printf '%s/%s\n' "$HOME" "${path#~/}" ;;
        "\$HOME"*) printf '%s%s\n' "$HOME" "${path#\$HOME}" ;;
        "\$XDG_CONFIG_HOME"*) printf '%s%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}" "${path#\$XDG_CONFIG_HOME}" ;;
        *) printf '%s\n' "$path" ;;
    esac
}

absolute_file_path() {
    local path
    path="$(expand_path "$1")"
    [ -f "$path" ] || return 1

    local dir
    dir="$(cd "$(dirname "$path")" && pwd)"
    printf '%s/%s\n' "$dir" "$(basename "$path")"
}

terminal_noir_wallpaper_dir() {
    local configured
    configured="$(terminal_noir_config_value wallpaper_dir 2>/dev/null || true)"
    if [ -n "$configured" ]; then
        expand_path "$configured"
    else
        printf '%s/wall\n' "${XDG_CONFIG_HOME:-$HOME/.config}"
    fi
}

terminal_noir_config_wallpaper() {
    local configured
    configured="$(terminal_noir_config_value wallpaper 2>/dev/null || true)"
    [ -n "$configured" ] || return 1
    absolute_file_path "$configured"
}

terminal_noir_list_wallpapers() {
    local wallpaper_dir
    wallpaper_dir="$(terminal_noir_wallpaper_dir)"
    [ -d "$wallpaper_dir" ] || return 1

    find "$wallpaper_dir" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
        | sort
}

terminal_noir_current_wallpaper() {
    local state_file
    state_file="$(terminal_noir_state_file current-wallpaper)"

    if [ -f "$state_file" ]; then
        local current
        current="$(cat "$state_file")"
        if [ -f "$current" ]; then
            printf '%s\n' "$current"
            return 0
        fi
    fi

    terminal_noir_config_wallpaper && return 0
    terminal_noir_list_wallpapers | head -n 1
}

terminal_noir_set_current_wallpaper() {
    local wallpaper="$1"
    mkdir -p "$(terminal_noir_state_dir)"
    printf '%s\n' "$wallpaper" > "$(terminal_noir_state_file current-wallpaper)"
}

terminal_noir_notify() {
    [ "${TNCTL_SKIP_APPLY:-0}" = "1" ] && return 0
    command -v notify-send >/dev/null 2>&1 && notify-send "Terminal Noir" "$1" || true
}
