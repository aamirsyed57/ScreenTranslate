import AppKit
import ApplicationServices

/// Retrieves the currently selected text from any app on screen.
///
/// Strategy:
/// 1. Ask the focused AXUIElement for `kAXSelectedTextAttribute` (preferred — no clipboard touch).
/// 2. If that fails, simulate ⌘C and read the clipboard (leaves clipboard with selected text).
final class AccessibilityHelper {
    static let shared = AccessibilityHelper()
    private init() {}

    func getSelectedText() async -> String? {
        // Try Accessibility API first (silent, no clipboard change)
        if let text = getSelectedTextViaAX(), !text.isEmpty {
            return text
        }
        // Fallback: simulate copy
        return await getSelectedTextViaClipboard()
    }

    // MARK: - AX API

    private func getSelectedTextViaAX() -> String? {
        guard AXIsProcessTrusted() else { return nil }

        let system: AXUIElement = AXUIElementCreateSystemWide()
        var focusedRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system,
                                            kAXFocusedUIElementAttribute as CFString,
                                            &focusedRef) == .success,
              let focusedRef = focusedRef else { return nil }

        let focused = focusedRef as! AXUIElement  // AXUIElement is CFTypeRef

        var selectedRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(focused,
                                            kAXSelectedTextAttribute as CFString,
                                            &selectedRef) == .success,
              let text = selectedRef as? String else { return nil }

        return text.isEmpty ? nil : text
    }

    // MARK: - Clipboard fallback

    private func getSelectedTextViaClipboard() async -> String? {
        let pb = NSPasteboard.general
        let prevCount = pb.changeCount

        simulateCopy()

        // Wait for the target app to copy
        try? await Task.sleep(nanoseconds: 200_000_000)  // 200 ms

        guard pb.changeCount != prevCount else { return nil }
        let text = pb.string(forType: .string)
        return text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? text : nil
    }

    private func simulateCopy() {
        let src = CGEventSource(stateID: .hidSystemState)
        // Key-down ⌘C (keyCode 8 = 'c')
        let down = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: true)
        down?.flags = .maskCommand
        down?.post(tap: .cgAnnotatedSessionEventTap)
        // Key-up
        let up = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: false)
        up?.flags = .maskCommand
        up?.post(tap: .cgAnnotatedSessionEventTap)
    }
}
