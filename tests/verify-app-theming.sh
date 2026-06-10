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

require_not_contains() {
    local path="$1"
    local pattern="$2"
    local label="$3"

    if [ ! -f "$repo_root/$path" ]; then
        fail "$path is missing for $label"
        return
    fi

    if grep -Eq -- "$pattern" "$repo_root/$path"; then
        fail "$label"
    else
        pass "$label"
    fi
}

for path in \
    ".config/gtk-3.0/settings.ini" \
    ".config/gtk-3.0/gtk.css" \
    ".config/gtk-4.0/settings.ini" \
    ".config/gtk-4.0/gtk.css" \
    ".gtkrc-2.0" \
    ".config/xsettingsd/xsettingsd.conf" \
    ".config/Trolltech.conf" \
    ".config/qt5ct/qt5ct.conf" \
    ".config/qt6ct/qt6ct.conf" \
    ".config/qt5ct/qss/terminal-noir.qss" \
    ".config/qt6ct/qss/terminal-noir.qss" \
    ".config/qt5ct/colors/terminal-noir.conf" \
    ".config/qt6ct/colors/terminal-noir.conf" \
    ".config/Kvantum/kvantum.kvconfig" \
    ".config/Kvantum/TerminalNoir/TerminalNoir.kvconfig" \
    ".local/share/color-schemes/TerminalNoir.colors" \
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
require_contains ".config/Trolltech.conf" '^Palette\\active=.*#141313.*#2a2a2a.*#e5e2e1' "Qt fallback palette uses Terminal Noir dark rows and light text"
require_contains ".config/Trolltech.conf" '^KWinPalette\\activeBackground=#141313$' "Qt fallback palette uses dark active window background"
require_not_contains ".config/Trolltech.conf" '#6c52a5|#926ee4|#2d2343|#b1aeae|#928c8c|#7b7575|#5a5656' "Qt fallback palette does not keep stale light or purple colors"

