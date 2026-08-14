# Bob Select Helper 0.6.3

A lightweight, independent macOS helper that recreates the useful part of Easydict's mouse-selection workflow and sends selected text to Bob.

## What's new in 0.6.3

- **Stops other selection tools flickering.** In apps that do not report their selection
  through Accessibility, such as Microsoft Word, the helper falls back to sending
  Command-C. That briefly disturbs the clipboard, and tools like PopClip that watch it
  would appear and vanish. The fallback no longer empties the clipboard first, cutting the
  pasteboard changes from three to two, and to none at all when the app ignores the copy.
- **Per-app Command-C exceptions.** Settings > Bob has a list of apps where Command-C is
  never sent. Add Word there and PopClip is left alone, while the helper keeps working
  normally everywhere else.

## What's new in 0.6.2

- **Pick applications from Finder.** The Applications tab now uses a standard `+` / `-` pair.
  `+` opens the normal macOS file picker at `/Applications`, so you choose apps by their
  real icon and name instead of typing a name into a text field. Multiple selection works.
- The list shows each app's **actual icon and display name**, resolved from the bundle
  identifier, with the raw identifier kept only as a tooltip.
- An empty list now explains what that means for the mode you are in.
- Removed the background scan of every installed application; it existed only to feed the
  old autocomplete.

## What's new in 0.6.1

- **Menu-bar only by default.** A Dock icon makes the app take focus and replace the
  frontmost app's menu bar when it activates, which works against a tool whose job is
  acting on a selection made somewhere else. The Dock switch is still there if you want it.

## What's new in 0.6.0

- **Dock icon is optional** - "Show icon in the Dock" in Settings, or in the menu-bar menu.
  Toggling it takes effect immediately, no restart, and the choice is remembered.
- **A real Settings window** - opening the app now shows what it does, whether Accessibility
  is granted, and every option grouped under General / Appearance / Bob / Applications,
  instead of dropping you straight into a bare filter list.
- **Fewer wakeups** - `leftMouseDragged` is only monitored between mouse-down and mouse-up
  rather than system-wide at all times, and scroll events return immediately when no icon
  is on screen.
- **Settings are read from memory** - values are loaded once at launch instead of hitting
  UserDefaults on every mouse event.
- **Fixed a crash** in the mouse-event monitor, which removed its own handler from inside
  its own callback.
- Application scanning reads `Info.plist` directly and runs once, in the background, only
  when the Applications tab is used.

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

- **Menu bar** - the `character.bubble` icon in the top-right. Always present, and holds
  the full settings menu. This is the app.
- **Dock** - off by default. Turn on **Show icon in the Dock** in Settings > General or in
  the menu-bar menu if you want one; clicking it then opens Settings.

Launching the app again from Applications reopens Settings, whether or not the Dock icon
is showing.

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
- Command-C fallback, with per-app exceptions
- Language (English / 简体中文)
- **Application Filter Settings**: Control which applications can trigger the helper

### Command-C and other selection tools

Some apps do not expose the selected text through Accessibility. For those the helper
sends Command-C, reads the clipboard, then puts the previous contents back. Other
selection tools that watch the clipboard can react to that and flicker.

If that happens, open **Settings > Bob** and add the app under **Never use Command-C in
these apps**. The helper still tries Accessibility there, and leaves the clipboard alone.

### Application filter

Under **Settings > Applications**:

- **Allow All** - the helper works everywhere (default)
- **Whitelist** - only the listed applications can use it
- **Blacklist** - every application except the listed ones can use it

Click **+** to pick applications with the normal macOS file picker, and **-** to remove the
selected ones. The list shows each app's own icon and name.

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
