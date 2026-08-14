#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
VERSION="0.6.3"
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

RELEASE_NOTES="Bob Select Helper v0.6.2

## Picking applications now works like the rest of macOS

Adding an app to the whitelist or blacklist used to mean typing its name into a text field,
with no icons and nothing to confirm you had picked the right thing.

The Applications tab now has the standard **+** and **-** buttons. **+** opens the normal
macOS file picker at /Applications, so you choose apps by their icon and name, and you can
select several at once. The list shows each app's real icon and display name. **-** removes
whatever you have selected.

An empty list also tells you what that means: an empty whitelist blocks the helper
everywhere, which is easy to do by accident.

## Also in 0.6.x

- **Menu-bar only by default.** A Dock icon makes the app take focus and replace the
  frontmost app's menu bar, which gets in the way of a tool that acts on selections made
  elsewhere. The Dock switch is still in Settings if you want it.
- A real Settings window with everything grouped under General / Appearance / Bob /
  Applications, instead of a bare filter list.
- English and 简体中文, switchable in the app, following your macOS language on first launch.
- Fixed a crash in the mouse-event monitor, which removed its own handler mid-callback.
- Lower overhead: drag events watched only during a drag, scroll events return immediately
  when nothing is showing, settings read from memory rather than UserDefaults per event.

## Install

1. Download the DMG
2. Open it and drag **Bob Select Helper** onto **Applications**
3. Launch it and grant Accessibility permission when asked
4. Look for the speech-bubble icon in the **menu bar**, top right

Quit any older copy first; one left running will mask the new one.

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
