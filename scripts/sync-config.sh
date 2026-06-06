#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_home="$HOME"
dry_run=0

usage() {
    cat <<'USAGE'
Usage: scripts/sync-config.sh [--dry-run] [--target-home PATH]

Copies this repo's .config and .local trees into the target home directory.
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

for source_root in "$repo_root/.config" "$repo_root/.local"; do
    [ -d "$source_root" ] || continue
    while IFS= read -r item; do
        sync_path "$item"
    done < <(find "$source_root" -mindepth 1 -maxdepth 1 | sort)
done

printf 'Done. Backups are under %s\n' "$backup_dir"
