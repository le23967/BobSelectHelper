#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ICONSET="$ROOT/.build-icon/AppIcon.iconset"
GENERATOR="$ROOT/.build-icon/GenerateIcon"
OUTPUT="$ROOT/Resources/AppIcon.icns"

rm -rf "$ROOT/.build-icon"
mkdir -p "$ROOT/.build-icon"

echo "Compiling icon generator"
xcrun swiftc -swift-version 5 -O \
    -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
    -framework AppKit \
    "$ROOT/Tools/GenerateIcon.swift" \
    -o "$GENERATOR"

echo "Rendering icon variants"
"$GENERATOR" "$ICONSET"

echo "Packing AppIcon.icns"
iconutil -c icns "$ICONSET" -o "$OUTPUT"

rm -rf "$ROOT/.build-icon"

echo "Wrote $OUTPUT"
