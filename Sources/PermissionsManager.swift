import AppKit
import ApplicationServices

final class PermissionsManager: ObservableObject {
    static let shared = PermissionsManager()

    @Published private(set) var hasAccessibilityPermission: Bool = false

    private var pollTimer: Timer?

    private init() {
        refresh()
        startPolling()
    }

    /// Re-check the current permission state.
    func refresh() {
        hasAccessibilityPermission = AXIsProcessTrusted()
    }

    /// Prompt the OS accessibility dialog AND open System Settings.
    func requestPermission() {
        let opts = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        AXIsProcessTrustedWithOptions(opts as CFDictionary)
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
            DispatchQueue.main.async { self?.refresh() }
        }
    }

    deinit { pollTimer?.invalidate() }
}
