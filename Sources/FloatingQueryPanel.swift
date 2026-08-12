import AppKit

final class FloatingQueryPanel: NSPanel {
    private let container = NSView(frame: .zero)
    private let queryButton = NSButton(frame: .zero)

    private var selectedText: String?
    private var hoverTimer: Timer?
    private var autoHideTimer: Timer?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var pointerInside = false
    private var translationInProgress = false

    var onTranslate: ((String) -> Void)?

    init() {
        let size = NSSize(width: Settings.shared.iconSize, height: Settings.shared.iconSize)
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .popUpMenu
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        animationBehavior = .utilityWindow
        becomesKeyOnlyIfNeeded = true
        acceptsMouseMovedEvents = true

        container.wantsLayer = true

        queryButton.isBordered = false
        queryButton.bezelStyle = .regularSquare
        queryButton.imagePosition = .imageOnly
        queryButton.toolTip = "使用 Bob 翻译"
        queryButton.target = self
        queryButton.action = #selector(buttonPressed)
        queryButton.imageScaling = .scaleProportionallyDown

        container.addSubview(queryButton)
        contentView = container
        applyCurrentSettings()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func show(text: String, near mousePoint: NSPoint) {
        selectedText = text
        translationInProgress = false
        hoverTimer?.invalidate()
        autoHideTimer?.invalidate()

        applyCurrentSettings()
        let origin = clampedOrigin(near: mousePoint)
        setFrameOrigin(origin)
        orderFrontRegardless()

        startTemporaryMouseMonitoring()
        updatePointerState(at: NSEvent.mouseLocation)

        let hideDelay = Settings.shared.autoHideDelay
        if hideDelay > 0 {
            autoHideTimer = Timer.scheduledTimer(withTimeInterval: hideDelay, repeats: false) { [weak self] _ in
                self?.hidePanel()
            }
        }
    }

    func hidePanel() {
        hoverTimer?.invalidate()
        hoverTimer = nil
        autoHideTimer?.invalidate()
        autoHideTimer = nil
        selectedText = nil
        pointerInside = false
        translationInProgress = false
        stopTemporaryMouseMonitoring()
        orderOut(nil)
    }

    func containsScreenPoint(_ point: NSPoint) -> Bool {
        isVisible && frame.insetBy(dx: -5, dy: -5).contains(point)
    }

    private func applyCurrentSettings() {
        let side = Settings.shared.iconSize
        let size = NSSize(width: side, height: side)
        let currentOrigin = frame.origin
        setFrame(NSRect(origin: currentOrigin, size: size), display: false)

        container.frame = NSRect(origin: .zero, size: size)
        container.layer?.cornerRadius = max(8, side * 0.31)
        container.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.97).cgColor
        container.layer?.borderWidth = 0.5
        container.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.55).cgColor

        let inset = max(2, side * 0.07)
        queryButton.frame = container.bounds.insetBy(dx: inset, dy: inset)
        queryButton.image = NSImage(
            systemSymbolName: "character.bubble.fill",
            accessibilityDescription: "使用 Bob 翻译"
        )?.withSymbolConfiguration(
            NSImage.SymbolConfiguration(pointSize: side * 0.52, weight: .medium)
        )
        queryButton.contentTintColor = .controlAccentColor
    }

    private func clampedOrigin(near point: NSPoint) -> NSPoint {
        let panelSize = frame.size
        let horizontalGap: CGFloat = 8
        let verticalGap: CGFloat = 6
        var origin: NSPoint

        switch Settings.shared.panelPosition {
        case .belowRight:
            origin = NSPoint(x: point.x + horizontalGap, y: point.y - panelSize.height - verticalGap)
        case .aboveRight:
            origin = NSPoint(x: point.x + horizontalGap, y: point.y + verticalGap)
        case .belowLeft:
            origin = NSPoint(x: point.x - panelSize.width - horizontalGap, y: point.y - panelSize.height - verticalGap)
        case .aboveLeft:
            origin = NSPoint(x: point.x - panelSize.width - horizontalGap, y: point.y + verticalGap)
        }

        let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return origin }

        origin.x = min(max(origin.x, visible.minX + 4), visible.maxX - panelSize.width - 4)
        origin.y = min(max(origin.y, visible.minY + 4), visible.maxY - panelSize.height - 4)
        return origin
    }

    private func startTemporaryMouseMonitoring() {
        stopTemporaryMouseMonitoring()

        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged]
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in
            self?.updatePointerState(at: NSEvent.mouseLocation)
        }

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.updatePointerState(at: NSEvent.mouseLocation)
            return event
        }
    }

    private func stopTemporaryMouseMonitoring() {
        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }
        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
            self.localMouseMonitor = nil
        }
    }

    private func updatePointerState(at point: NSPoint) {
        guard isVisible else { return }

        let isInside = frame.insetBy(dx: -1, dy: -1).contains(point)
        guard isInside != pointerInside else { return }
        pointerInside = isInside

        hoverTimer?.invalidate()
        hoverTimer = nil

        guard isInside, Settings.shared.activationMode == .hover else { return }
        let delay = Settings.shared.hoverDelay

        if delay <= 0.001 {
            translateNow()
        } else {
            hoverTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                guard let self, self.pointerInside else { return }
                self.translateNow()
            }
        }
    }

    @objc private func buttonPressed() {
        translateNow()
    }

    private func translateNow() {
        guard !translationInProgress, let text = selectedText else { return }
        translationInProgress = true
        hidePanel()
        onTranslate?(text)
    }
}
