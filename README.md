# Bob Select Helper 0.4.0

A lightweight, independent macOS menu-bar helper that recreates the useful part of Easydict's mouse-selection workflow and sends selected text to Bob.

## What's new in 0.4.0

- **English UI by default** - Fully translated interface with support for other languages
- **Application Filter Settings** - Control which applications can use the helper:
  - Allow All (default) - Works in all applications
  - Whitelist mode - Only listed apps can trigger the helper
  - Blacklist mode - All apps except listed ones can trigger the helper
- **Universal Binary** - Single release package supports both Intel and Apple Silicon Macs
- **Improved Distribution** - DMG and ZIP releases with checksums

## What's new in 0.3.0

- Added **Auto-launch with Bob** feature
- A small bundled login-item launcher waits silently in the background
- When macOS detects that Bob (`com.hezongyidev.Bob`) has launched, it opens Bob Select Helper without bringing anything to the foreground
- If Bob is already running when the launcher starts, Bob Select Helper opens immediately
- The feature can be turned on or off from the Bob Select Helper menu-bar menu

## Previous fixes

- Persistent Bob input-box setting: always unfold, follow current state, or always fold
- Hover/click trigger modes, delay, icon size, position, auto-hide, and Command-C fallback

## Requirements

- macOS 13 or later (Intel or Apple Silicon)
- Bob 1.5.0 or later
- Apple command-line developer tools (for development only)

Install the developer tools once if needed:

```bash
xcode-select --install
```

## Architecture Support

This project supports both Intel (x86_64) and Apple Silicon (arm64) Macs through universal binaries. A single release package works on all supported Macs without separate downloads.

## Installation from Release

1. Download the latest release from [GitHub Releases](https://github.com/le23967/BobSelectHelper/releases)
2. Open the DMG or extract the ZIP file
3. Drag **Bob Select Helper** to your **Applications** folder
4. Launch it from Applications
5. Grant Accessibility permissions when prompted

## Build and Install from Source

Open Terminal, type `cd ` with a trailing space, drag this folder into Terminal, press Return, then run:

```bash
./install.sh
```

The app is installed to:

```text
~/Applications/Bob Select Helper.app
```

The first launch registers the bundled launcher automatically. If macOS asks for approval, open **System Settings > General > Login Items & Extensions** and enable **Bob Select Helper Launcher**.

## Creating Release Builds

To build universal binaries for both Intel and Apple Silicon:

```bash
./release-build.sh
```

This creates DMG and ZIP releases in the `releases/` directory with:
- Universal binary (works on both architectures)
- Code signing
- SHA256 checksums

To publish to GitHub:

```bash
./create-release.sh
```

This requires GitHub CLI to be installed and authenticated.

## Menu Bar App

**Important:** Bob Select Helper is a menu bar app, not a Dock app.

- The app runs silently in the background
- Look for the icon in the **top-right menu bar** (next to system clock)
- The app does **not** appear in the Dock
- Click the menu bar icon to access settings

## Language Support

Bob Select Helper supports both **English** and **Chinese (简体中文)**.

To change the language, modify `Sources/Localization.swift`:
```swift
// Change this line:
Localization.current = .english  // Switch to .chinese
```

Then rebuild the app:
```bash
./release-build.sh
```

Available languages:
- **English** (.english)
- **Chinese Simplified** (.chinese)

## Menu-bar Settings

Click the icon in the **top-right menu bar** to access settings. You can change:

- Open Bob -> automatically start Bob Select Helper
- Bob input box: always unfold, follow current state, or always fold
- Trigger method: hover or click
- Hover delay
- Floating icon size and position
- Auto-hide duration
- Command-C fallback
- **Application Filter Settings**: Control which applications can trigger the helper

### Application Filter Modes

The Application Filter Settings window offers three modes:

- **Allow All**: The helper works in all applications (default)
- **Whitelist**: Only listed applications can use the helper
- **Blacklist**: All applications except listed ones can use the helper

To access the settings, click "Application Filter Settings" in the menu bar menu.

## First-run permissions

1. Allow Accessibility access for Bob Select Helper
2. When macOS asks whether Bob Select Helper may control Bob, choose **Allow**
3. If the auto-launch menu shows **"(Pending Approval)"**, open System Settings and enable **Bob Select Helper Launcher** in **General > Login Items & Extensions**

## Uninstall

1. Open Bob Select Helper and click the menu-bar icon
2. Turn off "Auto-launch with Bob"
3. Quit the helper
4. Delete the app from Applications folder:

```bash
rm -rf ~/Applications/Bob\ Select\ Helper.app
```
