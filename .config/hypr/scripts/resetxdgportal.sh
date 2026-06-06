#!/usr/bin/env bash

set -euo pipefail

if ! command -v xdg-desktop-portal-hyprland >/dev/null 2>&1; then
    exit 0
fi

pkill -x xdg-desktop-portal-hyprland >/dev/null 2>&1 || true
pkill -x xdg-desktop-portal >/dev/null 2>&1 || true

sleep 1

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user restart xdg-desktop-portal-hyprland.service >/dev/null 2>&1 || true
    systemctl --user restart xdg-desktop-portal.service >/dev/null 2>&1 || true
fi

if ! pgrep -x xdg-desktop-portal-hyprland >/dev/null 2>&1; then
    xdg-desktop-portal-hyprland >/tmp/terminal-noir-xdph.log 2>&1 &
fi

if command -v xdg-desktop-portal >/dev/null 2>&1 && ! pgrep -x xdg-desktop-portal >/dev/null 2>&1; then
    xdg-desktop-portal >/tmp/terminal-noir-xdp.log 2>&1 &
fi
