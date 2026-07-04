import AppKit
import Carbon

/// Listens globally for keyboard shortcuts using the macOS Carbon framework.
/// This method does NOT require Accessibility permission to register or listen
/// to the global keyboard shortcut, preventing startup and event tap permission errors.
final class HotkeyManager {
    static let shared = HotkeyManager()

    var onHotkeyPressed: (() -> Void)?

    private var hotkeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    private init() {}

    func startListening() {
        stopListening()

        let s = AppSettings.shared

        // Map Cocoa modifiers to Carbon flags
        var carbonModifiers: UInt32 = 0
        if s.hotkeyUsesCmd     { carbonModifiers |= UInt32(cmdKey) }
        if s.hotkeyUsesShift   { carbonModifiers |= UInt32(shiftKey) }
        if s.hotkeyUsesOption  { carbonModifiers |= UInt32(optionKey) }
        if s.hotkeyUsesControl { carbonModifiers |= UInt32(controlKey) }

        // Use a unique signature for this app hotkey
        let hotkeyID = EventHotKeyID(signature: OSType(0x53635472), id: 1) // "ScTr"

        print("[HotkeyManager] Registering Carbon HotKey: keyCode=\(s.hotkeyKeyCode), modifiers=\(carbonModifiers)")

        let status = RegisterEventHotKey(
            UInt32(s.hotkeyKeyCode),
            carbonModifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        guard status == noErr else {
            print("[HotkeyManager] Failed to register Carbon HotKey. Error status: \(status)")
            return
        }

        // Set up the event handler specification for kEventHotKeyPressed
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerCallback: EventHandlerUPP = { _, event, userInfo -> OSStatus in
            guard let userInfo = userInfo else { return noErr }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo).takeUnretainedValue()

            print("[HotkeyManager] Carbon HotKey pressed! Triggering action.")
            DispatchQueue.main.async {
                manager.onHotkeyPressed?()
            }
            return noErr
        }

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            handlerCallback,
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )

        if handlerStatus != noErr {
            print("[HotkeyManager] Failed to install Carbon Event Handler. Error status: \(handlerStatus)")
        } else {
            print("[HotkeyManager] Carbon HotKey and event handler registered successfully.")
        }
    }

    func stopListening() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
            print("[HotkeyManager] Unregistered Carbon HotKey.")
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
            print("[HotkeyManager] Removed Carbon event handler.")
        }
    }
}
