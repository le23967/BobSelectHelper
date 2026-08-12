#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
VERSION="0.5.0"
RELEASE_DIR="$ROOT/releases"

if ! command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI (gh) is required but not installed."
    echo "Install it with: brew install gh"
    exit 1
fi

if [ ! -d "$RELEASE_DIR" ] || [ -z "$(ls -A "$RELEASE_DIR")" ]; then
    echo "Release artifacts not found in $RELEASE_DIR"
    echo "Please run ./release-build.sh first"
    exit 1
fi

echo "Creating GitHub Release v$VERSION"
echo "===================================="
echo ""

RELEASE_NOTES="Release v$VERSION - Professional Icon & Improved Installation

## Major Improvements in v0.5.0

- ✨ **Professional Custom Icon** - Beautiful icon for Dock, Finder, and Launchpad
- 🎯 **Fixed Installation** - Drag-and-drop to Applications now works perfectly
- 🔧 **Improved DMG** - Better installer with clear setup instructions
- 📱 **Universal Binary** - Optimized for both Intel and Apple Silicon

## Installation Instructions

### Using DMG (Recommended)
1. Download Bob-Select-Helper-v0.5.0.dmg
2. Double-click to open
3. Drag 'Bob Select Helper' to Applications
4. Launch from Applications

### Using ZIP
1. Download Bob-Select-Helper-v0.5.0.zip
2. Extract the archive
3. Move to Applications folder
4. Launch from Applications

## System Requirements

- macOS 13 or later (Ventura or newer)
- Bob 1.5.0 or later
- Universal binary for Intel (x86_64) and Apple Silicon (arm64)

## Key Features

### Application Filter Settings
- Allow All (default)
- Whitelist mode - only selected apps
- Blacklist mode - all except selected apps

### Complete English UI
- Full English localization
- Easy language switching
- Intuitive interface

### Universal Architecture Support
✅ Intel (x86_64) - Full native support
✅ Apple Silicon (arm64) - Full native support

**Note**: This universal binary automatically optimizes for your Mac's processor!

## Previous Features (v0.4.0)

- Application filter with three modes
- Complete English localization
- SHA256 checksums for security
"

DMG_FILE="$RELEASE_DIR/Bob-Select-Helper-v$VERSION.dmg"
ZIP_FILE="$RELEASE_DIR/Bob-Select-Helper-v$VERSION.zip"

echo "Creating release with:"
echo "  - DMG file: $DMG_FILE"
echo "  - ZIP file: $ZIP_FILE"
echo ""

if ! gh release view "v$VERSION" >/dev/null 2>&1; then
    gh release create "v$VERSION" \
        --title "Bob Select Helper v$VERSION" \
        --notes "$RELEASE_NOTES" \
        "$DMG_FILE" \
        "$ZIP_FILE" \
        "$RELEASE_DIR/SHA256SUMS"

    echo ""
    echo "========================================"
    echo "✓ Release v$VERSION created successfully!"
    echo ""
    echo "View it at:"
    gh release view "v$VERSION" --web || echo "https://github.com/le23967/BobSelectHelper/releases/tag/v$VERSION"
else
    echo "Release v$VERSION already exists."
    echo "Delete it first with: gh release delete v$VERSION"
fi
