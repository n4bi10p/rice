#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_home="$HOME"
dry_run=0

usage() {
    cat <<'USAGE'
Usage: scripts/sync-config.sh [--dry-run] [--target-home PATH]

Copies this repo's .config, .local, and managed root dotfiles into the target home directory.
Matching live paths are backed up under ~/.config/cfg_backups/terminal-noir-*.
Unrelated files in the target directories are preserved.
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run)
            dry_run=1
            ;;
        --target-home)
            shift
            target_home="${1:-}"
            [ -n "$target_home" ] || {
                printf 'Missing value for --target-home\n' >&2
                exit 2
            }
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

target_config="$target_home/.config"
backup_root="$target_config/cfg_backups"
backup_dir="$backup_root/terminal-noir-$(date +'%Y%m%d-%H%M%S')"

run() {
    if [ "$dry_run" -eq 1 ]; then
        printf '[dry-run] %q' "$1"
        shift
        for arg in "$@"; do
            printf ' %q' "$arg"
        done
        printf '\n'
    else
        "$@"
    fi
}

backup_existing() {
    local rel="$1"
    local target="$target_home/$rel"
    local backup="$backup_dir/$rel"

    [ -e "$target" ] || return 0

    run mkdir -p "$(dirname "$backup")"
    run cp -a "$target" "$backup"
    printf 'backup: %s -> %s\n' "$target" "$backup"
}

sync_path() {
    local src="$1"
    local rel="${src#"$repo_root/"}"
    local dest="$target_home/$rel"

    backup_existing "$rel"
    run mkdir -p "$(dirname "$dest")"
    if command -v rsync >/dev/null 2>&1; then
        run rsync -a "$src" "$(dirname "$dest")/"
    else
        run cp -a "$src" "$(dirname "$dest")/"
    fi
    printf 'sync: %s -> %s\n' "$src" "$dest"
}

set_qtct_stylesheet() {
    local toolkit="$1"
    local conf="$target_home/.config/${toolkit}ct/${toolkit}ct.conf"
    local stylesheet="$target_home/.config/${toolkit}ct/qss/terminal-noir.qss"
    local tmp

    [ -f "$conf" ] || return 0
    [ -f "$stylesheet" ] || return 0

    if [ "$dry_run" -eq 1 ]; then
        printf '[dry-run] set %s Interface/stylesheets -> %s\n' "$conf" "$stylesheet"
        return 0
    fi

    tmp="$(mktemp)"
    awk -v stylesheet="$stylesheet" '
        BEGIN { in_interface = 0; wrote = 0 }
        /^\[Interface\]$/ {
            in_interface = 1
            print
            next
        }
        /^\[/ && in_interface {
            if (!wrote) {
                print "stylesheets=" stylesheet
                wrote = 1
            }
            in_interface = 0
        }
        in_interface && /^stylesheets=/ {
            if (!wrote) {
                print "stylesheets=" stylesheet
                wrote = 1
            }
            next
        }
        { print }
        END {
            if (in_interface && !wrote) {
                print "stylesheets=" stylesheet
            }
        }
    ' "$conf" > "$tmp"
    mv "$tmp" "$conf"
    printf 'theme: %s uses %s\n' "$conf" "$stylesheet"
}

source_root="$repo_root/.config"
if [ -d "$source_root" ]; then
    while IFS= read -r item; do
        sync_path "$item"
    done < <(find "$source_root" -mindepth 1 -maxdepth 1 | sort)
fi

for rel in \
    ".local/bin" \
    ".local/lib" \
    ".local/share/color-schemes/TerminalNoir.colors" \
    ".local/share/terminal-noir"; do
    [ -e "$repo_root/$rel" ] || continue
    sync_path "$repo_root/$rel"
done

for rel in ".gtkrc-2.0"; do
    [ -f "$repo_root/$rel" ] || continue
    sync_path "$repo_root/$rel"
done

set_qtct_stylesheet "qt5"
set_qtct_stylesheet "qt6"

printf 'Done. Backups are under %s\n' "$backup_dir"
