#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
theme_name="terminal-noir"
theme_src="$repo_root/sddm/$theme_name"
wallpaper_src="$repo_root/.config/wall/catwall.png"
theme_dest="/usr/share/sddm/themes/$theme_name"
config_dest="/etc/sddm.conf.d/terminal-noir.conf"
main_config_dest="/etc/sddm.conf"
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
backup_dir="$backup_root/$(date +'%Y%m%d-%H%M%S')"
if [ -f "$config_dest" ]; then
    install -d -m 0755 "$backup_dir"
    cp -a "$config_dest" "$backup_dir/terminal-noir.conf"
fi
if [ -f "$main_config_dest" ]; then
    install -d -m 0755 "$backup_dir"
    cp -a "$main_config_dest" "$backup_dir/sddm.conf"
fi

cat > "$config_dest" <<'CONF'
[Theme]
Current=terminal-noir
CONF

set_theme_current() {
    local path="$1"
    local tmp_path

    tmp_path="$(mktemp)"

    if [ -f "$path" ]; then
        awk -v theme="$theme_name" '
            BEGIN { in_theme = 0; seen_theme = 0; done = 0 }
            /^\[/ {
                if (in_theme && !done) {
                    print "Current=" theme
                    done = 1
                }
                in_theme = ($0 == "[Theme]")
                if (in_theme)
                    seen_theme = 1
            }
            in_theme && /^[[:space:]]*Current[[:space:]]*=/ {
                print "Current=" theme
                done = 1
                next
            }
            { print }
            END {
                if (!done) {
                    if (!seen_theme) {
                        print ""
                        print "[Theme]"
                    }
                    print "Current=" theme
                }
            }
        ' "$path" > "$tmp_path"
    else
        cat > "$tmp_path" <<CONF
[Theme]
Current=terminal-noir
CONF
    fi

    install -m 0644 "$tmp_path" "$path"
    rm -f "$tmp_path"
}

set_theme_current "$main_config_dest"

printf 'Installed %s SDDM theme to %s\n' "$theme_name" "$theme_dest"
printf 'Wrote SDDM config to %s\n' "$config_dest"
printf 'Updated main SDDM config at %s\n' "$main_config_dest"
printf 'Restart SDDM or reboot to see it on the login screen.\n'
