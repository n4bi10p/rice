#!/usr/bin/env bash

set -euo pipefail

target_home="$HOME"
dry_run=0
backup_root=""
backup_arg="latest"

usage() {
    cat <<'USAGE'
Usage: scripts/restore-config.sh [backup-dir|latest] [options]

Restores a Terminal Noir config backup.

Options:
  --target-home DIR  Home directory to restore into. Defaults to $HOME.
  --backup-root DIR  Backup root. Defaults to ~/.local/state/terminal-noir/backups.
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
        --dry-run)
            dry_run=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            printf 'Unknown argument: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
        *)
            backup_arg="$1"
            ;;
    esac
    shift
done

[ -n "$backup_root" ] || backup_root="$target_home/.local/state/terminal-noir/backups"

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

resolve_backup() {
    if [ "$backup_arg" = "latest" ]; then
        find "$backup_root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n 1
    else
        printf '%s\n' "$backup_arg"
    fi
}

backup_dir="$(resolve_backup)"
[ -n "$backup_dir" ] || {
    printf 'No backup found under %s\n' "$backup_root" >&2
    exit 1
}

[ -d "$backup_dir" ] || {
    printf 'Backup directory does not exist: %s\n' "$backup_dir" >&2
    exit 1
}

restore_tree() {
    local source_root="$1"
    local dest_root="$2"

    [ -d "$source_root" ] || return 0
    while IFS= read -r item; do
        local rel="${item#"$source_root/"}"
        local dest="$dest_root/$rel"
        run mkdir -p "$(dirname "$dest")"
        run cp -a "$item" "$dest"
        printf 'restore: %s -> %s\n' "$item" "$dest"
    done < <(find "$source_root" -mindepth 1 -maxdepth 1 | sort)
}

restore_tree "$backup_dir/.config" "$target_home/.config"
restore_tree "$backup_dir/.local" "$target_home/.local"

if [ -d "$backup_dir/etc" ]; then
    if [ "$(id -u)" -ne 0 ]; then
        printf 'Skipping /etc restore because root is required.\n' >&2
    else
        restore_tree "$backup_dir/etc" "/etc"
    fi
fi

printf 'Restore complete from %s\n' "$backup_dir"
