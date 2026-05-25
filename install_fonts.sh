#!/bin/bash

# ===========================================================================
# JETBRAINS MONO NERD FONT INSTALLER
# ===========================================================================

FONT_NAME="JetBrainsMono"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"
FONT_DIR="$HOME/.local/share/fonts/${FONT_NAME}"
ZIP_FILE="/tmp/${FONT_NAME}.zip"

echo "=========================================="
echo "Installing ${FONT_NAME} Nerd Font..."
echo "=========================================="

# 1. Download the font zip file
echo "[1/4] Downloading latest release from GitHub..."
wget -q --show-progress -O "$ZIP_FILE" "$FONT_URL"

if [ $? -ne 0 ]; then
    echo "❌ Download failed. Please check your internet connection."
    exit 1
fi

# 2. Extract and install to ~/.local/share/fonts/
echo "[2/4] Installing to ${FONT_DIR}..."
mkdir -p "$FONT_DIR"
# Unzip quietly, overwrite existing, drop into target directory
unzip -q -o "$ZIP_FILE" -d "$FONT_DIR"

# Clean up the zip file
rm "$ZIP_FILE"

# 3. Update the font cache
echo "[3/4] Updating font cache (fc-cache)..."
fc-cache -fv "$FONT_DIR" > /dev/null

# 4. Verify installation
echo "[4/4] Verifying installation..."
echo "------------------------------------------"
# Check if fc-list outputs anything for JetBrains
if fc-list | grep -i "JetBrains.*Nerd" > /dev/null; then
    echo "✅ SUCCESS! Font detected in system:"
    fc-list | grep -i "JetBrains.*Nerd" | head -n 3
    echo "... (and more)"
else
    echo "❌ WARNING: Font was not detected by fc-list."
    echo "Try logging out and logging back in, or running fc-cache -fv manually."
fi
echo "=========================================="
