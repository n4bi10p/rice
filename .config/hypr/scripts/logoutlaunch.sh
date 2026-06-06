#!/usr/bin/env bash

set -euo pipefail

if pgrep -x wlogout >/dev/null 2>&1; then
    pkill -x wlogout
    exit 0
fi

layout="${XDG_CONFIG_HOME:-$HOME/.config}/wlogout/layout"
style="${XDG_CONFIG_HOME:-$HOME/.config}/wlogout/style.css"

if [ -f "$layout" ] && [ -f "$style" ]; then
    exec wlogout -b 5 -c 0 -r 0 -m 0 --layout "$layout" --css "$style" --protocol layer-shell
fi

exec wlogout
