import AppKit

class AppListManager: NSWindowController, NSTableViewDataSource, NSTableViewDelegate, NSComboBoxDataSource, NSComboBoxDelegate {
    private let tableView = NSTableView()
    private let comboBox = NSComboBox()
    private let scrollView = NSScrollView()
    private let addButton = NSButton()
    private let removeButton = NSButton()
    private let modeSegmentControl = NSSegmentedControl()
    private let modeLabel = NSTextField(labelWithString: "")
    private let infoLabel = NSTextField(labelWithString: "")
    private let listLabel = NSTextField(labelWithString: "")
    private let addLabel = NSTextField(labelWithString: "")
    private var currentApps: [String] = []
    private let settings = Settings.shared
    private var allInstalledApps: [(name: String, bundleID: String)] = []

    override init(window: NSWindow? = nil) {
        let windowToUse = window ?? NSWindow()
        super.init(window: windowToUse)
        setupUI()
        loadInstalledApps()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        guard let w = window else { return }
        w.title = Localization.Filter.windowTitle
        w.setContentSize(NSSize(width: 500, height: 450))
        w.center()
        w.styleMask = [.titled, .closable, .resizable]

        let contentView = NSView()
        w.contentView = contentView

        modeLabel.stringValue = Localization.Filter.filterMode
        modeLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        contentView.addSubview(modeLabel)

        modeSegmentControl.segmentCount = 3
        modeSegmentControl.setLabel(Localization.Filter.allowAll, forSegment: 0)
        modeSegmentControl.setLabel(Localization.Filter.whitelist, forSegment: 1)
        modeSegmentControl.setLabel(Localization.Filter.blacklist, forSegment: 2)
        modeSegmentControl.selectedSegment = settings.appFilterMode == .allowAll ? 0 : (settings.appFilterMode == .whitelist ? 1 : 2)
        modeSegmentControl.target = self
        modeSegmentControl.action = #selector(filterModeChanged(_:))
        contentView.addSubview(modeSegmentControl)

        infoLabel.stringValue = Localization.Filter.explanation
        infoLabel.isEditable = false
        infoLabel.isSelectable = false
        infoLabel.font = NSFont.systemFont(ofSize: 11)
        infoLabel.textColor = .gray
        contentView.addSubview(infoLabel)

        listLabel.stringValue = Localization.Filter.applications
        listLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        contentView.addSubview(listLabel)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("app"))
        column.width = 400
        tableView.addTableColumn(column)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.headerView = nil
        tableView.target = self

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        contentView.addSubview(scrollView)

        addLabel.stringValue = Localization.Filter.addApplication
        addLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        contentView.addSubview(addLabel)

        comboBox.dataSource = self
        comboBox.delegate = self
        comboBox.isEditable = true
        comboBox.completes = true
        contentView.addSubview(comboBox)

        addButton.title = Localization.Filter.add
        addButton.target = self
        addButton.action = #selector(addApp(_:))
        contentView.addSubview(addButton)

