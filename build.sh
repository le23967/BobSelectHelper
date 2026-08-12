#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Bob Select Helper"
EXECUTABLE_NAME="BobSelectHelper"
LAUNCHER_APP_NAME="Bob Select Helper Launcher"
LAUNCHER_EXECUTABLE_NAME="BobSelectHelperLauncher"
BUILD_DIR="$ROOT/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"
LOGIN_ITEMS_DIR="$CONTENTS/Library/LoginItems"
LAUNCHER_APP_DIR="$LOGIN_ITEMS_DIR/$LAUNCHER_APP_NAME.app"
LAUNCHER_CONTENTS="$LAUNCHER_APP_DIR/Contents"
LAUNCHER_MACOS_DIR="$LAUNCHER_CONTENTS/MacOS"
LAUNCHER_RESOURCES_DIR="$LAUNCHER_CONTENTS/Resources"

if ! command -v xcrun >/dev/null 2>&1; then
    echo "Apple developer command-line tools are required."
    echo "Run: xcode-select --install"
    exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
mkdir -p "$LAUNCHER_MACOS_DIR" "$LAUNCHER_RESOURCES_DIR"

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
SOURCES=("$ROOT"/Sources/*.swift)
LAUNCHER_SOURCES=("$ROOT"/LauncherSources/*.swift)

xcrun swiftc \
    -swift-version 5 \
    -O \
    -whole-module-optimization \
    -sdk "$SDK_PATH" \
    -framework AppKit \
    -framework ApplicationServices \
    -framework Carbon \
    -framework ServiceManagement \
    "${SOURCES[@]}" \
    -o "$MACOS_DIR/$EXECUTABLE_NAME"

xcrun swiftc \
    -swift-version 5 \
    -O \
    -whole-module-optimization \
    -sdk "$SDK_PATH" \
    -framework AppKit \
    "${LAUNCHER_SOURCES[@]}" \
    -o "$LAUNCHER_MACOS_DIR/$LAUNCHER_EXECUTABLE_NAME"

cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"
cp "$ROOT/LauncherResources/Info.plist" "$LAUNCHER_CONTENTS/Info.plist"
chmod +x "$MACOS_DIR/$EXECUTABLE_NAME"
chmod +x "$LAUNCHER_MACOS_DIR/$LAUNCHER_EXECUTABLE_NAME"

codesign --force --deep --sign - "$LAUNCHER_APP_DIR" >/dev/null
codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo
printf 'Built: %s\n' "$APP_DIR"
printf 'Next: open "%s"\n' "$APP_DIR"
