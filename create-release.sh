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

RELEASE_NOTES="Bob Select Helper v0.6.0

## You can hide the Dock icon now

Previous builds decided the Dock icon once at startup with no way to change it. There is
now a **Show icon in the Dock** switch in Settings > General, and in the menu-bar menu.
Turn it off and the Dock tile disappears straight away, no restart, and the app keeps
running from the menu bar. The setting is remembered.

## Opening the app makes sense now

Before, launching it dropped you into a bare list of application bundle IDs with no
explanation. The window now opens on a proper Settings screen: what the app does, whether
Accessibility is granted (with a button to fix it), and every option grouped under
**General**, **Appearance**, **Bob** and **Applications**.

Language is a normal setting too. Pick English or 简体中文 and the whole interface changes
immediately.

## Lighter and more stable

- Fixed a crash in the mouse-event monitor, which removed its own handler while that
  handler was still running.
- Drag events are only watched between mouse-down and mouse-up, not system-wide at all
  times.
- Scroll events return immediately when no icon is on screen; every tick used to do work.
- Settings are read from memory instead of hitting UserDefaults on every mouse event.
- The application list is scanned once, in the background, only when you open that tab.

Measured on an M-series Mac: idle 0% CPU, and memory stays flat across repeated opening
and closing of the settings window.

## Install

1. Download the DMG
2. Open it and drag **Bob Select Helper** onto **Applications**
3. Launch it and grant Accessibility permission when asked

Quit any older copy first. A previous version left running in /Applications will keep
running and mask the new one.

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
