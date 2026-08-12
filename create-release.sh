#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
VERSION="0.6.1"
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

RELEASE_NOTES="Bob Select Helper v0.6.1

## Menu-bar only by default

A Dock icon means the app takes focus when it activates, and its menu bar replaces the one
belonging to whatever app you were just in. For a tool whose entire job is acting on text
you selected somewhere else, that gets in the way. It also costs a permanent Dock slot and
a Cmd-Tab entry for something you open only to change a setting.

So a fresh install now runs from the menu bar alone. If you want a Dock icon, the switch is
still there under **Show icon in the Dock**, in Settings > General or in the menu-bar menu,
and it takes effect immediately. If you already set a preference in 0.6.0, it is kept.

Settings is reachable either way: from the menu-bar icon, or by launching the app again
from Applications.

## Everything from 0.6.0

- A real Settings window: what the app does, whether Accessibility is granted, and every
  option grouped under General / Appearance / Bob / Applications
- English and 简体中文, switchable in the app, following your macOS language on first launch
- Fixed a crash in the mouse-event monitor, which removed its own handler mid-callback
- Drag events watched only between mouse-down and mouse-up, not system-wide at all times
- Scroll events return immediately when no icon is showing
- Settings read from memory rather than UserDefaults on every mouse event
- Application list scanned once, in the background, only when that tab is opened

## Install

1. Download the DMG
2. Open it and drag **Bob Select Helper** onto **Applications**
3. Launch it and grant Accessibility permission when asked
4. Look for the speech-bubble icon in the **menu bar**, top right

Quit any older copy first. A previous version left running will mask the new one.

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
