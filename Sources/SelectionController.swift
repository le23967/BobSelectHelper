import AppKit

final class SelectionController {
    private let reader = SelectionTextReader()
    private let panel = FloatingQueryPanel()
    private let bobClient = BobClient()

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var mouseDownPoint: NSPoint?
    private var didDrag = false
    private var requestGeneration = 0

    var onError: ((Error) -> Void)?

    init() {
        panel.onTranslate = { [weak self] text in
            self?.translate(text)
        }
    }

    deinit {
        stop()
    }

    func start() {
        guard globalMonitor == nil else { return }

        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .leftMouseDragged, .leftMouseUp, .scrollWheel]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        panel.hidePanel()
    }

    func testBob() {
        translate("Bob Select Helper is connected.")
    }

    private func handle(_ event: NSEvent) {
        guard Settings.shared.isEnabled else {
            panel.hidePanel()
            return
        }

        let point = NSEvent.mouseLocation

        switch event.type {
        case .leftMouseDown:
            if !panel.containsScreenPoint(point) {
                panel.hidePanel()
            }
            mouseDownPoint = point
            didDrag = false
            requestGeneration += 1

        case .leftMouseDragged:
            if let start = mouseDownPoint {
                let distance = hypot(point.x - start.x, point.y - start.y)
                if distance > 3 { didDrag = true }
            }

        case .leftMouseUp:
            guard !panel.containsScreenPoint(point) else { return }
            let looksLikeSelection = didDrag || event.clickCount >= 2
            mouseDownPoint = nil
            didDrag = false
            guard looksLikeSelection, shouldInspectFrontmostApplication() else { return }
            inspectSelection(after: 0.08, mousePoint: point)

        case .scrollWheel:
            panel.hidePanel()
            requestGeneration += 1

        default:
            break
        }
    }

    private func inspectSelection(after delay: TimeInterval, mousePoint: NSPoint) {
        requestGeneration += 1
        let generation = requestGeneration

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, generation == self.requestGeneration else { return }

            self.reader.readSelectedText { [weak self] text in
                guard let self,
                      generation == self.requestGeneration,
                      let text
                else {
                    return
                }

                self.panel.show(text: text, near: mousePoint)
            }
        }
    }

    private func shouldInspectFrontmostApplication() -> Bool {
        guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return true
        }

        let alwaysIgnored = [
            Bundle.main.bundleIdentifier,
            "com.hezongyidev.Bob"
        ].compactMap { $0 }

        if alwaysIgnored.contains(bundleID) {
            return false
        }

        let settings = Settings.shared
        switch settings.appFilterMode {
        case .allowAll:
            return true
        case .whitelist:
            return settings.whitelistedApps.contains(bundleID)
        case .blacklist:
            return !settings.blacklistedApps.contains(bundleID)
        }
    }

    private func translate(_ text: String) {
        bobClient.translate(text: text) { [weak self] error in
            if let error {
                self?.onError?(error)
            }
        }
    }
}
