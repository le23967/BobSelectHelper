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

RELEASE_NOTES="Bob Select Helper v0.6.3

## Fixes PopClip flickering in Word

Word does not report its selection through Accessibility, so the helper falls back to
sending Command-C and reading the clipboard. That fallback used to **empty** the clipboard
first, so anything watching it saw it go blank, fill, then revert. PopClip watches the
clipboard, and also sends its own Command-C in apps like Word, so it appeared and vanished
on every selection.

The clipboard is no longer emptied. The helper compares the change count across the copy
instead, so:

- the clipboard is never blank at any point
- pasteboard changes drop from **three to two** per selection
- an app that ignores the synthetic copy now causes **none at all**, where it previously
  still triggered a clear and a restore

Your clipboard contents are preserved exactly as before.

## Per-app Command-C exceptions

If a conflict remains, **Settings > Bob** now has **Never use Command-C in these apps**.
Add an app with the same Finder picker used elsewhere, and the helper will never send
Command-C there. It still reads the selection through Accessibility, so listing Word hands
its clipboard entirely to PopClip while the helper keeps working normally everywhere else.

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
