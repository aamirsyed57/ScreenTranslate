import AppKit
import CoreGraphics

/// Listens globally for ⌘⇧T and invokes `onHotkeyPressed`.
/// Uses a listen-only CGEventTap so the event is NOT consumed
/// and still reaches the frontmost application.
final class HotkeyManager {
    static let shared = HotkeyManager()

    var onHotkeyPressed: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private init() {}

    func startListening() {
        // If the tap is already successfully created and registered, do nothing.
        if eventTap != nil { return }

        let mask: CGEventMask = 1 << CGEventType.keyDown.rawValue

        // The callback must be a non-capturing C function pointer.
        // We pass `self` as userInfo (refcon) to reach the instance.
        // The tap runs on the main run loop, so AppSettings.shared is safe to read here.
        let callback: CGEventTapCallBack = { _, type, event, refcon -> Unmanaged<CGEvent>? in
            guard type == .keyDown, let refcon = refcon else {
                return Unmanaged.passRetained(event)
            }

            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags   = event.flags

            // Build expected modifier flags from persisted settings
            let s = AppSettings.shared
            let hasCmd = flags.contains(.maskCommand)
            let hasShift = flags.contains(.maskShift)
            let hasOption = flags.contains(.maskAlternate)
            let hasCtrl = flags.contains(.maskControl)

            let isMatch = keyCode == Int64(s.hotkeyKeyCode)
                       && hasCmd == s.hotkeyUsesCmd
                       && hasShift == s.hotkeyUsesShift
                       && hasOption == s.hotkeyUsesOption
                       && hasCtrl == s.hotkeyUsesControl

            if isMatch {
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                DispatchQueue.main.async { manager.onHotkeyPressed?() }
            }

            return Unmanaged.passRetained(event)
        }

        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: userInfo
        )

        guard let tap = eventTap else {
            print("[HotkeyManager] Could not create event tap — Accessibility permission missing.")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stopListening() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let src = runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetCurrent(), src, .commonModes) }
        eventTap = nil
        runLoopSource = nil
    }
}
