#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$ROOT/build/Bob Select Helper.app"
RELEASE_DIR="$ROOT/releases"
DMG_NAME="Bob-Select-Helper-v0.5.0.dmg"
DMG_PATH="$RELEASE_DIR/$DMG_NAME"
TEMP_DMG="$RELEASE_DIR/.temp.dmg"
MOUNT_POINT="/Volumes/Bob Select Helper"

if [ ! -d "$APP_DIR" ]; then
    echo "Error: App not found in $APP_DIR"
    echo "Please run ./release-build.sh first"
    exit 1
fi

echo "Creating DMG installer: $DMG_NAME"
echo "===================================="

mkdir -p "$RELEASE_DIR"

# Clean up any existing mount point
if [ -d "$MOUNT_POINT" ]; then
    hdiutil unmount "$MOUNT_POINT" 2>/dev/null || true
fi

# Remove old DMG if it exists
[ -f "$DMG_PATH" ] && rm "$DMG_PATH"
[ -f "$TEMP_DMG" ] && rm "$TEMP_DMG"

# Create temporary directory for DMG contents
TEMP_DIR="$RELEASE_DIR/.dmg-contents"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Copy app to temporary directory
echo "Preparing installer contents..."
ditto "$APP_DIR" "$TEMP_DIR/Bob Select Helper.app"

# Create a symbolic link to Applications folder
ln -s /Applications "$TEMP_DIR/Applications"

# Create a .DS_Store-like setup (for nice appearance)
# This sets up the window appearance without requiring tools
cat > "$TEMP_DIR/.background_info" << 'EOF'
The application has been copied to your Applications folder.
If you see this, the installation was successful.
You can now close this window and launch Bob Select Helper from Applications.
EOF

# Create DMG from the temporary directory
echo "Creating disk image..."
hdiutil create \
    -volname "Bob Select Helper" \
    -srcfolder "$TEMP_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH" 2>&1 | grep -v "^." || true

# Fix quarantine attribute that prevents drag-and-drop
echo "Fixing quarantine attribute..."
xattr -d com.apple.quarantine "$DMG_PATH" 2>/dev/null || true

# Verify DMG was created
if [ -f "$DMG_PATH" ]; then
    DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
    echo ""
    echo "✓ DMG created successfully: $DMG_NAME ($DMG_SIZE)"
    echo ""
    echo "Installation Instructions:"
    echo "  1. Open the DMG file"
    echo "  2. Drag 'Bob Select Helper' to the Applications folder"
    echo "  3. Close the DMG window"
    echo "  4. Launch Bob Select Helper from Applications"
    echo ""
else
    echo "Error: Failed to create DMG"
    exit 1
fi

# Cleanup
rm -rf "$TEMP_DIR"
[ -f "$TEMP_DMG" ] && rm "$TEMP_DMG"

echo "✓ Installation package ready!"
