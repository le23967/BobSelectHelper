import AppKit
import UniformTypeIdentifiers

/// The window shown when the Dock icon or the menu's settings item is used.
///
/// A single instance is kept alive by the app delegate and reused, so reopening the
/// window neither rebuilds the view tree nor re-scans the installed applications.
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private let settings = Settings.shared

    // Header
    private let headlineLabel = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(labelWithString: "")
    private let grantButton = NSButton()

    // General
    private let enabledCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let dockCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let dockHintLabel = NSTextField(labelWithString: "")
    private let languagePopUp = NSPopUpButton()
    private let triggerPopUp = NSPopUpButton()
    private let hoverDelayPopUp = NSPopUpButton()

    // Appearance
    private let iconSizePopUp = NSPopUpButton()
    private let positionPopUp = NSPopUpButton()
    private let autoHidePopUp = NSPopUpButton()

    // Bob
    private let inputBoxPopUp = NSPopUpButton()
    private let autoLaunchCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let copyFallbackCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let fallbackHintLabel = NSTextField(labelWithString: "")
    private let fallbackSectionLabel = NSTextField(labelWithString: "")
    private let fallbackTable = NSTableView()
    private let fallbackScroll = NSScrollView()
    private let fallbackEmptyLabel = NSTextField(labelWithString: "")
    private let fallbackAddButton = NSButton()
    private let fallbackRemoveButton = NSButton()
    private var excludedApps: [String] = []

    // Applications
    private let tabView = NSTabView()
    private let modeSegment = NSSegmentedControl()
    private let filterHintLabel = NSTextField(labelWithString: "")
    private let appTable = NSTableView()
    private let appScroll = NSScrollView()
    private let addButton = NSButton()
    private let removeButton = NSButton()
    private let emptyLabel = NSTextField(labelWithString: "")

    private var listedApps: [String] = []
    /// Resolved display name and icon per bundle identifier, so redrawing a row
    /// does not hit NSWorkspace again.
    private var resolved: [String: (name: String, icon: NSImage)] = [:]

    /// Grid row labels are built once, so each keeps a provider that `refresh()`
    /// re-evaluates when the language changes.
    private var rowLabels: [(field: NSTextField, text: () -> String)] = []

    var onDockVisibilityChange: ((Bool) -> Void)?
    var onLanguageChange: (() -> Void)?
    var onAutoLaunchToggle: (() -> Void)?
    var onRequestAccessibility: (() -> Void)?

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 470),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        // NSWindowController owns the window; releasing it on close would leave a
        // dangling controller when the window is reopened.
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)
        window.delegate = self
        buildInterface()
        refresh()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Construction

    private func buildInterface() {
        guard let window else { return }
        window.title = Localization.Window.title

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 12
        root.edgeInsets = NSEdgeInsets(top: 18, left: 20, bottom: 18, right: 20)
        root.translatesAutoresizingMaskIntoConstraints = false

        root.addArrangedSubview(buildHeader())
        root.addArrangedSubview(makeSeparator())

        tabView.addTabViewItem(makeTab(Localization.Window.tabGeneral, view: buildGeneralTab()))
        tabView.addTabViewItem(makeTab(Localization.Window.tabAppearance, view: buildAppearanceTab()))
        tabView.addTabViewItem(makeTab(Localization.Window.tabBob, view: buildBobTab()))
        tabView.addTabViewItem(makeTab(Localization.Window.tabApplications, view: buildApplicationsTab()))
        tabView.translatesAutoresizingMaskIntoConstraints = false
        root.addArrangedSubview(tabView)

        let content = NSView()
        content.addSubview(root)
        window.contentView = content

        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: content.topAnchor),
            root.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            root.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            tabView.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -40)
        ])
    }

    private func buildHeader() -> NSView {
        let iconView = NSImageView()
        iconView.image = NSApplication.shared.applicationIconImage
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 52),
            iconView.heightAnchor.constraint(equalToConstant: 52)
        ])

        let title = NSTextField(labelWithString: "Bob Select Helper")
        title.font = .systemFont(ofSize: 15, weight: .semibold)

        headlineLabel.font = .systemFont(ofSize: 12)
        headlineLabel.textColor = .secondaryLabelColor
        headlineLabel.lineBreakMode = .byWordWrapping
        headlineLabel.maximumNumberOfLines = 2

        statusLabel.font = .systemFont(ofSize: 11)

        grantButton.title = Localization.Window.grantAccess
        grantButton.bezelStyle = .rounded
        grantButton.controlSize = .small
        grantButton.target = self
        grantButton.action = #selector(requestAccessibility)

        let statusRow = NSStackView(views: [statusLabel, grantButton])
        statusRow.orientation = .horizontal
        statusRow.spacing = 8

        let textColumn = NSStackView(views: [title, headlineLabel, statusRow])
        textColumn.orientation = .vertical
        textColumn.alignment = .leading
        textColumn.spacing = 3

        let header = NSStackView(views: [iconView, textColumn])
        header.orientation = .horizontal
        header.alignment = .top
        header.spacing = 14
        return header
    }

    private func buildGeneralTab() -> NSView {
        configure(languagePopUp, action: #selector(languageChanged))
        configure(triggerPopUp, action: #selector(triggerChanged))
        configure(hoverDelayPopUp, action: #selector(hoverDelayChanged))

        enabledCheckbox.target = self
        enabledCheckbox.action = #selector(toggleEnabled)
        dockCheckbox.target = self
        dockCheckbox.action = #selector(toggleDock)

        dockHintLabel.font = .systemFont(ofSize: 11)
        dockHintLabel.textColor = .secondaryLabelColor
        dockHintLabel.lineBreakMode = .byWordWrapping
        dockHintLabel.maximumNumberOfLines = 2
        dockHintLabel.preferredMaxLayoutWidth = 430

        let grid = makeGrid([
            ({ Localization.Menu.language }, languagePopUp),
            ({ Localization.Menu.triggerMethod }, triggerPopUp),
            ({ Localization.Window.hoverDelayLabel }, hoverDelayPopUp)
        ])

        return makeTabBody([enabledCheckbox, dockCheckbox, dockHintLabel, grid])
    }

    private func buildAppearanceTab() -> NSView {
        configure(iconSizePopUp, action: #selector(iconSizeChanged))
        configure(positionPopUp, action: #selector(positionChanged))
        configure(autoHidePopUp, action: #selector(autoHideChanged))

        let grid = makeGrid([
            ({ Localization.Window.iconSizeLabel }, iconSizePopUp),
            ({ Localization.Menu.iconPosition }, positionPopUp),
            ({ Localization.Window.autoHideLabel }, autoHidePopUp)
        ])
        return makeTabBody([grid])
    }

    private func buildBobTab() -> NSView {
        configure(inputBoxPopUp, action: #selector(inputBoxChanged))

        autoLaunchCheckbox.target = self
        autoLaunchCheckbox.action = #selector(toggleAutoLaunch)
        copyFallbackCheckbox.target = self
        copyFallbackCheckbox.action = #selector(toggleCopyFallback)

        for label in [fallbackHintLabel, fallbackEmptyLabel] {
            label.font = .systemFont(ofSize: 11)
            label.textColor = .secondaryLabelColor
            label.lineBreakMode = .byWordWrapping
            label.maximumNumberOfLines = 5
        }
        fallbackHintLabel.preferredMaxLayoutWidth = 430
        fallbackEmptyLabel.alignment = .center
        fallbackEmptyLabel.textColor = .tertiaryLabelColor
        fallbackEmptyLabel.translatesAutoresizingMaskIntoConstraints = false

        fallbackSectionLabel.font = .systemFont(ofSize: 12, weight: .semibold)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("fallbackApp"))
        column.width = 400
        fallbackTable.addTableColumn(column)
        fallbackTable.headerView = nil
        fallbackTable.dataSource = self
        fallbackTable.delegate = self
        fallbackTable.rowHeight = 24
        fallbackTable.allowsMultipleSelection = true
        fallbackTable.style = .inset

        fallbackScroll.documentView = fallbackTable
        fallbackScroll.hasVerticalScroller = true
        fallbackScroll.borderType = .bezelBorder
        fallbackScroll.translatesAutoresizingMaskIntoConstraints = false

        let listArea = NSView()
        listArea.translatesAutoresizingMaskIntoConstraints = false
        listArea.addSubview(fallbackScroll)
        listArea.addSubview(fallbackEmptyLabel)
        NSLayoutConstraint.activate([
            fallbackScroll.topAnchor.constraint(equalTo: listArea.topAnchor),
            fallbackScroll.leadingAnchor.constraint(equalTo: listArea.leadingAnchor),
            fallbackScroll.trailingAnchor.constraint(equalTo: listArea.trailingAnchor),
            fallbackScroll.bottomAnchor.constraint(equalTo: listArea.bottomAnchor),
            listArea.heightAnchor.constraint(equalToConstant: 96),
            fallbackEmptyLabel.centerXAnchor.constraint(equalTo: listArea.centerXAnchor),
            fallbackEmptyLabel.centerYAnchor.constraint(equalTo: listArea.centerYAnchor),
            fallbackEmptyLabel.widthAnchor.constraint(lessThanOrEqualTo: listArea.widthAnchor, constant: -32)
        ])

        fallbackAddButton.bezelStyle = .smallSquare
        fallbackAddButton.image = NSImage(systemSymbolName: "plus", accessibilityDescription: nil)
        fallbackAddButton.target = self
        fallbackAddButton.action = #selector(addFallbackExclusion)

        fallbackRemoveButton.bezelStyle = .smallSquare
        fallbackRemoveButton.image = NSImage(systemSymbolName: "minus", accessibilityDescription: nil)
        fallbackRemoveButton.target = self
        fallbackRemoveButton.action = #selector(removeFallbackExclusion)

        for button in [fallbackAddButton, fallbackRemoveButton] {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: 28).isActive = true
            button.heightAnchor.constraint(equalToConstant: 22).isActive = true
        }

        let buttonRow = NSStackView(views: [fallbackAddButton, fallbackRemoveButton, NSView()])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 0

        let grid = makeGrid([({ Localization.Menu.bobInputBox }, inputBoxPopUp)])
        return makeTabBody(
            [grid, autoLaunchCheckbox, copyFallbackCheckbox, fallbackHintLabel,
             fallbackSectionLabel, listArea, buttonRow],
            fillWidth: true
        )
    }

    private func buildApplicationsTab() -> NSView {
        modeSegment.segmentCount = 3
        modeSegment.trackingMode = .selectOne
        modeSegment.target = self
        modeSegment.action = #selector(filterModeChanged)

        filterHintLabel.font = .systemFont(ofSize: 11)
        filterHintLabel.textColor = .secondaryLabelColor
        filterHintLabel.lineBreakMode = .byWordWrapping
        filterHintLabel.maximumNumberOfLines = 3
        filterHintLabel.preferredMaxLayoutWidth = 430

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("app"))
        column.width = 400
        appTable.addTableColumn(column)
        appTable.headerView = nil
        appTable.dataSource = self
        appTable.delegate = self
        appTable.rowHeight = 24
        appTable.allowsMultipleSelection = true
        appTable.style = .inset

        appScroll.documentView = appTable
        appScroll.hasVerticalScroller = true
        appScroll.borderType = .bezelBorder
        appScroll.translatesAutoresizingMaskIntoConstraints = false

        emptyLabel.alignment = .center
        emptyLabel.font = .systemFont(ofSize: 11)
        emptyLabel.textColor = .tertiaryLabelColor
        emptyLabel.lineBreakMode = .byWordWrapping
        emptyLabel.maximumNumberOfLines = 3
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        // The placeholder sits over the empty table rather than shifting the layout.
        let listArea = NSView()
        listArea.translatesAutoresizingMaskIntoConstraints = false
        listArea.addSubview(appScroll)
        listArea.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            appScroll.topAnchor.constraint(equalTo: listArea.topAnchor),
            appScroll.leadingAnchor.constraint(equalTo: listArea.leadingAnchor),
            appScroll.trailingAnchor.constraint(equalTo: listArea.trailingAnchor),
            appScroll.bottomAnchor.constraint(equalTo: listArea.bottomAnchor),
            listArea.heightAnchor.constraint(equalToConstant: 168),
            emptyLabel.centerXAnchor.constraint(equalTo: listArea.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: listArea.centerYAnchor),
            emptyLabel.widthAnchor.constraint(lessThanOrEqualTo: listArea.widthAnchor, constant: -32)
        ])

        // Standard macOS list editing: a +/- pair under the table, not a text field.
        addButton.bezelStyle = .smallSquare
        addButton.setButtonType(.momentaryPushIn)
        addButton.image = NSImage(systemSymbolName: "plus", accessibilityDescription: nil)
        addButton.target = self
        addButton.action = #selector(addApp)

        removeButton.bezelStyle = .smallSquare
        removeButton.setButtonType(.momentaryPushIn)
        removeButton.image = NSImage(systemSymbolName: "minus", accessibilityDescription: nil)
        removeButton.target = self
        removeButton.action = #selector(removeApp)

        for button in [addButton, removeButton] {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: 28).isActive = true
            button.heightAnchor.constraint(equalToConstant: 22).isActive = true
        }

        let spacer = NSView()
        let buttonRow = NSStackView(views: [addButton, removeButton, spacer])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 0
        buttonRow.setHuggingPriority(.defaultLow, for: .horizontal)

        return makeTabBody([modeSegment, filterHintLabel, listArea, buttonRow], fillWidth: true)
    }

    // MARK: - Layout helpers

    private func configure(_ popUp: NSPopUpButton, action: Selector) {
        popUp.target = self
        popUp.action = action
        popUp.controlSize = .regular
    }

    private func makeTab(_ label: String, view: NSView) -> NSTabViewItem {
        let item = NSTabViewItem()
        item.label = label
        item.view = view
        return item
    }

    private func makeTabBody(_ views: [NSView], fillWidth: Bool = false) -> NSView {
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = fillWidth ? .width : .leading
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let host = NSView()
        host.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: host.topAnchor),
            stack.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: host.trailingAnchor)
        ])
        return host
    }

    private func makeGrid(_ rows: [(() -> String, NSView)]) -> NSGridView {
        let grid = NSGridView(numberOfColumns: 2, rows: 0)
        grid.columnSpacing = 10
        grid.rowSpacing = 8
        for (label, control) in rows {
            let text = NSTextField(labelWithString: label())
            text.alignment = .right
            rowLabels.append((field: text, text: label))
            grid.addRow(with: [text, control])
        }
        grid.column(at: 0).xPlacement = .trailing
        return grid
    }

    private func makeSeparator() -> NSView {
        let line = NSBox()
        line.boxType = .separator
        return line
    }

    // MARK: - State

    /// Rebuilds every user-visible string and re-reads all values from Settings.
    func refresh() {
        window?.title = Localization.Window.title
        headlineLabel.stringValue = Localization.Window.headline

        for row in rowLabels {
            row.field.stringValue = row.text()
        }

        let trusted = AccessibilitySupport.isTrusted
        statusLabel.stringValue = trusted
            ? Localization.Window.statusReady
            : Localization.Window.statusNeedsAccessibility
        statusLabel.textColor = trusted ? .systemGreen : .systemOrange
        grantButton.isHidden = trusted
        grantButton.title = Localization.Window.grantAccess

        tabView.tabViewItems[0].label = Localization.Window.tabGeneral
        tabView.tabViewItems[1].label = Localization.Window.tabAppearance
        tabView.tabViewItems[2].label = Localization.Window.tabBob
        tabView.tabViewItems[3].label = Localization.Window.tabApplications

        enabledCheckbox.title = Localization.Menu.enableHelper
        enabledCheckbox.state = settings.isEnabled ? .on : .off

        dockCheckbox.title = Localization.Window.showInDock
        dockCheckbox.state = settings.showInDock ? .on : .off
        dockHintLabel.stringValue = Localization.Window.showInDockHint

        fill(languagePopUp, titles: [Localization.Menu.languageEnglish, Localization.Menu.languageChinese],
             selected: settings.language == .english ? 0 : 1)

        fill(triggerPopUp, titles: [Localization.Menu.translateOnHover, Localization.Menu.translateOnClick],
             selected: settings.activationMode == .hover ? 0 : 1)

        let delays: [TimeInterval] = [0.0, 0.12, 0.22, 0.40, 0.70]
        fill(hoverDelayPopUp,
             titles: [Localization.Menu.immediate, Localization.Menu.fast, Localization.Menu.balanced,
                      Localization.Menu.slow, Localization.Menu.verySlow],
             selected: nearestIndex(of: settings.hoverDelay, in: delays))
        hoverDelayPopUp.isEnabled = settings.activationMode == .hover

        let sizes: [CGFloat] = [26, 30, 34, 40, 48, 56]
        fill(iconSizePopUp,
             titles: [Localization.Menu.small, Localization.Menu.smaller, Localization.Menu.default,
                      Localization.Menu.larger, Localization.Menu.large, Localization.Menu.extraLarge],
             selected: nearestIndex(of: Double(settings.iconSize), in: sizes.map(Double.init)))

        fill(positionPopUp,
             titles: [Localization.Menu.bottomRight, Localization.Menu.topRight,
                      Localization.Menu.bottomLeft, Localization.Menu.topLeft],
             selected: [PanelPosition.belowRight, .aboveRight, .belowLeft, .aboveLeft]
                .firstIndex(of: settings.panelPosition) ?? 0)

        let hides: [TimeInterval] = [2, 5, 10, 0]
        fill(autoHidePopUp,
             titles: [Localization.Menu.twoSeconds, Localization.Menu.fiveSeconds,
                      Localization.Menu.tenSeconds, Localization.Window.neverLabel],
             selected: hides.firstIndex(of: settings.autoHideDelay) ?? 1)

        fill(inputBoxPopUp,
             titles: [Localization.Menu.alwaysExpandInputBox, Localization.Menu.followBobState,
                      Localization.Menu.alwaysCollapseInputBox],
             selected: [InputBoxState.alwaysUnfold, .last, .alwaysFold]
                .firstIndex(of: settings.inputBoxState) ?? 0)

        let autoLaunchStatus = BobAutoLaunchService.shared.status
        autoLaunchCheckbox.title = autoLaunchStatus == .requiresApproval
            ? Localization.Menu.autoLaunchPendingApproval
            : Localization.Menu.autoLaunchWithBob
        autoLaunchCheckbox.state = BobAutoLaunchService.shared.isEnabledOrPendingApproval ? .on : .off

        copyFallbackCheckbox.title = Localization.Menu.useCopyFallback
        copyFallbackCheckbox.state = settings.copyFallbackEnabled ? .on : .off

        fallbackHintLabel.stringValue = Localization.Fallback.explanation
        fallbackSectionLabel.stringValue = Localization.Fallback.sectionTitle
        fallbackAddButton.toolTip = Localization.Filter.addTooltip
        fallbackRemoveButton.toolTip = Localization.Filter.removeTooltip
        reloadExclusionList()

        modeSegment.setLabel(Localization.Filter.allowAll, forSegment: 0)
        modeSegment.setLabel(Localization.Filter.whitelist, forSegment: 1)
        modeSegment.setLabel(Localization.Filter.blacklist, forSegment: 2)
        modeSegment.selectedSegment = [AppFilterMode.allowAll, .whitelist, .blacklist]
            .firstIndex(of: settings.appFilterMode) ?? 0
        filterHintLabel.stringValue = Localization.Filter.explanation

        addButton.toolTip = Localization.Filter.addTooltip
        removeButton.toolTip = Localization.Filter.removeTooltip

        reloadAppList()
    }

    private func fill(_ popUp: NSPopUpButton, titles: [String], selected: Int) {
        popUp.removeAllItems()
        popUp.addItems(withTitles: titles)
        if selected >= 0, selected < titles.count {
            popUp.selectItem(at: selected)
        }
    }

    private func nearestIndex(of value: Double, in options: [Double]) -> Int {
        var bestIndex = 0
        var bestDistance = Double.greatestFiniteMagnitude
        for (index, option) in options.enumerated() {
            let distance = abs(option - value)
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }
        return bestIndex
    }

    private func reloadAppList() {
        let mode = settings.appFilterMode
        listedApps = mode == .whitelist
            ? settings.whitelistedApps.sorted { displayName(for: $0).localizedCaseInsensitiveCompare(displayName(for: $1)) == .orderedAscending }
            : (mode == .blacklist
                ? settings.blacklistedApps.sorted { displayName(for: $0).localizedCaseInsensitiveCompare(displayName(for: $1)) == .orderedAscending }
                : [])

        let editable = mode != .allowAll
        appTable.isEnabled = editable
        addButton.isEnabled = editable
        removeButton.isEnabled = editable && appTable.selectedRow >= 0

        switch mode {
        case .allowAll:  emptyLabel.stringValue = Localization.Filter.allowAllNotice
        case .whitelist: emptyLabel.stringValue = Localization.Filter.emptyWhitelist
        case .blacklist: emptyLabel.stringValue = Localization.Filter.emptyBlacklist
        }
        emptyLabel.isHidden = !listedApps.isEmpty

        appTable.reloadData()
    }

    private func reloadExclusionList() {
        excludedApps = settings.copyFallbackExcludedApps.sorted {
            displayName(for: $0).localizedCaseInsensitiveCompare(displayName(for: $1)) == .orderedAscending
        }

        let enabled = settings.copyFallbackEnabled
        fallbackTable.isEnabled = enabled
        fallbackAddButton.isEnabled = enabled
        fallbackRemoveButton.isEnabled = enabled && fallbackTable.selectedRow >= 0
        fallbackSectionLabel.textColor = enabled ? .labelColor : .disabledControlTextColor

        fallbackEmptyLabel.stringValue = enabled
            ? Localization.Fallback.empty
            : Localization.Fallback.disabledNotice
        fallbackEmptyLabel.isHidden = !excludedApps.isEmpty

        fallbackTable.reloadData()
    }

    /// Resolves a bundle identifier to the app's real name and icon, caching the
    /// result so row redraws do not repeat the lookup.
    private func entry(for bundleID: String) -> (name: String, icon: NSImage) {
        if let cached = resolved[bundleID] { return cached }

        let workspace = NSWorkspace.shared
        var name = bundleID
        var icon = NSImage(systemSymbolName: "questionmark.app.dashed", accessibilityDescription: nil)
            ?? NSImage(size: NSSize(width: 16, height: 16))

        if let url = workspace.urlForApplication(withBundleIdentifier: bundleID) {
            name = FileManager.default.displayName(atPath: url.path)
            icon = workspace.icon(forFile: url.path)
        }
        icon.size = NSSize(width: 16, height: 16)

        let value = (name: name, icon: icon)
        resolved[bundleID] = value
        return value
    }

    private func displayName(for bundleID: String) -> String {
        entry(for: bundleID).name
    }

    func show() {
        refresh()
        window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    // MARK: - Actions

    @objc private func toggleEnabled() {
        settings.isEnabled = enabledCheckbox.state == .on
    }

    @objc private func toggleDock() {
        let show = dockCheckbox.state == .on
        settings.showInDock = show
        onDockVisibilityChange?(show)
    }

    @objc private func languageChanged() {
        settings.language = languagePopUp.indexOfSelectedItem == 0 ? .english : .chinese
        refresh()
        onLanguageChange?()
    }

    @objc private func triggerChanged() {
        settings.activationMode = triggerPopUp.indexOfSelectedItem == 0 ? .hover : .click
        hoverDelayPopUp.isEnabled = settings.activationMode == .hover
    }

    @objc private func hoverDelayChanged() {
        let delays: [TimeInterval] = [0.0, 0.12, 0.22, 0.40, 0.70]
        settings.hoverDelay = delays[safe: hoverDelayPopUp.indexOfSelectedItem] ?? 0.22
    }

    @objc private func iconSizeChanged() {
        let sizes: [CGFloat] = [26, 30, 34, 40, 48, 56]
        settings.iconSize = sizes[safe: iconSizePopUp.indexOfSelectedItem] ?? 34
    }

    @objc private func positionChanged() {
        let positions: [PanelPosition] = [.belowRight, .aboveRight, .belowLeft, .aboveLeft]
        settings.panelPosition = positions[safe: positionPopUp.indexOfSelectedItem] ?? .belowRight
    }

    @objc private func autoHideChanged() {
        let hides: [TimeInterval] = [2, 5, 10, 0]
        settings.autoHideDelay = hides[safe: autoHidePopUp.indexOfSelectedItem] ?? 5
    }

    @objc private func inputBoxChanged() {
        let states: [InputBoxState] = [.alwaysUnfold, .last, .alwaysFold]
        settings.inputBoxState = states[safe: inputBoxPopUp.indexOfSelectedItem] ?? .alwaysUnfold
    }

    @objc private func toggleAutoLaunch() {
        onAutoLaunchToggle?()
        refresh()
    }

    @objc private func toggleCopyFallback() {
        settings.copyFallbackEnabled = copyFallbackCheckbox.state == .on
        reloadExclusionList()
    }

    @objc private func addFallbackExclusion() {
        presentApplicationPicker { [weak self] bundleIDs in
            guard let self else { return }
            for bundleID in bundleIDs {
                self.settings.addToCopyFallbackExclusions(bundleID)
            }
            self.reloadExclusionList()
        }
    }

    @objc private func removeFallbackExclusion() {
        let rows = fallbackTable.selectedRowIndexes
        guard !rows.isEmpty else { return }
        for row in rows {
            guard let bundleID = excludedApps[safe: row] else { continue }
            settings.removeFromCopyFallbackExclusions(bundleID)
        }
        fallbackTable.deselectAll(nil)
        reloadExclusionList()
    }

    @objc private func requestAccessibility() {
        onRequestAccessibility?()
    }

    @objc private func filterModeChanged() {
        let modes: [AppFilterMode] = [.allowAll, .whitelist, .blacklist]
        settings.appFilterMode = modes[safe: modeSegment.selectedSegment] ?? .allowAll
        reloadAppList()
    }

    @objc private func addApp() {
        guard settings.appFilterMode != .allowAll else { return }
        presentApplicationPicker { [weak self] bundleIDs in
            guard let self else { return }
            for bundleID in bundleIDs {
                switch self.settings.appFilterMode {
                case .whitelist: self.settings.addToWhitelist(bundleID)
                case .blacklist: self.settings.addToBlacklist(bundleID)
                case .allowAll:  continue
                }
            }
            self.reloadAppList()
        }
    }

    /// Opens the standard picker restricted to applications and hands back the
    /// identifier of everything chosen.
    private func presentApplicationPicker(_ handler: @escaping ([String]) -> Void) {
        guard let window else { return }

        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.resolvesAliases = true
        panel.treatsFilePackagesAsDirectories = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = Localization.Filter.choosePanelPrompt
        panel.message = Localization.Filter.choosePanelMessage

        panel.beginSheetModal(for: window) { response in
            guard response == .OK else { return }
            handler(panel.urls.compactMap { SettingsWindowController.bundleIdentifier(at: $0) })
        }
    }

    @objc private func removeApp() {
        let rows = appTable.selectedRowIndexes
        guard !rows.isEmpty else { return }

        for row in rows {
            guard let bundleID = listedApps[safe: row] else { continue }
            switch settings.appFilterMode {
            case .whitelist: settings.removeFromWhitelist(bundleID)
            case .blacklist: settings.removeFromBlacklist(bundleID)
            case .allowAll:  break
            }
        }
        appTable.deselectAll(nil)
        reloadAppList()
    }

    /// Reads the identifier straight from Info.plist. Bundle(url:) would work, but
    /// CoreFoundation caches every bundle it creates for the process lifetime.
    private static func bundleIdentifier(at url: URL) -> String? {
        let plist = url.appendingPathComponent("Contents/Info.plist")
        guard let info = NSDictionary(contentsOf: plist) else { return nil }
        return info["CFBundleIdentifier"] as? String
    }
}

