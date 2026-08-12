#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Bob Select Helper"
SOURCE_APP="$ROOT/build/$APP_NAME.app"
DEST_DIR="$HOME/Applications"
DEST_APP="$DEST_DIR/$APP_NAME.app"

"$ROOT/build.sh"
mkdir -p "$DEST_DIR"
rm -rf "$DEST_APP"
ditto "$SOURCE_APP" "$DEST_APP"
xattr -cr "$DEST_APP" 2>/dev/null || true
open "$DEST_APP"

echo
printf 'Installed: %s\n' "$DEST_APP"
echo 'Grant Accessibility permission when prompted.'
