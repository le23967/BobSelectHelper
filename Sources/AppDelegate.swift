import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var selectionController: SelectionController!
    private let settings = Settings.shared
    private let bobAutoLaunchService = BobAutoLaunchService.shared
    private var appListManager: AppListManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()

        selectionController = SelectionController()
        selectionController.onError = { [weak self] error in
            self?.showError(error)
        }
        selectionController.start()

        if !AccessibilitySupport.isTrusted {
            AccessibilitySupport.requestPermission()
        }

        if !settings.didConfigureBobAutoLaunch {
            settings.didConfigureBobAutoLaunch = true
            enableBobAutoLaunch(showApprovalPrompt: true)
        }

        if !settings.didShowWelcome {
            settings.didShowWelcome = true
            showWelcome()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "character.bubble",
            accessibilityDescription: "Bob Select Helper"
        )
        statusItem.button?.toolTip = "Bob Select Helper"

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let enabled = NSMenuItem(title: "Enable Helper", action: #selector(toggleEnabled), keyEquivalent: "")
        enabled.target = self
        enabled.state = settings.isEnabled ? .on : .off
        menu.addItem(enabled)

        menu.addItem(.separator())

        let triggerMenu = NSMenu()
        let hover = NSMenuItem(title: "Translate on Hover", action: #selector(useHoverMode), keyEquivalent: "")
        hover.target = self
        hover.state = settings.activationMode == .hover ? .on : .off
        triggerMenu.addItem(hover)

        let click = NSMenuItem(title: "Translate on Click", action: #selector(useClickMode), keyEquivalent: "")
        click.target = self
        click.state = settings.activationMode == .click ? .on : .off
        triggerMenu.addItem(click)

        let triggerItem = NSMenuItem(title: "Trigger Method", action: nil, keyEquivalent: "")
        triggerItem.submenu = triggerMenu
        menu.addItem(triggerItem)

        let inputBoxMenu = NSMenu()
        addInputBoxStateItem("Always Expand Input Box", value: .alwaysUnfold, to: inputBoxMenu)
        addInputBoxStateItem("Follow Bob's State", value: .last, to: inputBoxMenu)
        addInputBoxStateItem("Always Collapse Input Box", value: .alwaysFold, to: inputBoxMenu)
        let inputBoxItem = NSMenuItem(title: "Bob Input Box", action: nil, keyEquivalent: "")
        inputBoxItem.submenu = inputBoxMenu
        menu.addItem(inputBoxItem)

        let delayMenu = NSMenu()
        addDelayItem("Immediate", value: 0.0, to: delayMenu)
        addDelayItem("Fast (0.12s)", value: 0.12, to: delayMenu)
        addDelayItem("Balanced (0.22s)", value: 0.22, to: delayMenu)
        addDelayItem("Slow (0.40s)", value: 0.40, to: delayMenu)
        addDelayItem("Very Slow (0.70s)", value: 0.70, to: delayMenu)
        let delayItem = NSMenuItem(title: "Hover Delay", action: nil, keyEquivalent: "")
        delayItem.submenu = delayMenu
        delayItem.isEnabled = settings.activationMode == .hover
        menu.addItem(delayItem)

        let sizeMenu = NSMenu()
        addSizeItem("Small (26px)", value: 26, to: sizeMenu)
        addSizeItem("Smaller (30px)", value: 30, to: sizeMenu)
        addSizeItem("Default (34px)", value: 34, to: sizeMenu)
        addSizeItem("Larger (40px)", value: 40, to: sizeMenu)
        addSizeItem("Large (48px)", value: 48, to: sizeMenu)
        addSizeItem("Extra Large (56px)", value: 56, to: sizeMenu)
        let sizeItem = NSMenuItem(title: "Icon Size", action: nil, keyEquivalent: "")
        sizeItem.submenu = sizeMenu
        menu.addItem(sizeItem)

        let positionMenu = NSMenu()
        addPositionItem("Bottom Right", value: .belowRight, to: positionMenu)
        addPositionItem("Top Right", value: .aboveRight, to: positionMenu)
        addPositionItem("Bottom Left", value: .belowLeft, to: positionMenu)
        addPositionItem("Top Left", value: .aboveLeft, to: positionMenu)
        let positionItem = NSMenuItem(title: "Icon Position", action: nil, keyEquivalent: "")
        positionItem.submenu = positionMenu
        menu.addItem(positionItem)

        let hideMenu = NSMenu()
        addAutoHideItem("2 seconds", value: 2, to: hideMenu)
        addAutoHideItem("5 seconds", value: 5, to: hideMenu)
        addAutoHideItem("10 seconds", value: 10, to: hideMenu)
        addAutoHideItem("Never Auto-hide", value: 0, to: hideMenu)
        let hideItem = NSMenuItem(title: "Auto-hide Duration", action: nil, keyEquivalent: "")
        hideItem.submenu = hideMenu
        menu.addItem(hideItem)

        menu.addItem(.separator())

        let autoLaunchStatus = bobAutoLaunchService.status
        let autoLaunchTitle: String
        switch autoLaunchStatus {
        case .requiresApproval:
            autoLaunchTitle = "Auto-launch with Bob (Pending Approval)"
        default:
            autoLaunchTitle = "Auto-launch with Bob"
        }

        let autoLaunch = NSMenuItem(title: autoLaunchTitle, action: #selector(toggleBobAutoLaunch), keyEquivalent: "")
        autoLaunch.target = self
        switch autoLaunchStatus {
        case .enabled:
            autoLaunch.state = .on
        case .requiresApproval:
            autoLaunch.state = .mixed
        case .notRegistered, .notFound:
            autoLaunch.state = .off
        @unknown default:
            autoLaunch.state = .off
        }
        menu.addItem(autoLaunch)

        if autoLaunchStatus == .requiresApproval {
            let loginItems = NSMenuItem(title: "Open Login Items and Allow", action: #selector(openLoginItemsSettings), keyEquivalent: "")
            loginItems.target = self
            menu.addItem(loginItems)
        }

        let fallback = NSMenuItem(title: "Use Command-C Fallback", action: #selector(toggleCopyFallback), keyEquivalent: "")
        fallback.target = self
        fallback.state = settings.copyFallbackEnabled ? .on : .off
        menu.addItem(fallback)

        let appFilter = NSMenuItem(title: "Application Filter Settings", action: #selector(openAppListManager), keyEquivalent: "")
        appFilter.target = self
        menu.addItem(appFilter)

        let permission = NSMenuItem(title: "Open Accessibility Permissions", action: #selector(requestAccessibility), keyEquivalent: "")
        permission.target = self
        menu.addItem(permission)

        let test = NSMenuItem(title: "Test Bob Connection", action: #selector(testBob), keyEquivalent: "")
        test.target = self
        menu.addItem(test)

        menu.addItem(.separator())

        let about = NSMenuItem(title: "Instructions", action: #selector(showWelcomeFromMenu), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: "Quit Bob Select Helper", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    private func addDelayItem(_ title: String, value: TimeInterval, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: #selector(setHoverDelay(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = NSNumber(value: value)
        item.state = abs(settings.hoverDelay - value) < 0.01 ? .on : .off
        menu.addItem(item)
    }

    private func addSizeItem(_ title: String, value: CGFloat, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: #selector(setIconSize(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = NSNumber(value: Double(value))
        item.state = abs(settings.iconSize - value) < 0.5 ? .on : .off
        menu.addItem(item)
    }

    private func addPositionItem(_ title: String, value: PanelPosition, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: #selector(setPanelPosition(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = value.rawValue
        item.state = settings.panelPosition == value ? .on : .off
        menu.addItem(item)
    }

    private func addAutoHideItem(_ title: String, value: TimeInterval, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: #selector(setAutoHideDelay(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = NSNumber(value: value)
        item.state = abs(settings.autoHideDelay - value) < 0.01 ? .on : .off
        menu.addItem(item)
    }

    private func addInputBoxStateItem(_ title: String, value: InputBoxState, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: #selector(setInputBoxState(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = value.rawValue
        item.state = settings.inputBoxState == value ? .on : .off
        menu.addItem(item)
    }

    @objc private func toggleEnabled() {
        settings.isEnabled.toggle()
    }

    @objc private func useHoverMode() {
        settings.activationMode = .hover
    }

    @objc private func useClickMode() {
        settings.activationMode = .click
    }

    @objc private func setHoverDelay(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? NSNumber else { return }
        settings.hoverDelay = value.doubleValue
    }

    @objc private func setIconSize(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? NSNumber else { return }
        settings.iconSize = CGFloat(value.doubleValue)
    }

    @objc private func setPanelPosition(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let position = PanelPosition(rawValue: raw)
        else { return }
        settings.panelPosition = position
    }

    @objc private func setAutoHideDelay(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? NSNumber else { return }
        settings.autoHideDelay = value.doubleValue
    }

    @objc private func setInputBoxState(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let state = InputBoxState(rawValue: raw)
        else { return }
        settings.inputBoxState = state
    }

    @objc private func toggleBobAutoLaunch() {
        if bobAutoLaunchService.isEnabledOrPendingApproval {
            bobAutoLaunchService.disable { [weak self] error in
                if let error {
                    self?.showError(error)
                }
            }
        } else {
            enableBobAutoLaunch(showApprovalPrompt: true)
        }
    }

    @objc private func openLoginItemsSettings() {
        bobAutoLaunchService.openLoginItemsSettings()
    }

    @objc private func toggleCopyFallback() {
        settings.copyFallbackEnabled.toggle()
    }

    @objc private func requestAccessibility() {
        AccessibilitySupport.requestPermission()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func testBob() {
        selectionController.testBob()
    }

    @objc private func openAppListManager() {
        if appListManager?.window?.isVisible == true {
            appListManager?.window?.makeKeyAndOrderFront(nil)
        } else {
            appListManager = AppListManager()
            appListManager?.window?.makeKeyAndOrderFront(nil)
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    @objc private func showWelcomeFromMenu() {
        showWelcome()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func enableBobAutoLaunch(showApprovalPrompt: Bool) {
        do {
            try bobAutoLaunchService.enable()

            if showApprovalPrompt, bobAutoLaunchService.status == .requiresApproval {
                NSApplication.shared.activate(ignoringOtherApps: true)
                let alert = NSAlert()
                alert.messageText = “Allow Auto-launch with Bob”
                alert.informativeText = “macOS has registered Bob Select Helper Launcher, but you need to allow it to run in the background in System Settings > General > Login Items & Extensions. Bob Select Helper will automatically launch when you open Bob.”
                alert.alertStyle = .informational
                alert.addButton(withTitle: “Open Login Items”)
                alert.addButton(withTitle: “Later”)
                if alert.runModal() == .alertFirstButtonReturn {
                    bobAutoLaunchService.openLoginItemsSettings()
                }
            }
        } catch {
            showError(error)
        }
    }

    private func showWelcome() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = “Bob Select Helper”
        alert.informativeText = “After selecting text by dragging, double-clicking a word, or triple-clicking a paragraph, a Bob icon will appear next to your cursor.\n\nClick the menu bar icon to customize: hover or click trigger, Bob input box behavior, auto-launch with Bob, icon size, hover delay, position, and auto-hide duration.\n\nYou'll need to grant Accessibility permissions on first use. When macOS asks if Bob Select Helper may control Bob, please allow it.”
        alert.alertStyle = .informational
        alert.addButton(withTitle: “Got It”)
        alert.runModal()
    }

    private func showError(_ error: Error) {
        NSSound.beep()
        NSApplication.shared.activate(ignoringOtherApps: true)
        let alert = NSAlert(error: error)
        alert.informativeText += “\n\nPlease ensure Bob is installed and that Bob Select Helper has permission to control Bob in System Settings > Privacy & Security > Automation.”
        alert.runModal()
    }
}
