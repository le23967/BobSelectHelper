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

        let enabled = NSMenuItem(title: "启用划词助手", action: #selector(toggleEnabled), keyEquivalent: "")
        enabled.target = self
        enabled.state = settings.isEnabled ? .on : .off
        menu.addItem(enabled)

        menu.addItem(.separator())

        let triggerMenu = NSMenu()
        let hover = NSMenuItem(title: "悬停后翻译", action: #selector(useHoverMode), keyEquivalent: "")
        hover.target = self
        hover.state = settings.activationMode == .hover ? .on : .off
        triggerMenu.addItem(hover)

        let click = NSMenuItem(title: "点击后翻译", action: #selector(useClickMode), keyEquivalent: "")
        click.target = self
        click.state = settings.activationMode == .click ? .on : .off
        triggerMenu.addItem(click)

        let triggerItem = NSMenuItem(title: "触发方式", action: nil, keyEquivalent: "")
        triggerItem.submenu = triggerMenu
        menu.addItem(triggerItem)

        let inputBoxMenu = NSMenu()
        addInputBoxStateItem("总是展开输入框", value: .alwaysUnfold, to: inputBoxMenu)
        addInputBoxStateItem("跟随 Bob 当前状态", value: .last, to: inputBoxMenu)
        addInputBoxStateItem("总是折叠输入框", value: .alwaysFold, to: inputBoxMenu)
        let inputBoxItem = NSMenuItem(title: "Bob 输入框", action: nil, keyEquivalent: "")
        inputBoxItem.submenu = inputBoxMenu
        menu.addItem(inputBoxItem)

        let delayMenu = NSMenu()
        addDelayItem("立即", value: 0.0, to: delayMenu)
        addDelayItem("快速（0.12 秒）", value: 0.12, to: delayMenu)
        addDelayItem("平衡（0.22 秒）", value: 0.22, to: delayMenu)
        addDelayItem("较慢（0.40 秒）", value: 0.40, to: delayMenu)
        addDelayItem("防误触（0.70 秒）", value: 0.70, to: delayMenu)
        let delayItem = NSMenuItem(title: "悬停延迟", action: nil, keyEquivalent: "")
        delayItem.submenu = delayMenu
        delayItem.isEnabled = settings.activationMode == .hover
        menu.addItem(delayItem)

        let sizeMenu = NSMenu()
        addSizeItem("小（26 px）", value: 26, to: sizeMenu)
        addSizeItem("较小（30 px）", value: 30, to: sizeMenu)
        addSizeItem("默认（34 px）", value: 34, to: sizeMenu)
        addSizeItem("较大（40 px）", value: 40, to: sizeMenu)
        addSizeItem("大（48 px）", value: 48, to: sizeMenu)
        addSizeItem("特大（56 px）", value: 56, to: sizeMenu)
        let sizeItem = NSMenuItem(title: "悬浮图标大小", action: nil, keyEquivalent: "")
        sizeItem.submenu = sizeMenu
        menu.addItem(sizeItem)

        let positionMenu = NSMenu()
        addPositionItem("右下方", value: .belowRight, to: positionMenu)
        addPositionItem("右上方", value: .aboveRight, to: positionMenu)
        addPositionItem("左下方", value: .belowLeft, to: positionMenu)
        addPositionItem("左上方", value: .aboveLeft, to: positionMenu)
        let positionItem = NSMenuItem(title: "图标出现位置", action: nil, keyEquivalent: "")
        positionItem.submenu = positionMenu
        menu.addItem(positionItem)

        let hideMenu = NSMenu()
        addAutoHideItem("2 秒", value: 2, to: hideMenu)
        addAutoHideItem("5 秒", value: 5, to: hideMenu)
        addAutoHideItem("10 秒", value: 10, to: hideMenu)
        addAutoHideItem("不自动隐藏", value: 0, to: hideMenu)
        let hideItem = NSMenuItem(title: "自动隐藏", action: nil, keyEquivalent: "")
        hideItem.submenu = hideMenu
        menu.addItem(hideItem)

        menu.addItem(.separator())

        let autoLaunchStatus = bobAutoLaunchService.status
        let autoLaunchTitle: String
        switch autoLaunchStatus {
        case .requiresApproval:
            autoLaunchTitle = "打开 Bob 时自动启动（待系统允许）"
        default:
            autoLaunchTitle = "打开 Bob 时自动启动"
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
            let loginItems = NSMenuItem(title: "打开登录项设置并允许", action: #selector(openLoginItemsSettings), keyEquivalent: "")
            loginItems.target = self
            menu.addItem(loginItems)
        }

        let fallback = NSMenuItem(title: "不兼容软件使用 Command-C 取词", action: #selector(toggleCopyFallback), keyEquivalent: "")
        fallback.target = self
        fallback.state = settings.copyFallbackEnabled ? .on : .off
        menu.addItem(fallback)

        let appFilter = NSMenuItem(title: "Application Filter Settings", action: #selector(openAppListManager), keyEquivalent: "")
        appFilter.target = self
        menu.addItem(appFilter)

        let permission = NSMenuItem(title: "打开辅助功能权限", action: #selector(requestAccessibility), keyEquivalent: "")
        permission.target = self
        menu.addItem(permission)

        let test = NSMenuItem(title: "测试 Bob 连接", action: #selector(testBob), keyEquivalent: "")
        test.target = self
        menu.addItem(test)

        menu.addItem(.separator())

        let about = NSMenuItem(title: "使用说明", action: #selector(showWelcomeFromMenu), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: "退出 Bob Select Helper", action: #selector(quitApp), keyEquivalent: "q")
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
                alert.messageText = "允许随 Bob 自动启动"
                alert.informativeText = "macOS 已登记 Bob Select Helper Launcher，但需要你在“系统设置 > 通用 > 登录项与扩展”中允许它在后台运行。以后打开 Bob 时，Bob Select Helper 会自动启动。"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "打开登录项设置")
                alert.addButton(withTitle: "稍后")
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
        alert.messageText = "Bob Select Helper"
        alert.informativeText = "拖选文字、双击单词或三击段落后，鼠标旁会出现一个 Bob 图标。\n\n点击菜单栏图标，可以自定义：悬停或点击触发、Bob 输入框总是展开/跟随/折叠、打开 Bob 时自动启动、图标大小、悬停延迟、出现位置和自动隐藏时间。\n\n首次使用需要允许辅助功能权限；系统询问是否允许控制 Bob 时，请选择允许。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "知道了")
        alert.runModal()
    }

    private func showError(_ error: Error) {
        NSSound.beep()
        NSApplication.shared.activate(ignoringOtherApps: true)
        let alert = NSAlert(error: error)
        alert.informativeText += "\n\n请确认已经安装 Bob，并在系统设置 > 隐私与安全性 > 自动化中允许 Bob Select Helper 控制 Bob。"
        alert.runModal()
    }
}