        removeButton.title = Localization.Filter.remove
        removeButton.target = self
        removeButton.action = #selector(removeApp(_:))
        contentView.addSubview(removeButton)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        modeLabel.translatesAutoresizingMaskIntoConstraints = false
        modeSegmentControl.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        listLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addLabel.translatesAutoresizingMaskIntoConstraints = false
        comboBox.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            modeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            modeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            modeSegmentControl.topAnchor.constraint(equalTo: modeLabel.bottomAnchor, constant: 8),
            modeSegmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            modeSegmentControl.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),

            infoLabel.topAnchor.constraint(equalTo: modeSegmentControl.bottomAnchor, constant: 12),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            listLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 16),
            listLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            scrollView.topAnchor.constraint(equalTo: listLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            scrollView.heightAnchor.constraint(equalToConstant: 150),

            addLabel.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 16),
            addLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            comboBox.topAnchor.constraint(equalTo: addLabel.bottomAnchor, constant: 8),
            comboBox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            comboBox.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -8),
            comboBox.heightAnchor.constraint(equalToConstant: 22),

            addButton.topAnchor.constraint(equalTo: addLabel.bottomAnchor, constant: 8),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            addButton.widthAnchor.constraint(equalToConstant: 60),

            removeButton.topAnchor.constraint(equalTo: comboBox.bottomAnchor, constant: 8),
            removeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            removeButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20),
        ])

        loadCurrentApps()
    }

    /// Re-applies every visible string after the user switches language.
    func reloadLocalizedText() {
        window?.title = Localization.Filter.windowTitle
        modeLabel.stringValue = Localization.Filter.filterMode
        infoLabel.stringValue = Localization.Filter.explanation
        listLabel.stringValue = Localization.Filter.applications
        addLabel.stringValue = Localization.Filter.addApplication
        modeSegmentControl.setLabel(Localization.Filter.allowAll, forSegment: 0)
        modeSegmentControl.setLabel(Localization.Filter.whitelist, forSegment: 1)
        modeSegmentControl.setLabel(Localization.Filter.blacklist, forSegment: 2)
        addButton.title = Localization.Filter.add
        removeButton.title = Localization.Filter.remove
    }

    private func loadInstalledApps() {
        let fileManager = FileManager.default
        var apps: [(name: String, bundleID: String)] = []

        let searchPaths = ["/Applications", NSHomeDirectory() + "/Applications"]

        for path in searchPaths {
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: path)
                for item in contents {
                    let fullPath = (path as NSString).appendingPathComponent(item)
                    if item.hasSuffix(".app") {
                        if let bundleID = getBundleID(forAppAtPath: fullPath) {
                            let displayName = item.replacingOccurrences(of: ".app", with: "")
                            apps.append((name: displayName, bundleID: bundleID))
                        }
                    }
                }
            } catch {
                continue
            }
        }

        allInstalledApps = apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func getBundleID(forAppAtPath path: String) -> String? {
        let bundle = Bundle(path: path)
        return bundle?.bundleIdentifier
    }

    private func loadCurrentApps() {
        let mode = settings.appFilterMode
        currentApps = mode == .whitelist ? Array(settings.whitelistedApps) : Array(settings.blacklistedApps)
        currentApps.sort()
        tableView.reloadData()
        updateModeLabel()
    }

    private func updateModeLabel() {
        let mode = settings.appFilterMode
        switch mode {
        case .allowAll:
            modeSegmentControl.selectedSegment = 0
        case .whitelist:
            modeSegmentControl.selectedSegment = 1
        case .blacklist:
            modeSegmentControl.selectedSegment = 2
        }
    }

    @objc private func filterModeChanged(_ sender: NSSegmentedControl) {
        let newMode: AppFilterMode = sender.selectedSegment == 0 ? .allowAll : (sender.selectedSegment == 1 ? .whitelist : .blacklist)
        settings.appFilterMode = newMode
        loadCurrentApps()
    }

    @objc private func addApp(_ sender: Any) {
        let input = comboBox.stringValue.trimmingCharacters(in: .whitespaces)
        guard !input.isEmpty else { return }

        let bundleID: String?
        if let app = allInstalledApps.first(where: { $0.name.localizedCaseInsensitiveCompare(input) == .orderedSame }) {
            bundleID = app.bundleID
        } else {
            bundleID = input
        }

        guard let bundleID = bundleID, !bundleID.isEmpty else { return }

        if !currentApps.contains(bundleID) {
            let mode = settings.appFilterMode
            if mode == .whitelist {
                settings.addToWhitelist(bundleID)
            } else if mode == .blacklist {
                settings.addToBlacklist(bundleID)
            }
            loadCurrentApps()
            comboBox.stringValue = ""
        }
    }

    @objc private func removeApp(_ sender: Any) {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0, selectedRow < currentApps.count else { return }

        let bundleID = currentApps[selectedRow]
        let mode = settings.appFilterMode
        if mode == .whitelist {
            settings.removeFromWhitelist(bundleID)
        } else if mode == .blacklist {
            settings.removeFromBlacklist(bundleID)
        }
        loadCurrentApps()
    }

    // MARK: - NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        return currentApps.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard row >= 0, row < currentApps.count else { return nil }
        let bundleID = currentApps[row]
        if let app = allInstalledApps.first(where: { $0.bundleID == bundleID }) {
            return "\(app.name) (\(bundleID))"
        }
        return bundleID
    }

    // MARK: - NSComboBoxDataSource

    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        guard let index = allInstalledApps.firstIndex(where: { $0.name.localizedCaseInsensitiveCompare(string) == .orderedSame }) else { return NSNotFound }
        return index
    }

    func comboBox(_ comboBox: NSComboBox, completedString uncompletedString: String) -> String? {
        let lower = uncompletedString.lowercased()
        return allInstalledApps.first { $0.name.lowercased().hasPrefix(lower) }?.name
    }

    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return allInstalledApps.count
    }

    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        guard index >= 0, index < allInstalledApps.count else { return nil }
        return allInstalledApps[index].name
    }
}
