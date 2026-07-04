import AppKit
import ApplicationServices

@MainActor
final class PermissionsManager: ObservableObject {
    static let shared = PermissionsManager()

    @Published private(set) var hasAccessibilityPermission: Bool = false {
        didSet {
            if hasAccessibilityPermission {
                // Automatically recreate or enable the hotkey listener once permission is granted at runtime.
                // We call startListening on the main actor.
                HotkeyManager.shared.startListening()
            }
        }
    }

    private var pollTimer: Timer?

    private init() {
        refresh()
        startPolling()
    }

    /// Re-check the current permission state without showing a prompt.
    func refresh() {
        // Querying with prompt option explicitly set to false prevents OS prompts on check
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options)
    }

    /// Prompt the OS accessibility dialog AND open System Settings.
    func requestPermission() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
        openSettings()
    }

    /// Deep-link directly to the Accessibility pane.
    func openSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - Private

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    deinit {
        pollTimer?.invalidate()
    }
}
