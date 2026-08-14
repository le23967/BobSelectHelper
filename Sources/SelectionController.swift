import AppKit

final class SelectionController {
    private let reader = SelectionTextReader()
    private let panel = FloatingQueryPanel()
    private let bobClient = BobClient()

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var dragGlobalMonitor: Any?
    private var dragLocalMonitor: Any?
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

        // .leftMouseDragged fires continuously during any drag anywhere on the system.
        // It is only meaningful between a mouse-down and the matching mouse-up, so it is
        // subscribed on demand in `beginDragTracking()` rather than left running.
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .leftMouseUp, .scrollWheel]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    private func beginDragTracking() {
        guard dragGlobalMonitor == nil else { return }

        let mask: NSEvent.EventTypeMask = [.leftMouseDragged]
        dragGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in
            self?.trackDrag()
        }
        dragLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.trackDrag()
            return event
        }
    }

    private func endDragTracking() {
        if let dragGlobalMonitor {
            NSEvent.removeMonitor(dragGlobalMonitor)
            self.dragGlobalMonitor = nil
        }
        if let dragLocalMonitor {
            NSEvent.removeMonitor(dragLocalMonitor)
            self.dragLocalMonitor = nil
        }
    }

    private func trackDrag() {
        // Once the threshold is crossed this returns immediately, so the monitor is
        // left in place until mouse-up. Calling removeMonitor here would free the
        // handler block while it is still executing.
        guard !didDrag, let start = mouseDownPoint else { return }
        let point = NSEvent.mouseLocation
        if hypot(point.x - start.x, point.y - start.y) > 3 {
            didDrag = true
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
        endDragTracking()
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
            beginDragTracking()

        case .leftMouseUp:
            endDragTracking()
            guard !panel.containsScreenPoint(point) else { return }
            let looksLikeSelection = didDrag || event.clickCount >= 2
            mouseDownPoint = nil
            didDrag = false
            guard looksLikeSelection, let bundleID = inspectableFrontmostApplication() else { return }
            inspectSelection(after: 0.08, mousePoint: point, bundleID: bundleID)

        case .scrollWheel:
            // Scrolling emits a dense stream of events; only act when there is
            // something on screen to dismiss.
            guard panel.isVisible else { return }
            panel.hidePanel()
            requestGeneration += 1

        default:
            break
        }
    }

    private func inspectSelection(after delay: TimeInterval, mousePoint: NSPoint, bundleID: String?) {
        requestGeneration += 1
        let generation = requestGeneration

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, generation == self.requestGeneration else { return }

            self.reader.readSelectedText(in: bundleID) { [weak self] text in
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

    /// Returns the frontmost bundle identifier when the helper may act there.
    ///
    /// The identifier is carried through so per-app rules, such as suppressing the
    /// Command-C fallback, can be applied to the app the selection came from. A nil
    /// return means the helper should stay out of the way entirely.
    private func inspectableFrontmostApplication() -> String? {
        guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return ""
        }

        let alwaysIgnored = [
            Bundle.main.bundleIdentifier,
            "com.hezongyidev.Bob"
        ].compactMap { $0 }

        if alwaysIgnored.contains(bundleID) {
            return nil
        }

        return Settings.shared.allowsApplication(bundleID) ? bundleID : nil
    }

    private func translate(_ text: String) {
        bobClient.translate(text: text) { [weak self] error in
            if let error {
                self?.onError?(error)
            }
        }
    }
}
