#!/bin/bash
set -euo pipefail

# Create .icns file from PNG images
ICONSET="Resources/AppIcon.appiconset"
ICNS_OUTPUT="Resources/AppIcon.icns"

if [ ! -d "$ICONSET" ]; then
    echo "Error: Icon set not found at $ICONSET"
    exit 1
fi

echo "Creating macOS icon file (.icns)..."

# Create temporary iconset directory
TEMP_ICONSET="/tmp/AppIcon.iconset"
rm -rf "$TEMP_ICONSET"
mkdir -p "$TEMP_ICONSET"

# Copy and rename PNG files to match iconset naming convention
# macOS expects specific names like icon_16x16.png, icon_32x32.png, etc.
cp "$ICONSET/icon_16x16.png" "$TEMP_ICONSET/icon_16x16.png" 2>/dev/null || true
cp "$ICONSET/icon_16x16@2x.png" "$TEMP_ICONSET/icon_32x32.png" 2>/dev/null || true
cp "$ICONSET/icon_32x32.png" "$TEMP_ICONSET/icon_32x32.png" 2>/dev/null || true
cp "$ICONSET/icon_32x32@2x.png" "$TEMP_ICONSET/icon_64x64.png" 2>/dev/null || true
cp "$ICONSET/icon_128x128.png" "$TEMP_ICONSET/icon_128x128.png" 2>/dev/null || true
cp "$ICONSET/icon_128x128@2x.png" "$TEMP_ICONSET/icon_256x256.png" 2>/dev/null || true
cp "$ICONSET/icon_256x256.png" "$TEMP_ICONSET/icon_256x256.png" 2>/dev/null || true
cp "$ICONSET/icon_256x256@2x.png" "$TEMP_ICONSET/icon_512x512.png" 2>/dev/null || true
cp "$ICONSET/icon_512x512.png" "$TEMP_ICONSET/icon_512x512.png" 2>/dev/null || true
cp "$ICONSET/icon_512x512@2x.png" "$TEMP_ICONSET/icon_1024x1024.png" 2>/dev/null || true

# Create .icns file from the iconset
if command -v iconutil >/dev/null 2>&1; then
    iconutil -c icns "$TEMP_ICONSET" -o "$ICNS_OUTPUT"
    echo "✓ Created $ICNS_OUTPUT"
else
    echo "Warning: iconutil not found, using appiconset instead"
fi

# Cleanup
rm -rf "$TEMP_ICONSET"

echo "✓ Icon file creation complete!"
