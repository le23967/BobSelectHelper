import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var selectionController: SelectionController!
    private let settings = Settings.shared
    private let bobAutoLaunchService = BobAutoLaunchService.shared
    private var appListManager: AppListManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupApplicationMenu()
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

    /// A .regular app owns the menu bar, so it needs a real application menu.
    private func setupApplicationMenu() {
        let appMenu = NSMenu()
        appMenu.addItem(
            withTitle: Localization.Menu.applicationFilterSettings,
            action: #selector(openAppListManager),
            keyEquivalent: ","
        ).target = self
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: Localization.Menu.instructions,
            action: #selector(showWelcomeFromMenu),
            keyEquivalent: ""
        ).target = self
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: Localization.Menu.quitHelper,
            action: #selector(quitApp),
            keyEquivalent: "q"
        ).target = self

        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu

        let mainMenu = NSMenu()
        mainMenu.addItem(appMenuItem)
        NSApplication.shared.mainMenu = mainMenu
    }

    /// Clicking the Dock icon has no window to restore, so open settings instead.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            openAppListManager()
        }
        return true
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

        let enabled = NSMenuItem(title: Localization.Menu.enableHelper, action: #selector(toggleEnabled), keyEquivalent: "")
        enabled.target = self
        enabled.state = settings.isEnabled ? .on : .off
        menu.addItem(enabled)

        menu.addItem(.separator())

        let triggerMenu = NSMenu()
        let hover = NSMenuItem(title: Localization.Menu.translateOnHover, action: #selector(useHoverMode), keyEquivalent: "")
        hover.target = self
        hover.state = settings.activationMode == .hover ? .on : .off
        triggerMenu.addItem(hover)

        let click = NSMenuItem(title: Localization.Menu.translateOnClick, action: #selector(useClickMode), keyEquivalent: "")
        click.target = self
        click.state = settings.activationMode == .click ? .on : .off
        triggerMenu.addItem(click)

        let triggerItem = NSMenuItem(title: Localization.Menu.triggerMethod, action: nil, keyEquivalent: "")
        triggerItem.submenu = triggerMenu
        menu.addItem(triggerItem)

        let inputBoxMenu = NSMenu()
        addInputBoxStateItem(Localization.Menu.alwaysExpandInputBox, value: .alwaysUnfold, to: inputBoxMenu)
        addInputBoxStateItem(Localization.Menu.followBobState, value: .last, to: inputBoxMenu)
        addInputBoxStateItem(Localization.Menu.alwaysCollapseInputBox, value: .alwaysFold, to: inputBoxMenu)
        let inputBoxItem = NSMenuItem(title: Localization.Menu.bobInputBox, action: nil, keyEquivalent: "")
        inputBoxItem.submenu = inputBoxMenu
        menu.addItem(inputBoxItem)

        let delayMenu = NSMenu()
        addDelayItem(Localization.Menu.immediate, value: 0.0, to: delayMenu)
        addDelayItem(Localization.Menu.fast, value: 0.12, to: delayMenu)
        addDelayItem(Localization.Menu.balanced, value: 0.22, to: delayMenu)
        addDelayItem(Localization.Menu.slow, value: 0.40, to: delayMenu)
        addDelayItem(Localization.Menu.verySlow, value: 0.70, to: delayMenu)
        let delayItem = NSMenuItem(title: Localization.Menu.hoverDelay, action: nil, keyEquivalent: "")
        delayItem.submenu = delayMenu
        delayItem.isEnabled = settings.activationMode == .hover
        menu.addItem(delayItem)

        let sizeMenu = NSMenu()
        addSizeItem(Localization.Menu.small, value: 26, to: sizeMenu)
        addSizeItem(Localization.Menu.smaller, value: 30, to: sizeMenu)
        addSizeItem(Localization.Menu.default, value: 34, to: sizeMenu)
        addSizeItem(Localization.Menu.larger, value: 40, to: sizeMenu)
        addSizeItem(Localization.Menu.large, value: 48, to: sizeMenu)
        addSizeItem(Localization.Menu.extraLarge, value: 56, to: sizeMenu)
        let sizeItem = NSMenuItem(title: Localization.Menu.iconSize, action: nil, keyEquivalent: "")
        sizeItem.submenu = sizeMenu
        menu.addItem(sizeItem)

        let positionMenu = NSMenu()
        addPositionItem(Localization.Menu.bottomRight, value: .belowRight, to: positionMenu)
        addPositionItem(Localization.Menu.topRight, value: .aboveRight, to: positionMenu)
        addPositionItem(Localization.Menu.bottomLeft, value: .belowLeft, to: positionMenu)
        addPositionItem(Localization.Menu.topLeft, value: .aboveLeft, to: positionMenu)
        let positionItem = NSMenuItem(title: Localization.Menu.iconPosition, action: nil, keyEquivalent: "")
        positionItem.submenu = positionMenu
        menu.addItem(positionItem)

        let hideMenu = NSMenu()
        addAutoHideItem(Localization.Menu.twoSeconds, value: 2, to: hideMenu)
        addAutoHideItem(Localization.Menu.fiveSeconds, value: 5, to: hideMenu)
        addAutoHideItem(Localization.Menu.tenSeconds, value: 10, to: hideMenu)
        addAutoHideItem(Localization.Menu.neverAutoHide, value: 0, to: hideMenu)
        let hideItem = NSMenuItem(title: Localization.Menu.autoHideDuration, action: nil, keyEquivalent: "")
        hideItem.submenu = hideMenu
        menu.addItem(hideItem)

        menu.addItem(.separator())

        let autoLaunchStatus = bobAutoLaunchService.status
        let autoLaunchTitle: String
        switch autoLaunchStatus {
        case .requiresApproval:
            autoLaunchTitle = Localization.Menu.autoLaunchPendingApproval
        default:
            autoLaunchTitle = Localization.Menu.autoLaunchWithBob
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
            let loginItems = NSMenuItem(title: Localization.Menu.openLoginItems, action: #selector(openLoginItemsSettings), keyEquivalent: "")
            loginItems.target = self
            menu.addItem(loginItems)
        }

        let fallback = NSMenuItem(title: Localization.Menu.useCopyFallback, action: #selector(toggleCopyFallback), keyEquivalent: "")
        fallback.target = self
        fallback.state = settings.copyFallbackEnabled ? .on : .off
        menu.addItem(fallback)

        let appFilter = NSMenuItem(title: Localization.Menu.applicationFilterSettings, action: #selector(openAppListManager), keyEquivalent: "")
        appFilter.target = self
        menu.addItem(appFilter)

        let permission = NSMenuItem(title: Localization.Menu.openAccessibilityPermissions, action: #selector(requestAccessibility), keyEquivalent: "")
        permission.target = self
        menu.addItem(permission)

        let test = NSMenuItem(title: Localization.Menu.testBobConnection, action: #selector(testBob), keyEquivalent: "")
        test.target = self
        menu.addItem(test)

        let languageMenu = NSMenu()
        addLanguageItem(Localization.Menu.languageEnglish, value: .english, to: languageMenu)
        addLanguageItem(Localization.Menu.languageChinese, value: .chinese, to: languageMenu)
        let languageItem = NSMenuItem(title: Localization.Menu.language, action: nil, keyEquivalent: "")
        languageItem.submenu = languageMenu
        menu.addItem(languageItem)

        menu.addItem(.separator())

        let about = NSMenuItem(title: Localization.Menu.instructions, action: #selector(showWelcomeFromMenu), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: Localization.Menu.quitHelper, action: #selector(quitApp), keyEquivalent: "q")
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

    private func addLanguageItem(_ title: String, value: Localization.Language, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: #selector(setLanguage(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = value.rawValue
        item.state = settings.language == value ? .on : .off
        menu.addItem(item)
    }

    @objc private func setLanguage(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let language = Localization.Language(rawValue: raw)
        else { return }
        settings.language = language
        // The status menu rebuilds on open; the app menu and any open window do not.
        setupApplicationMenu()
        appListManager?.reloadLocalizedText()
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
                alert.messageText = Localization.Dialog.allowAutolaunchTitle
                alert.informativeText = Localization.Dialog.allowAutolaunchMessage
                alert.alertStyle = .informational
                alert.addButton(withTitle: Localization.Menu.openLoginItems)
                alert.addButton(withTitle: Localization.Dialog.later)
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
        alert.messageText = Localization.Dialog.welcomeTitle
        alert.informativeText = Localization.Dialog.welcomeMessage
        alert.alertStyle = .informational
        alert.addButton(withTitle: Localization.Dialog.gotIt)
        alert.runModal()
    }

    private func showError(_ error: Error) {
        NSSound.beep()
        NSApplication.shared.activate(ignoringOtherApps: true)
        let alert = NSAlert(error: error)
        alert.informativeText += Localization.Dialog.errorSuffix
        alert.runModal()
    }
}
