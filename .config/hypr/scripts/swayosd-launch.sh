#!/usr/bin/env bash

set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
runtime_config="$runtime_dir/terminal-noir-swayosd.toml"
style_path="$config_home/swayosd/style.css"

cat >"$runtime_config" <<CONFIG
[server]
style = "$style_path"
top_margin = 0.08
max_volume = 100
min_brightness = 5
show_percentage = true
keyboard_backlight = true

[client]
CONFIG

exec swayosd-server --config "$runtime_config"
