#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail_count=0

fail() {
    printf 'FAIL: %s\n' "$1"
    fail_count=$((fail_count + 1))
}

pass() {
    printf 'PASS: %s\n' "$1"
}

require_file() {
    local path="$1"
    [ -f "$repo_root/$path" ] && pass "$path exists" || fail "$path is missing"
}

require_contains() {
    local path="$1"
    local pattern="$2"
    local label="$3"

    if [ ! -f "$repo_root/$path" ]; then
        fail "$path is missing for $label"
        return
    fi

    if grep -Eq -- "$pattern" "$repo_root/$path"; then
        pass "$label"
    else
        fail "$label"
    fi
}

for path in \
    ".config/gtk-3.0/settings.ini" \
    ".config/gtk-3.0/gtk.css" \
    ".config/gtk-4.0/settings.ini" \
    ".config/gtk-4.0/gtk.css" \
    ".gtkrc-2.0" \
    ".config/xsettingsd/xsettingsd.conf" \
    ".config/qt5ct/qt5ct.conf" \
    ".config/qt6ct/qt6ct.conf" \
    ".config/qt5ct/colors/terminal-noir.conf" \
    ".config/qt6ct/colors/terminal-noir.conf" \
    ".config/Kvantum/kvantum.kvconfig" \
    ".config/Kvantum/TerminalNoir/TerminalNoir.kvconfig" \
    ".config/kdeglobals" \
    ".config/dolphinrc"; do
    require_file "$path"
done

require_contains ".config/gtk-3.0/settings.ini" '^gtk-application-prefer-dark-theme=1$' "GTK3 prefers dark theme"
require_contains ".config/gtk-4.0/settings.ini" '^gtk-application-prefer-dark-theme=1$' "GTK4 prefers dark theme"
require_contains ".config/gtk-3.0/settings.ini" '^gtk-font-name=JetBrainsMono Nerd Font 10$' "GTK3 uses Terminal Noir font"
require_contains ".config/gtk-4.0/settings.ini" '^gtk-font-name=JetBrainsMono Nerd Font 10$' "GTK4 uses Terminal Noir font"
require_contains ".gtkrc-2.0" '^gtk-theme-name="Adwaita-dark"$' "GTK2 uses dark fallback theme"
require_contains ".config/gtk-3.0/gtk.css" '@define-color noir_bg #141313' "GTK3 CSS defines Terminal Noir background"
require_contains ".config/gtk-4.0/gtk.css" '@define-color noir_bg #141313' "GTK4 CSS defines Terminal Noir background"
require_contains ".config/gtk-3.0/gtk.css" '@define-color noir_selected #2a2a2a' "GTK3 selection uses dark grey"
require_contains ".config/gtk-4.0/gtk.css" '@define-color noir_selected #2a2a2a' "GTK4 selection uses dark grey"
require_contains ".config/gtk-3.0/gtk.css" 'background-color: @noir_selected' "GTK3 selection avoids white highlight"
require_contains ".config/gtk-4.0/gtk.css" 'background-color: @noir_selected' "GTK4 selection avoids white highlight"
require_contains ".config/xsettingsd/xsettingsd.conf" '^Net/ThemeName "Adwaita-dark"$' "xsettingsd mirrors GTK theme"

require_contains ".config/qt5ct/qt5ct.conf" '^style=kvantum$' "Qt5 uses Kvantum style"
require_contains ".config/qt6ct/qt6ct.conf" '^style=kvantum$' "Qt6 uses Kvantum style"
require_contains ".config/qt5ct/qt5ct.conf" 'terminal-noir\.conf' "Qt5 uses Terminal Noir color scheme"
require_contains ".config/qt6ct/qt6ct.conf" 'terminal-noir\.conf' "Qt6 uses Terminal Noir color scheme"
require_contains ".config/Kvantum/kvantum.kvconfig" '^theme=TerminalNoir$' "Kvantum selects Terminal Noir theme"
require_contains ".config/Kvantum/TerminalNoir/TerminalNoir.kvconfig" '^window\.color=#141313$' "Kvantum theme uses design background color"
require_contains ".config/Kvantum/TerminalNoir/TerminalNoir.kvconfig" '^highlight\.color=#2a2a2a$' "Kvantum selection uses dark grey"
require_contains ".config/Kvantum/TerminalNoir/TerminalNoir.kvconfig" '^highlight\.text\.color=#e5e2e1$' "Kvantum selected text remains readable"
require_contains ".config/Kvantum/TerminalNoir/TerminalNoir.kvconfig" '^transparent_dolphin_view=true$' "Kvantum enables transparent Dolphin view"
require_contains ".config/kdeglobals" '^TerminalApplication=kitty$' "KDE globals use kitty terminal"
require_contains ".config/kdeglobals" '^ColorScheme=TerminalNoir$' "KDE globals select Terminal Noir color scheme"
require_contains ".config/kdeglobals" '^BackgroundAlternate=28,27,27$' "KDE view alternate rows use dark grey"
require_contains ".config/kdeglobals" '^BackgroundNormal=42,42,42$' "KDE selection background uses dark grey"
require_contains ".config/kdeglobals" '^ForegroundNormal=229,226,225$' "KDE selection text remains readable"
require_contains ".config/dolphinrc" '^OpenExternallyCalledFolderInNewTab=true$' "Dolphin keeps external folders in tabs"

require_contains ".local/bin/terminal-noir-zen-theme" 'userChrome\.css' "Zen theme helper writes browser chrome CSS"
require_contains ".local/bin/terminal-noir-zen-theme" 'ui.systemUsesDarkTheme' "Zen theme helper forces dark browser prefs"
require_contains ".local/bin/terminal-noir-zen-theme" '#141313' "Zen theme helper uses Terminal Noir background"

require_contains ".config/hypr/env.conf" 'QT_QPA_PLATFORMTHEME,qt6ct' "Hyprland exports Qt platform theme"
require_contains ".config/hypr/env.conf" 'QT_STYLE_OVERRIDE,kvantum' "Hyprland exports Kvantum style override"
require_contains ".config/hypr/env.conf" 'GTK_THEME,Adwaita:dark' "Hyprland exports GTK dark theme"
require_contains ".config/hypr/windowrules.conf" 'dolphin.*opacity' "Dolphin has app opacity rule"
require_contains ".config/hypr/windowrules.conf" 'pavucontrol.*opacity' "audio settings app has opacity rule"
require_contains ".config/hypr/windowrules.conf" 'qt5ct.*opacity' "Qt settings apps have opacity rule"

require_contains "scripts/sync-config.sh" '\.gtkrc-2\.0' "sync-config copies GTK2 root config"
require_contains "scripts/backup-config.sh" '\.gtkrc-2\.0' "backup includes GTK2 root config"
require_contains "scripts/uninstall.sh" '\.gtkrc-2\.0' "uninstall removes managed GTK2 root config"
require_contains "verify-rice.sh" '\.config/gtk-3\.0/settings\.ini' "verify-rice checks GTK theme config"
require_contains "verify-rice.sh" '\.config/qt5ct/qt5ct\.conf' "verify-rice checks Qt theme config"
require_contains "verify-rice.sh" '\.config/Kvantum/kvantum\.kvconfig' "verify-rice checks Kvantum config"

if [ "$fail_count" -gt 0 ]; then
    printf '\n%d app theming check(s) failed.\n' "$fail_count"
    exit 1
fi

printf '\nApp theming checks passed.\n'
