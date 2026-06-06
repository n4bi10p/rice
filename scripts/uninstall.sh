#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_home="$HOME"
dry_run=0
skip_backup=0

usage() {
    cat <<'USAGE'
Usage: scripts/uninstall.sh [options]

Removes Terminal Noir managed config files. Packages are never removed.

Options:
  --target-home DIR  Home directory to clean. Defaults to $HOME.
  --skip-backup      Do not create a pre-uninstall backup.
  --dry-run          Print actions without removing files.
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
        --skip-backup)
            skip_backup=1
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

if [ "$skip_backup" -eq 0 ]; then
    backup_args=(--target-home "$target_home")
    [ "$dry_run" -eq 1 ] && backup_args+=(--dry-run)
    "$repo_root/scripts/backup-config.sh" "${backup_args[@]}"
fi

managed_paths=(
    ".gtkrc-2.0"
    ".config/hypr"
    ".config/waybar"
    ".config/quickshell"
    ".config/rofi"
    ".config/wlogout"
    ".config/kitty"
    ".config/swayosd"
    ".config/gtk-3.0/settings.ini"
    ".config/gtk-3.0/gtk.css"
    ".config/gtk-4.0/settings.ini"
    ".config/gtk-4.0/gtk.css"
    ".config/xsettingsd/xsettingsd.conf"
    ".config/qt5ct/qt5ct.conf"
    ".config/qt5ct/colors/terminal-noir.conf"
    ".config/qt6ct/qt6ct.conf"
    ".config/qt6ct/colors/terminal-noir.conf"
    ".config/Kvantum/kvantum.kvconfig"
    ".config/Kvantum/TerminalNoir"
    ".config/kdeglobals"
    ".config/dolphinrc"
    ".config/vim/colors/terminal-noir.vim"
    ".config/terminal-noir"
    ".local/bin/tnctl"
    ".local/lib/terminal-noir"
    ".local/share/terminal-noir"
)

for rel in "${managed_paths[@]}"; do
    target="$target_home/$rel"
    [ -e "$target" ] || continue
    run rm -rf "$target"
    printf 'remove: %s\n' "$target"
done

printf 'Terminal Noir config uninstall complete. Packages were not removed.\n'
