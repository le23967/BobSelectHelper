# Bob Select Helper 0.5.3

A lightweight, independent macOS helper that recreates the useful part of Easydict's mouse-selection workflow and sends selected text to Bob.

## What's new in 0.5.3

- **Custom app icon** - a real `.icns` is now built and bundled, so the icon shows in
  Finder, the Dock, and System Settings
- **Shows in the Dock** - the activation policy is `regular`, so the app has a Dock icon
  and an application menu alongside its menu-bar icon
- **Language switching in the app** - pick English or 简体中文 from the menu; the choice is
  saved and applies immediately, with no rebuild
- Clicking the Dock icon opens Application Filter Settings

## What's new in 0.4.0

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

The app icon is generated from `Tools/GenerateIcon.swift`. `release-build.sh` builds
`Resources/AppIcon.icns` automatically if it is missing; to redraw it after editing the
generator, run:

```bash
./make-icon.sh
```

To publish to GitHub:

```bash
./create-release.sh
```

This requires GitHub CLI to be installed and authenticated.

## Where to find the app

Bob Select Helper is reachable in two places:

- **Dock** - the app has a normal Dock icon. Clicking it opens Application Filter Settings.
- **Menu bar** - the `character.bubble` icon in the top-right holds the full settings menu.

## Language

English and 简体中文 are both built in. Switch from the menu-bar icon under **Language**.
The choice is saved and takes effect straight away.

On first launch the app follows your macOS language: a system language starting with `zh`
selects Chinese, anything else selects English.

## Settings

Click the menu-bar icon to access settings. You can change:

- Open Bob -> automatically start Bob Select Helper
- Bob input box: always unfold, follow current state, or always fold
- Trigger method: hover or click
- Hover delay
- Floating icon size and position
- Auto-hide duration
- Command-C fallback
- Language (English / 简体中文)
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
