#!/bin/bash

# ===========================================================================
# RICE SYSTEM VERIFICATION SCRIPT (ARCH/ENDEAVOUR COMPATIBLE)
# ===========================================================================

echo "=========================================="
echo "Checking System Requirements..."
echo "=========================================="

FAIL_COUNT=0

# 1. Check Waybar version (must be >= 0.10)
if command -v waybar > /dev/null; then
    WAYBAR_VERSION=$(waybar --version | awk '{print $2}' | sed 's/v//')
    if [ "$(printf '%s\n' "0.10.0" "$WAYBAR_VERSION" | sort -V | head -n1)" = "0.10.0" ]; then
        echo "✅ PASS: Waybar version $WAYBAR_VERSION is 0.10.x+"
    else
        echo "❌ FAIL: Waybar version is $WAYBAR_VERSION (needs 0.10.x+)"
        echo "   FIX: sudo pacman -S waybar"
        ((FAIL_COUNT++))
    fi
else
    echo "❌ FAIL: Waybar is not installed"
    echo "   FIX: sudo pacman -S waybar"
    ((FAIL_COUNT++))
fi

# 2. Check JetBrains Mono Nerd Font
if fc-list | grep -i "JetBrains.*Nerd" > /dev/null; then
    echo "✅ PASS: JetBrains Mono Nerd Font detected"
else
    echo "❌ FAIL: JetBrains Mono Nerd Font missing"
    echo "   FIX: Run ./install_fonts.sh"
    ((FAIL_COUNT++))
fi

# 3. Check runtime tools used by the rice
for TOOL in quickshell rofi swaybg nmcli rfkill brightnessctl wpctl; do
    if command -v "$TOOL" > /dev/null; then
        TOOL_PATH=$(command -v "$TOOL")
        echo "✅ PASS: $TOOL found at $TOOL_PATH"
    else
        echo "❌ FAIL: $TOOL is not installed"
        case "$TOOL" in
            quickshell) echo "   FIX: yay -S quickshell-git" ;;
            rofi) echo "   FIX: sudo pacman -S rofi-wayland" ;;
            swaybg) echo "   FIX: sudo pacman -S swaybg" ;;
            nmcli) echo "   FIX: sudo pacman -S networkmanager" ;;
            rfkill) echo "   FIX: sudo pacman -S util-linux" ;;
            brightnessctl) echo "   FIX: sudo pacman -S brightnessctl" ;;
            wpctl) echo "   FIX: sudo pacman -S wireplumber" ;;
        esac
        ((FAIL_COUNT++))
    fi
done

# 4. Check pavucontrol fallback
if command -v pavucontrol > /dev/null; then
    PAVU_PATH=$(which pavucontrol)
    echo "✅ PASS: pavucontrol found at $PAVU_PATH"
else
    echo "❌ FAIL: pavucontrol not found"
    echo "   FIX: sudo pacman -S pavucontrol"
    ((FAIL_COUNT++))
fi

# 5. Check Quickshell helper scripts
for SCRIPT in "$PWD/.config/quickshell/hw_stats.sh" "$PWD/.config/quickshell/sw_stats.sh" "$PWD/.config/quickshell/control_state.sh"; do
    if [ -x "$SCRIPT" ]; then
        if "$SCRIPT" > /dev/null; then
            echo "✅ PASS: $(basename "$SCRIPT") runs"
        else
            echo "❌ FAIL: $(basename "$SCRIPT") exists but returned an error"
            ((FAIL_COUNT++))
        fi
    else
        echo "❌ FAIL: $(basename "$SCRIPT") is missing or not executable"
        ((FAIL_COUNT++))
    fi
done

# 6. Check Hyprland (hyprctl version)
if command -v hyprctl > /dev/null; then
    if hyprctl version > /dev/null 2>&1; then
        HYPR_VER=$(hyprctl version | grep -i "Tag:" | head -n 1 | awk '{print $2}')
        if [ -z "$HYPR_VER" ]; then
            HYPR_VER=$(hyprctl version | head -n 1)
        fi
        echo "✅ PASS: Hyprland is installed and running ($HYPR_VER)"
    else
        echo "❌ FAIL: hyprctl found, but cannot connect to Hyprland socket"
        echo "   FIX: Run this script from inside a Hyprland session."
        ((FAIL_COUNT++))
    fi
else
    echo "❌ FAIL: hyprctl command not found"
    echo "   FIX: sudo pacman -S hyprland"
    ((FAIL_COUNT++))
fi

echo "=========================================="
if [ $FAIL_COUNT -eq 0 ]; then
    echo "🎉 ALL CHECKS PASSED!"
else
    echo "⚠️ $FAIL_COUNT CHECK(S) FAILED. Apply fixes above."
fi
echo "=========================================="
