#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
VERSION="0.4.0"
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

RELEASE_NOTES="Release v$VERSION

## Features

- Application Filter Settings: Control which applications can use the helper
  - Allow All (default)
  - Whitelist mode
  - Blacklist mode
- Fully localized in English with support for other languages
- Universal binary supporting both Intel and Apple Silicon Macs

## Downloads

- **Intel (x86_64)**: Included in universal binary
- **Apple Silicon (arm64)**: Included in universal binary

## Installation

1. Download either the DMG or ZIP file
2. Open the DMG or extract the ZIP
3. Drag Bob Select Helper to your Applications folder
4. Launch it and grant Accessibility permissions when prompted

## Requirements

- macOS 11 or later
- Bob 1.5.0 or later

## What's Changed

- Added application filter UI with easy add/remove interface
- Updated all UI text to English (configurable for other languages)
- Improved release packaging with universal binaries
- Added SHA256 checksums for all release artifacts

**Note**: This release includes a universal binary that runs natively on both Intel and Apple Silicon Macs. No separate downloads needed!
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