require_contains ".config/qt5ct/qt5ct.conf" '^style=kvantum$' "Qt5 uses Kvantum style"
require_contains ".config/qt6ct/qt6ct.conf" '^style=kvantum$' "Qt6 uses Kvantum style"
require_contains ".config/qt5ct/qt5ct.conf" 'terminal-noir\.conf' "Qt5 uses Terminal Noir color scheme"
require_contains ".config/qt6ct/qt6ct.conf" 'terminal-noir\.conf' "Qt6 uses Terminal Noir color scheme"
require_contains ".config/qt5ct/qt5ct.conf" 'terminal-noir\.qss' "Qt5 loads Terminal Noir stylesheet"
require_contains ".config/qt6ct/qt6ct.conf" 'terminal-noir\.qss' "Qt6 loads Terminal Noir stylesheet"
require_contains ".config/qt5ct/qss/terminal-noir.qss" 'QAbstractItemView|QTreeView' "Qt5 QSS targets item views"
require_contains ".config/qt6ct/qss/terminal-noir.qss" 'QAbstractItemView|QTreeView' "Qt6 QSS targets item views"
require_contains ".config/qt5ct/qss/terminal-noir.qss" 'alternate-background-color:[[:space:]]*transparent' "Qt5 QSS prevents light alternating Dolphin rows"
require_contains ".config/qt6ct/qss/terminal-noir.qss" 'alternate-background-color:[[:space:]]*transparent' "Qt6 QSS prevents light alternating Dolphin rows"
require_contains ".config/qt5ct/qss/terminal-noir.qss" 'selection-background-color:[[:space:]]*rgba\(42,[[:space:]]*42,[[:space:]]*42,' "Qt5 QSS keeps selection dark grey"
require_contains ".config/qt6ct/qss/terminal-noir.qss" 'selection-background-color:[[:space:]]*rgba\(42,[[:space:]]*42,[[:space:]]*42,' "Qt6 QSS keeps selection dark grey"
require_contains ".config/qt5ct/qss/terminal-noir.qss" 'color:[[:space:]]*#e5e2e1' "Qt5 QSS keeps Dolphin file text light"
require_contains ".config/qt6ct/qss/terminal-noir.qss" 'color:[[:space:]]*#e5e2e1' "Qt6 QSS keeps Dolphin file text light"
require_not_contains ".config/qt5ct/qss/terminal-noir.qss" '#fff|#ffffff|white' "Qt5 QSS does not define white backgrounds"
require_not_contains ".config/qt6ct/qss/terminal-noir.qss" '#fff|#ffffff|white' "Qt6 QSS does not define white backgrounds"
require_contains ".config/Kvantum/kvantum.kvconfig" '^theme=TerminalNoir$' "Kvantum selects Terminal Noir theme"
require_contains ".config/Kvantum/TerminalNoir/TerminalNoir.kvconfig" '^window\.color=#141313$' "Kvantum theme uses design background color"
require_contains ".config/Kvantum/TerminalNoir/TerminalNoir.kvconfig" '^highlight\.color=#2a2a2a$' "Kvantum selection uses dark grey"
require_contains ".config/Kvantum/TerminalNoir/TerminalNoir.kvconfig" '^highlight\.text\.color=#e5e2e1$' "Kvantum selected text remains readable"
require_contains ".config/Kvantum/TerminalNoir/TerminalNoir.kvconfig" '^transparent_dolphin_view=true$' "Kvantum lets Dolphin file view use compositor blur"
require_contains ".config/Kvantum/TerminalNoir/TerminalNoir.kvconfig" '^\[ItemView\]$' "Kvantum defines item-view rendering for Dolphin rows"
require_contains ".config/Kvantum/TerminalNoir/TerminalNoir.kvconfig" '^interior\.element=itemview$' "Kvantum item views use Terminal Noir itemview SVG elements"
require_contains ".config/Kvantum/TerminalNoir/TerminalNoir.kvconfig" '^text\.normal\.color=#e5e2e1$' "Kvantum item-view normal text is light"
require_contains ".config/Kvantum/TerminalNoir/TerminalNoir.kvconfig" '^text\.toggle\.color=#e5e2e1$' "Kvantum item-view selected text is light"
require_contains ".config/Kvantum/TerminalNoir/TerminalNoir.svg" 'id="itemview-normal".*fill:#141313|id="itemview-normal" class="item-base"' "Kvantum SVG defines dark normal item-view background"
require_contains ".config/Kvantum/TerminalNoir/TerminalNoir.svg" 'id="itemview-toggled".*fill:#2a2a2a|id="itemview-toggled" class="item-active"' "Kvantum SVG defines dark selected item-view background"
require_contains ".config/Kvantum/TerminalNoir/TerminalNoir.svg" 'id="itemview-focused".*fill:#1c1b1b|id="itemview-focused" class="item-focus"' "Kvantum SVG defines dark focused item-view background"
require_not_contains ".config/Kvantum/TerminalNoir/TerminalNoir.svg" 'id="itemview-[^"]*".*(#fff|#ffffff|white)' "Kvantum item-view SVG does not use white row backgrounds"
require_contains ".local/share/color-schemes/TerminalNoir.colors" '^ColorScheme=TerminalNoir$' "KDE color scheme id is Terminal Noir"
require_contains ".local/share/color-schemes/TerminalNoir.colors" '^Name=Terminal Noir$' "KDE color scheme has Terminal Noir name"
require_contains ".local/share/color-schemes/TerminalNoir.colors" '^BackgroundNormal=20,19,19$' "KDE color scheme view background uses dark surface"
require_contains ".local/share/color-schemes/TerminalNoir.colors" '^BackgroundNormal=42,42,42$' "KDE color scheme selection background uses dark grey"
require_contains ".local/share/color-schemes/TerminalNoir.colors" '^ForegroundNormal=229,226,225$' "KDE color scheme selected text remains readable"
require_contains ".local/share/color-schemes/TerminalNoir.colors" '\[Colors:Header\]' "KDE color scheme defines Dolphin header colors"
require_contains ".config/kdeglobals" '^TerminalApplication=kitty$' "KDE globals use kitty terminal"
require_contains ".config/kdeglobals" '^ColorScheme=TerminalNoir$' "KDE globals select Terminal Noir color scheme"
require_contains ".config/kdeglobals" '^widgetStyle=Breeze$' "KDE globals use the installed Breeze widget style"
require_contains ".config/kdeglobals" '^BackgroundAlternate=28,27,27$' "KDE view alternate rows use dark grey"
require_contains ".config/kdeglobals" '^BackgroundNormal=42,42,42$' "KDE selection background uses dark grey"
require_contains ".config/kdeglobals" '^ForegroundNormal=229,226,225$' "KDE selection text remains readable"
require_contains ".config/kdeglobals" '\[Colors:Header\]' "KDE globals define Dolphin header colors"
require_not_contains ".config/kdeglobals" '146,110,228|108,82,165|111,86,168' "KDE globals do not keep purple accent colors"
require_contains ".config/dolphinrc" '^OpenExternallyCalledFolderInNewTab=true$' "Dolphin keeps external folders in tabs"
require_contains ".config/dolphinrc" '^ColorScheme=TerminalNoir$' "Dolphin explicitly uses Terminal Noir color scheme"

