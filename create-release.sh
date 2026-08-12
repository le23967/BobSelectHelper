#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
VERSION="0.6.0"
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

RELEASE_NOTES="Bob Select Helper v0.5.3

Fixes the three things that were broken in 0.5.0 through 0.5.2.

## The app icon now works

Earlier builds shipped an \`.appiconset\`, which is an Xcode source format. It has to be
compiled into an \`Assets.car\` to mean anything, so the bundle effectively had no icon and
macOS fell back to the blank placeholder. The icon is now generated as a real \`.icns\` and
referenced through \`CFBundleIconFile\`, so it shows in Finder, the Dock, and System Settings.

## The app now appears in the Dock

Setting \`LSUIElement\` in Info.plist had no effect because the code called
\`setActivationPolicy(.accessory)\`, which wins. The policy is now \`regular\`: the app has a
Dock icon and an application menu, and clicking the Dock icon opens Application Filter
Settings. The menu-bar icon is unchanged and still holds the full settings menu.

## Chinese now actually works

The localization file existed but nothing referenced it, so the UI stayed English. It is now
wired into the menus and the settings window. Choose **Language > English / 简体中文** from
the menu-bar icon; the choice is saved and applies immediately. First launch follows your
macOS language.

## Install

1. Download the DMG
2. Open it and drag **Bob Select Helper** onto **Applications**
3. Launch it from Applications and grant Accessibility permission when asked

If you installed an earlier version, quit it first, then replace it. The old copy in
\`/Applications\` keeps running until you quit it and will otherwise mask the new one.

## Requirements

macOS 13 or later. Universal binary: Intel (x86_64) and Apple Silicon (arm64).
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
