#!/usr/bin/env bash

set -euo pipefail

shot_dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
record_dir="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"

notify() {
    local title="$1"
    local body="${2:-}"

    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$title" "$body"
    fi
}

need_cmd() {
    local command_name="$1"
    local label="$2"

    if command -v "$command_name" >/dev/null 2>&1; then
        return 0
    fi

    notify "Terminal Noir" "$label is not installed"
    return 1
}

timestamp() {
    date +"%Y-%m-%d_%H-%M-%S"
}

shot_file() {
    mkdir -p "$shot_dir"
    printf '%s/terminal-noir-%s.png\n' "$shot_dir" "$(timestamp)"
}

record_file() {
    mkdir -p "$record_dir"
    printf '%s/terminal-noir-%s.mp4\n' "$record_dir" "$(timestamp)"
}

run_grimblast() {
    need_cmd grimblast "grimblast" || return 1
    grimblast -n "$@"
}

area_to_clipboard() {
    run_grimblast copy area
}

area_to_file() {
    local file
    file="$(shot_file)"
    run_grimblast save area "$file"
}

area_annotate() {
    need_cmd grimblast "grimblast" || return 1
    need_cmd satty "satty" || return 1

    mkdir -p "$shot_dir"

    local tmp_file
    tmp_file="$(mktemp --suffix=.png)"

    if ! grimblast save area "$tmp_file"; then
        rm -f "$tmp_file"
        return 1
    fi

    satty \
        --filename "$tmp_file" \
        --output-filename "$shot_dir/terminal-noir-%Y-%m-%d_%H-%M-%S.png" \
        --copy-command wl-copy \
        --fullscreen current-screen \
        --actions-on-enter save-to-clipboard \
        --actions-on-escape exit
}

fullscreen_to_clipboard() {
    run_grimblast copy screen
}

fullscreen_to_file() {
    local file
    file="$(shot_file)"
    run_grimblast save screen "$file"
}

monitor_to_file() {
    local file
    file="$(shot_file)"
    run_grimblast save output "$file"
}

color_picker() {
    need_cmd hyprpicker "hyprpicker" || return 1
    hyprpicker -an
}

toggle_recording() {
    if pgrep -x wf-recorder >/dev/null 2>&1; then
        pkill -INT -x wf-recorder
        notify "Terminal Noir" "Screen recording stopped"
        return 0
    fi

    need_cmd wf-recorder "wf-recorder" || return 1

    local file
    file="$(record_file)"
    wf-recorder -f "$file" >/tmp/terminal-noir-wf-recorder.log 2>&1 &
    notify "Terminal Noir" "Recording to $file"
}

recording_label() {
    if pgrep -x wf-recorder >/dev/null 2>&1; then
        printf 'Stop recording\n'
    else
        printf 'Start recording\n'
    fi
}

open_menu() {
    need_cmd rofi "rofi" || return 1

    {
        printf 'Area to clipboard\n'
        printf 'Area to file\n'
        printf 'Area annotate\n'
        printf 'Fullscreen to clipboard\n'
        printf 'Fullscreen to file\n'
        printf 'Monitor to file\n'
        printf 'Color picker\n'
        recording_label
    } | rofi \
        -dmenu \
        -i \
        -p "screenshot" \
        -theme-str 'entry { placeholder: "Select screenshot action"; }' \
        -theme-str 'listview { lines: 8; }' \
        -theme-str 'window { width: 520px; }'
}

choice="$(open_menu || true)"

case "$choice" in
    "Area to clipboard") area_to_clipboard ;;
    "Area to file") area_to_file ;;
    "Area annotate") area_annotate ;;
    "Fullscreen to clipboard") fullscreen_to_clipboard ;;
    "Fullscreen to file") fullscreen_to_file ;;
    "Monitor to file") monitor_to_file ;;
    "Color picker") color_picker ;;
    "Start recording"|"Stop recording") toggle_recording ;;
    "" ) exit 0 ;;
    * ) exit 0 ;;
esac