require_contains ".local/bin/terminal-noir-zen-theme" 'userChrome\.css' "Zen theme helper writes browser chrome CSS"
require_contains ".local/bin/terminal-noir-zen-theme" 'ui.systemUsesDarkTheme' "Zen theme helper forces dark browser prefs"
require_contains ".local/bin/terminal-noir-zen-theme" '#141313' "Zen theme helper uses Terminal Noir background"

require_contains ".config/hypr/env.conf" 'QT_QPA_PLATFORMTHEME,kde' "Hyprland exports installed KDE Qt platform theme"
require_contains ".config/hypr/env.conf" 'QT_STYLE_OVERRIDE,Breeze' "Hyprland exports installed Breeze style override"
require_not_contains ".config/hypr/env.conf" 'QT_QPA_PLATFORMTHEME,qt6ct|QT_STYLE_OVERRIDE,kvantum' "Hyprland does not force missing qtct/Kvantum plugins"
require_contains ".config/hypr/env.conf" 'GTK_THEME,Adwaita:dark' "Hyprland exports GTK dark theme"
require_contains ".config/hypr/windowrules.conf" 'dolphin.*opacity' "Dolphin uses compositor opacity for blur visibility"
require_contains ".config/hypr/windowrules.conf" 'pavucontrol.*opacity' "audio settings app has opacity rule"
require_contains ".config/hypr/windowrules.conf" 'qt5ct.*opacity' "Qt settings apps have opacity rule"

require_contains "scripts/sync-config.sh" '\.gtkrc-2\.0' "sync-config copies GTK2 root config"
require_contains "scripts/sync-config.sh" '\.local/share/color-schemes/TerminalNoir\.colors' "sync-config copies KDE Terminal Noir color scheme without backing up all local share"
require_contains "scripts/sync-config.sh" 'terminal-noir\.qss' "sync-config rewrites qtct stylesheet paths for the target home"
require_contains "scripts/backup-config.sh" '\.gtkrc-2\.0' "backup includes GTK2 root config"
require_contains "scripts/backup-config.sh" '\.local/share/color-schemes/TerminalNoir\.colors' "backup includes KDE Terminal Noir color scheme"
require_contains "scripts/uninstall.sh" '\.gtkrc-2\.0' "uninstall removes managed GTK2 root config"
require_contains "scripts/uninstall.sh" '\.local/share/color-schemes/TerminalNoir\.colors' "uninstall removes KDE Terminal Noir color scheme"
require_contains "scripts/uninstall.sh" 'terminal-noir\.qss' "uninstall removes managed qtct stylesheet files"
require_contains "verify-rice.sh" '\.config/gtk-3\.0/settings\.ini' "verify-rice checks GTK theme config"
require_contains "verify-rice.sh" '\.config/qt5ct/qt5ct\.conf' "verify-rice checks Qt theme config"
require_contains "verify-rice.sh" '\.config/Kvantum/kvantum\.kvconfig' "verify-rice checks Kvantum config"
require_contains "verify-rice.sh" '\.local/share/color-schemes/TerminalNoir\.colors' "verify-rice checks KDE Terminal Noir color scheme"

if [ "$fail_count" -gt 0 ]; then
    printf '\n%d app theming check(s) failed.\n' "$fail_count"
    exit 1
fi

printf '\nApp theming checks passed.\n'
