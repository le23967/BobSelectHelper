# Bob Select Helper 0.3.0

A lightweight, independent macOS menu-bar helper that recreates the useful part of Easydict's mouse-selection workflow and sends selected text to Bob.

## What's new in 0.3.0

- Added **打开 Bob 时自动启动**.
- A small bundled login-item launcher waits silently in the background.
- When macOS detects that Bob (`com.hezongyidev.Bob`) has launched, it opens Bob Select Helper without bringing anything to the foreground.
- If Bob is already running when the launcher starts, Bob Select Helper opens immediately.
- The feature can be turned on or off from the Bob Select Helper menu-bar menu.
- On some macOS installations, the first registration shows **待系统允许**. Open **System Settings > General > Login Items & Extensions** and allow **Bob Select Helper Launcher** under background items.

This is different from simply launching Bob Select Helper at login: the launcher stays silent and starts the visible helper only after Bob is running.

## Previous fixes

- Persistent Bob input-box setting: always unfold, follow current state, or always fold.
- Hover/click trigger modes, delay, icon size, position, auto-hide, and Command-C fallback.
- **Application Filter Settings**: Control which applications can use the helper with whitelist or blacklist modes.

## Requirements

- macOS 13 or later
- Bob 1.5.0 or later
- Apple command-line developer tools

Install the developer tools once if needed:

```bash
xcode-select --install
```

## Build and install

Open Terminal, type `cd ` with a trailing space, drag this folder into Terminal, press Return, then run:

```bash
./install.sh
```

The app is installed to:

```text
~/Applications/Bob Select Helper.app
```

The first launch registers the bundled launcher automatically. If macOS asks for approval, choose **打开登录项设置**, then enable **Bob Select Helper Launcher**.

## Menu-bar settings

Click the `character.bubble` icon in the macOS menu bar. You can change:

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

1. Allow Accessibility access for Bob Select Helper.
2. When macOS asks whether Bob Select Helper may control Bob, choose Allow.
3. If the auto-launch menu says **待系统允许**, enable Bob Select Helper Launcher in Login Items.

## Uninstall

First turn off **打开 Bob 时自动启动** from the menu, then quit the helper and delete:

```text
~/Applications/Bob Select Helper.app
```