// MARK: - Table

extension SettingsWindowController: NSTableViewDataSource, NSTableViewDelegate {
    private func rows(for tableView: NSTableView) -> [String] {
        tableView === fallbackTable ? excludedApps : listedApps
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        rows(for: tableView).count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let bundleID = rows(for: tableView)[safe: row] else { return nil }
        let identifier = NSUserInterfaceItemIdentifier("appCell")

        let cell: NSTableCellView
        if let reused = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView {
            cell = reused
        } else {
            cell = NSTableCellView()
            cell.identifier = identifier

            let image = NSImageView()
            image.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(image)
            cell.imageView = image

            let text = NSTextField(labelWithString: "")
            text.font = .systemFont(ofSize: 12)
            text.lineBreakMode = .byTruncatingMiddle
            text.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(text)
            cell.textField = text

            NSLayoutConstraint.activate([
                image.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
                image.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                image.widthAnchor.constraint(equalToConstant: 16),
                image.heightAnchor.constraint(equalToConstant: 16),
                text.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 6),
                text.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
                text.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
            ])
        }

        let details = entry(for: bundleID)
        cell.imageView?.image = details.icon
        cell.textField?.stringValue = details.name
        cell.toolTip = bundleID
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let table = notification.object as? NSTableView else { return }
        if table === fallbackTable {
            fallbackRemoveButton.isEnabled = settings.copyFallbackEnabled && table.selectedRow >= 0
        } else {
            removeButton.isEnabled = settings.appFilterMode != .allowAll && table.selectedRow >= 0
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
