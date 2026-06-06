#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$repo_root/scripts/pkg_core.lst"
install_packages=1
sync_config=0
install_sddm=0
dry_run=0
package_mode="all"
target_home="$HOME"

usage() {
    cat <<'USAGE'
Usage: scripts/install.sh [options]

Installs Terminal Noir packages and optionally syncs user config.

Options:
  --required-only   Install only required packages from scripts/pkg_core.lst.
  --all             Install required and recommended packages. This is default.
  --no-packages     Skip package installation.
  --sync-config     Run scripts/sync-config.sh after package installation.
  --install-sddm    Run scripts/install-sddm-theme.sh after package installation.
  --target-home DIR Target home for config sync. Defaults to $HOME.
  --dry-run         Print actions without installing or copying files.
  -h, --help        Show this help.
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --required-only)
            package_mode="required"
            ;;
        --all)
            package_mode="all"
            ;;
        --no-packages)
            install_packages=0
            ;;
        --sync-config)
            sync_config=1
            ;;
        --install-sddm)
            install_sddm=1
            ;;
        --target-home)
            shift
            target_home="${1:-}"
            [ -n "$target_home" ] || {
                printf 'Missing value for --target-home\n' >&2
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

is_arch_like() {
    [ -f /etc/arch-release ] && return 0
    [ -f /etc/os-release ] && grep -Eiq 'ID(_LIKE)?=.*(arch|endeavouros)' /etc/os-release
}

require_arch_like() {
    if ! is_arch_like; then
        printf 'This installer currently supports Arch/EndeavourOS-style systems only.\n' >&2
        exit 1
    fi
}

require_yay() {
    if ! command -v yay >/dev/null 2>&1; then
        printf 'Missing yay. Install yay first, then rerun this installer.\n' >&2
        exit 1
    fi
}

package_from_line() {
    local command_name="$1"
    local package_name="$2"

    if [ -n "$package_name" ]; then
        printf '%s\n' "$package_name"
    else
        printf '%s\n' "$command_name"
    fi
}

read_packages_by_level() {
    local requested_level="$1"
    local command_name package_name level description package

    while IFS='|' read -r command_name package_name level description || [ -n "${command_name:-}" ]; do
        case "${command_name:-}" in
            ""|\#*) continue ;;
        esac

        command_name="${command_name%%[[:space:]]*}"
        package_name="${package_name%%[[:space:]]*}"
        level="${level:-required}"

        [ "$level" = "$requested_level" ] || continue

        package="$(package_from_line "$command_name" "$package_name")"
        [ -n "$package" ] && printf '%s\n' "$package"
    done < "$manifest"
}

install_package_group() {
    local label="$1"
    shift
    local packages=("$@")

    [ "${#packages[@]}" -gt 0 ] || return 0

    printf 'Installing %s packages: %s\n' "$label" "${packages[*]}"
    run yay -S --needed "${packages[@]}"
}

install_manifest_packages() {
    local required_packages=()
    local recommended_packages=()

    [ -f "$manifest" ] || {
        printf 'Missing package manifest: %s\n' "$manifest" >&2
        exit 1
    }

    mapfile -t required_packages < <(read_packages_by_level required | sort -u)
    mapfile -t recommended_packages < <(read_packages_by_level recommended | sort -u)

    install_package_group required "${required_packages[@]}"
    if [ "$package_mode" = "all" ]; then
        install_package_group recommended "${recommended_packages[@]}"
    fi
}

require_arch_like

if [ "$install_packages" -eq 1 ]; then
    require_yay
    install_manifest_packages
fi

if [ "$sync_config" -eq 1 ]; then
    run "$repo_root/scripts/sync-config.sh" --target-home "$target_home"
fi

if [ "$install_sddm" -eq 1 ]; then
    if [ "$dry_run" -eq 1 ]; then
        run "$repo_root/scripts/install-sddm-theme.sh"
    else
        "$repo_root/scripts/install-sddm-theme.sh"
    fi
fi

printf 'Terminal Noir install step complete.\n'
