import AppKit
import ApplicationServices
import Carbon

final class SelectionTextReader {
    func readSelectedText(in bundleID: String?, completion: @escaping (String?) -> Void) {
        if let text = selectedTextFromAccessibility() {
            completion(clean(text))
            return
        }

        guard Settings.shared.allowsCopyFallback(in: bundleID) else {
            completion(nil)
            return
        }

        readByTemporaryCopy(completion: completion)
    }

    private func selectedTextFromAccessibility() -> String? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedValue: CFTypeRef?

        let focusedError = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        )

        guard focusedError == .success,
              let focusedValue,
              CFGetTypeID(focusedValue) == AXUIElementGetTypeID()
        else {
            return nil
        }

        let focusedElement = focusedValue as! AXUIElement
        var selectedValue: CFTypeRef?
        let selectedError = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedValue
        )

        guard selectedError == .success, let text = selectedValue as? String else {
            return nil
        }

        return clean(text)
    }

    private func readByTemporaryCopy(completion: @escaping (String?) -> Void) {
        guard AccessibilitySupport.isTrusted else {
            completion(nil)
            return
        }

        let pasteboard = NSPasteboard.general

        // Clearing first would leave the pasteboard momentarily empty, which other
        // selection tools watching it react to. Comparing changeCount detects the copy
        // just as well and leaves the existing contents in place until the copy lands.
        let changeCountBeforeCopy = pasteboard.changeCount
        let snapshot = PasteboardSnapshot(pasteboard: pasteboard)

        postCommandC()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            guard pasteboard.changeCount != changeCountBeforeCopy else {
                // Nothing was copied, so the pasteboard is untouched and needs no restore.
                completion(nil)
                return
            }

            let copied = pasteboard.string(forType: .string)
            snapshot.restore(to: pasteboard)
            completion(self.clean(copied))
        }
    }

    private func postCommandC() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        let keyCode = CGKeyCode(kVK_ANSI_C)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    private func clean(_ text: String?) -> String? {
        guard let text else { return nil }
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, cleaned.count <= 20_000 else { return nil }
        return cleaned
    }
}

private struct PasteboardSnapshot {
    let itemData: [[NSPasteboard.PasteboardType: Data]]

    init(pasteboard: NSPasteboard) {
        itemData = (pasteboard.pasteboardItems ?? []).map { item in
            var values: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    values[type] = data
                }
            }
            return values
        }
    }

    func restore(to pasteboard: NSPasteboard) {
        pasteboard.clearContents()

        let items: [NSPasteboardItem] = itemData.map { values in
            let item = NSPasteboardItem()
            for (type, data) in values {
                item.setData(data, forType: type)
            }
            return item
        }

        if !items.isEmpty {
            pasteboard.writeObjects(items)
        }
    }
}
