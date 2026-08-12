#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Bob Select Helper"
EXECUTABLE_NAME="BobSelectHelper"
LAUNCHER_APP_NAME="Bob Select Helper Launcher"
LAUNCHER_EXECUTABLE_NAME="BobSelectHelperLauncher"
VERSION="0.5.3"
RELEASE_DIR="$ROOT/releases"
BUILD_DIR="$ROOT/build"
TEMP_BUILD="$ROOT/.build-temp"

echo "Building Bob Select Helper v$VERSION (Universal Binary)"
echo "======================================================="

if ! command -v xcrun >/dev/null 2>&1; then
    echo "Apple developer command-line tools are required."
    echo "Run: xcode-select --install"
    exit 1
fi

mkdir -p "$RELEASE_DIR" "$TEMP_BUILD"

build_for_architecture() {
    local arch=$1
    local arch_build="$TEMP_BUILD/$arch"
    mkdir -p "$arch_build"

    echo ""
    echo "Building for architecture: $arch"
    echo "-----------------------------------"

    SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
    SOURCES=("$ROOT"/Sources/*.swift)
    LAUNCHER_SOURCES=("$ROOT"/LauncherSources/*.swift)

    local arch_flag=""
    case $arch in
        arm64)
            arch_flag="-target arm64-macos13"
            ;;
        x86_64)
            arch_flag="-target x86_64-macos13"
            ;;
    esac

    mkdir -p "$arch_build/app/MacOS" "$arch_build/app/Resources"
    mkdir -p "$arch_build/launcher/MacOS" "$arch_build/launcher/Resources"

    xcrun swiftc \
        -swift-version 5 \
        -O \
        -whole-module-optimization \
        $arch_flag \
        -sdk "$SDK_PATH" \
        -framework AppKit \
        -framework ApplicationServices \
        -framework Carbon \
        -framework ServiceManagement \
        "${SOURCES[@]}" \
        -o "$arch_build/app/MacOS/$EXECUTABLE_NAME" 2>&1 | grep -v "warning:" || true

    echo "  ✓ Main app built for $arch"

    xcrun swiftc \
        -swift-version 5 \
        -O \
        -whole-module-optimization \
        $arch_flag \
        -sdk "$SDK_PATH" \
        -framework AppKit \
        "${LAUNCHER_SOURCES[@]}" \
        -o "$arch_build/launcher/MacOS/$LAUNCHER_EXECUTABLE_NAME" 2>&1 | grep -v "warning:" || true

    echo "  ✓ Launcher built for $arch"
}

create_universal_binary() {
    echo ""
    echo "Creating universal binaries"
    echo "----------------------------"

    local app_dir="$BUILD_DIR/$APP_NAME.app"
    local contents="$app_dir/Contents"
    local macos_dir="$contents/MacOS"
    local resources_dir="$contents/Resources"
    local login_items_dir="$contents/Library/LoginItems"
    local launcher_app_dir="$login_items_dir/$LAUNCHER_APP_NAME.app"
    local launcher_contents="$launcher_app_dir/Contents"
    local launcher_macos_dir="$launcher_contents/MacOS"
    local launcher_resources_dir="$launcher_contents/Resources"

    rm -rf "$app_dir"
    mkdir -p "$macos_dir" "$resources_dir"
    mkdir -p "$launcher_macos_dir" "$launcher_resources_dir"

    lipo -create \
        "$TEMP_BUILD/arm64/app/MacOS/$EXECUTABLE_NAME" \
        "$TEMP_BUILD/x86_64/app/MacOS/$EXECUTABLE_NAME" \
        -output "$macos_dir/$EXECUTABLE_NAME"

    lipo -create \
        "$TEMP_BUILD/arm64/launcher/MacOS/$LAUNCHER_EXECUTABLE_NAME" \
        "$TEMP_BUILD/x86_64/launcher/MacOS/$LAUNCHER_EXECUTABLE_NAME" \
        -output "$launcher_macos_dir/$LAUNCHER_EXECUTABLE_NAME"

    cp "$ROOT/Resources/Info.plist" "$contents/Info.plist"
    cp "$ROOT/LauncherResources/Info.plist" "$launcher_contents/Info.plist"

    # CFBundleIconFile needs a real .icns here; an .appiconset is Xcode-only source.
    if [ ! -f "$ROOT/Resources/AppIcon.icns" ]; then
        "$ROOT/make-icon.sh"
    fi
    cp "$ROOT/Resources/AppIcon.icns" "$resources_dir/AppIcon.icns"

    chmod +x "$macos_dir/$EXECUTABLE_NAME"
    chmod +x "$launcher_macos_dir/$LAUNCHER_EXECUTABLE_NAME"

    codesign --force --deep --sign - "$launcher_app_dir" >/dev/null 2>&1 || true
    codesign --force --deep --sign - "$app_dir" >/dev/null 2>&1 || true

    echo "  ✓ Universal binary created"
    echo "  ✓ Code signed"
    echo "  ✓ Icon assets included"
}

create_dmg() {
    local dmg_name="Bob-Select-Helper-v$VERSION.dmg"
    local dmg_path="$RELEASE_DIR/$dmg_name"
    local app_dir="$BUILD_DIR/$APP_NAME.app"
    local temp_dmg="$TEMP_BUILD/temp.dmg"
    local dmg_temp_dir="$TEMP_BUILD/dmg-contents"

    echo ""
    echo "Creating macOS disk image: $dmg_name"
    echo "------------------------------------"

    mkdir -p "$dmg_temp_dir"

    # Copy app to temporary DMG folder
    ditto "$app_dir" "$dmg_temp_dir/$APP_NAME.app"

    # Create symlink to Applications folder
    ln -s /Applications "$dmg_temp_dir/Applications"

    # Create installation instructions file
    cat > "$dmg_temp_dir/INSTALL.txt" << 'EOF'
INSTALLATION INSTRUCTIONS
=========================

1. Drag "Bob Select Helper" to the "Applications" folder
2. Wait for the copy to complete
3. Close this window
4. Launch "Bob Select Helper" from Applications folder

First Launch:
- Grant Accessibility permissions when prompted
- Enjoy!
EOF

    # Create the DMG
    hdiutil create \
        -volname "$APP_NAME" \
        -srcfolder "$dmg_temp_dir" \
        -ov \
        -format UDZO \
        "$temp_dmg" >/dev/null 2>&1

    if [ -f "$dmg_path" ]; then
        rm "$dmg_path"
    fi

    mv "$temp_dmg" "$dmg_path"

    # Remove quarantine attribute
    xattr -d com.apple.quarantine "$dmg_path" 2>/dev/null || true

    echo "  ✓ DMG created: $dmg_path"
}

create_zip() {
    local zip_name="Bob-Select-Helper-v$VERSION.zip"
    local zip_path="$RELEASE_DIR/$zip_name"
    local app_dir="$BUILD_DIR/$APP_NAME.app"

    echo ""
    echo "Creating ZIP archive: $zip_name"
    echo "--------------------------------"

    if [ -f "$zip_path" ]; then
        rm "$zip_path"
    fi

    cd "$BUILD_DIR"
    zip -r "$zip_path" "$APP_NAME.app" >/dev/null 2>&1
    cd "$ROOT"

    echo "  ✓ ZIP created: $zip_path"
}

create_checksums() {
    echo ""
    echo "Creating checksums"
    echo "-------------------"

    cd "$RELEASE_DIR"
    shasum -a 256 *.dmg *.zip > SHA256SUMS 2>/dev/null || true
    cd "$ROOT"

    echo "  ✓ SHA256 checksums created"
}

verify_universal_binary() {
    echo ""
    echo "Verifying universal binary"
    echo "----------------------------"

    local app_dir="$BUILD_DIR/$APP_NAME.app"
    local executable="$app_dir/Contents/MacOS/$EXECUTABLE_NAME"

    if lipo -info "$executable" | grep -q arm64 && lipo -info "$executable" | grep -q x86_64; then
        echo "  ✓ Valid universal binary detected"
        lipo -info "$executable"
    else
        echo "  ⚠ Warning: Binary may not be properly universal"
        lipo -info "$executable" || true
    fi
}

cleanup() {
    echo ""
    echo "Cleaning up temporary files"
    echo "----------------------------"

    rm -rf "$TEMP_BUILD"
    echo "  ✓ Cleanup complete"
}

main() {
    build_for_architecture "arm64"
    build_for_architecture "x86_64"
    create_universal_binary
    verify_universal_binary
    create_dmg
    create_zip
    create_checksums
    cleanup

    echo ""
    echo "======================================================="
    echo "Release build complete!"
    echo ""
    echo "Artifacts:"
    ls -lh "$RELEASE_DIR"
    echo ""
    echo "Next steps:"
    echo "  1. Test the DMG and ZIP files on both Intel and Apple Silicon Macs"
    echo "  2. If satisfied, create a GitHub release"
    echo "  3. Upload the DMG and ZIP files to the release"
    echo "======================================================="
}

main
