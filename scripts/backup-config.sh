#!/usr/bin/env bash

set -euo pipefail

target_home="$HOME"
dry_run=0
include_sddm=0
backup_root=""

usage() {
    cat <<'USAGE'
Usage: scripts/backup-config.sh [options]

Backs up Terminal Noir managed config paths.

Options:
  --target-home DIR  Home directory to back up. Defaults to $HOME.
  --backup-root DIR  Backup root. Defaults to ~/.local/state/terminal-noir/backups.
  --include-sddm     Also back up /etc/sddm.conf and /etc/sddm.conf.d when run as root.
  --dry-run          Print actions without copying.
  -h, --help         Show this help.
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --target-home)
            shift
            target_home="${1:-}"
            [ -n "$target_home" ] || {
                printf 'Missing value for --target-home\n' >&2
                exit 2
            }
            ;;
        --backup-root)
            shift
            backup_root="${1:-}"
            [ -n "$backup_root" ] || {
                printf 'Missing value for --backup-root\n' >&2
                exit 2
            }
            ;;
        --include-sddm)
            include_sddm=1
            ;;
        --dry-run)
            dry_run=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown argument: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

[ -n "$backup_root" ] || backup_root="$target_home/.local/state/terminal-noir/backups"
backup_dir="$backup_root/$(date +'%Y%m%d-%H%M%S')"

run() {
    if [ "$dry_run" -eq 1 ]; then
        printf '[dry-run]'
        for arg in "$@"; do
            printf ' %q' "$arg"
        done
        printf '\n'
    else
        "$@"
    fi
}

backup_path() {
    local source_path="$1"
    local rel_path="$2"
    local dest_path="$backup_dir/$rel_path"

    [ -e "$source_path" ] || return 0

    run mkdir -p "$(dirname "$dest_path")"
    run cp -a "$source_path" "$dest_path"
    printf 'backup: %s -> %s\n' "$source_path" "$dest_path"
}

managed_paths=(
    ".gtkrc-2.0"
    ".config/hypr"
    ".config/waybar"
    ".config/quickshell"
    ".config/rofi"
    ".config/wlogout"
    ".config/kitty"
    ".config/swayosd"
    ".config/gtk-3.0"
    ".config/gtk-4.0"
    ".config/xsettingsd"
    ".config/Trolltech.conf"
    ".config/qt5ct"
    ".config/qt6ct"
    ".config/Kvantum"
    ".local/share/color-schemes/TerminalNoir.colors"
    ".config/kdeglobals"
    ".config/dolphinrc"
    ".config/vim"
    ".config/Code"
    ".config/Code - OSS"
    ".config/VSCodium"
    ".config/spotify-flags.conf"
    ".config/spicetify"
    ".config/terminal-noir"
    ".local/bin/tnctl"
    ".local/lib/terminal-noir"
    ".local/share/terminal-noir"
)

run mkdir -p "$backup_dir"

for rel in "${managed_paths[@]}"; do
    backup_path "$target_home/$rel" "$rel"
done

if [ "$include_sddm" -eq 1 ]; then
    if [ "$(id -u)" -ne 0 ]; then
        printf 'Skipping SDDM backup because --include-sddm requires root.\n' >&2
    else
        backup_path "/etc/sddm.conf" "etc/sddm.conf"
        backup_path "/etc/sddm.conf.d" "etc/sddm.conf.d"
    fi
fi

printf 'Backup complete: %s\n' "$backup_dir"
