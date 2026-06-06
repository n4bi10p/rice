#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
theme_name="terminal-noir"
theme_src="$repo_root/sddm/$theme_name"
wallpaper_src="$repo_root/.config/wall/catwall.png"
theme_dest="/usr/share/sddm/themes/$theme_name"
config_dest="/etc/sddm.conf.d/terminal-noir.conf"
backup_root="/etc/sddm.conf.d/terminal-noir-backups"

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    printf 'Usage: scripts/install-sddm-theme.sh\n'
    printf 'Installs the Terminal Noir SDDM theme. Requires root privileges.\n'
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

[ -d "$theme_src" ] || {
    printf 'Missing theme source: %s\n' "$theme_src" >&2
    exit 1
}

[ -f "$wallpaper_src" ] || {
    printf 'Missing wallpaper source: %s\n' "$wallpaper_src" >&2
    exit 1
}

install -d -m 0755 "$theme_dest"
cp -a "$theme_src/." "$theme_dest/"
install -m 0644 "$wallpaper_src" "$theme_dest/background.png"

if command -v magick >/dev/null 2>&1; then
    magick "$wallpaper_src" -resize 1920x1080^ -gravity center -extent 1920x1080 -blur 0x18 -fill '#000000' -colorize 28 "$theme_dest/background-blur.png"
elif command -v convert >/dev/null 2>&1; then
    convert "$wallpaper_src" -resize 1920x1080^ -gravity center -extent 1920x1080 -blur 0x18 -fill '#000000' -colorize 28 "$theme_dest/background-blur.png"
else
    cp "$theme_dest/background.png" "$theme_dest/background-blur.png"
fi

install -d -m 0755 "$(dirname "$config_dest")"
if [ -f "$config_dest" ]; then
    backup_dir="$backup_root/$(date +'%Y%m%d-%H%M%S')"
    install -d -m 0755 "$backup_dir"
    cp -a "$config_dest" "$backup_dir/terminal-noir.conf"
fi

cat > "$config_dest" <<'CONF'
[Theme]
Current=terminal-noir
CONF

printf 'Installed %s SDDM theme to %s\n' "$theme_name" "$theme_dest"
printf 'Wrote SDDM config to %s\n' "$config_dest"
printf 'Restart SDDM or reboot to see it on the login screen.\n'
