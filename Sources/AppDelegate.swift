import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    private var statusItem: NSStatusItem!
    private let popup = PopupWindowController()
    private var settingsWindow: NSWindow?
    private var isTranslating = false

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildStatusItem()
        startHotkeyListener()

        // Handle source language override from the popup view
        popup.state.onReTranslate = { [weak self] overrideCode in
            self?.reTranslate(overrideSourceCode: overrideCode)
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    // MARK: - Status Bar

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        refreshStatusIcon()
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: "Enable Translation",
                                    action: #selector(toggleEnabled),
                                    keyEquivalent: "")
        toggleItem.state = AppSettings.shared.isEnabled ? .on : .off
        toggleItem.tag = 1
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings…",
                                      action: #selector(openSettings),
                                      keyEquivalent: ",")
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit ScreenTranslate",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q")
        menu.addItem(quitItem)
        return menu
    }

    @objc private func refreshStatusIcon() {
        guard let button = statusItem.button else { return }
        let img = NSImage(systemSymbolName: "character.bubble.fill",
                          accessibilityDescription: "Translate")
        img?.isTemplate = true
        button.image = img
        button.alphaValue = AppSettings.shared.isEnabled ? 1.0 : 0.38
    }

    @objc private func toggleEnabled() {
        AppSettings.shared.isEnabled.toggle()
        refreshStatusIcon()
        // Sync check-mark
        statusItem.menu?.item(withTag: 1)?.state = AppSettings.shared.isEnabled ? .on : .off
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let view = SettingsView()
            let hosting = NSHostingView(rootView: view)
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            win.title = "ScreenTranslate Settings"
            win.contentView = hosting
            win.center()
            win.setFrameAutosaveName("TranslateSettings")
            settingsWindow = win
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Hotkey

    private func startHotkeyListener() {
        HotkeyManager.shared.onHotkeyPressed = { [weak self] in
            self?.handleHotkey()
        }
        HotkeyManager.shared.startListening()
    }

    private func handleHotkey() {
        guard AppSettings.shared.isEnabled else { return }
        guard !isTranslating else { return }

        isTranslating = true
        let cursorLocation = NSEvent.mouseLocation
        popup.showLoading(near: cursorLocation)

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            defer { self.isTranslating = false }

            guard let text = await AccessibilityHelper.shared.getSelectedText() else {
                // If text retrieval fails, verify if it was due to missing accessibility permissions
                PermissionsManager.shared.refresh()
                self.popup.dismiss()
                
                if !PermissionsManager.shared.hasAccessibilityPermission {
                    self.showPermissionAlert()
                } else {
                    // Alert window or floating error popup
                    self.popup.showLoading(near: cursorLocation) // show panel briefly to display error
                    self.popup.showError("No text selected.\nHighlight some text in any app, then press your hotkey.")
                }
                return
            }

            do {
                let result = try await TranslationService.shared.translate(
                    text: text,
                    targetCode: AppSettings.shared.targetLanguageCode
                )
                self.popup.showResult(result)
            } catch {
                self.popup.showError(error.localizedDescription)
            }
        }
    }

    private func reTranslate(overrideSourceCode: String) {
        guard !isTranslating else { return }
        guard let currentResult = popup.state.result else { return }

        isTranslating = true
        popup.state.phase = .loading

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            defer { self.isTranslating = false }

            do {
                let result = try await TranslationService.shared.translate(
                    text: currentResult.originalText,
                    targetCode: AppSettings.shared.targetLanguageCode,
                    overrideSourceCode: overrideSourceCode
                )
                self.popup.showResult(result)
            } catch {
                self.popup.showError(error.localizedDescription)
            }
        }
    }

    // MARK: - Permission alert

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
            ScreenTranslate needs Accessibility access to read selected text from other apps.

            Please go to System Settings → Privacy & Security → Accessibility and enable ScreenTranslate.
            """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        alert.alertStyle = .warning
        if alert.runModal() == .alertFirstButtonReturn {
            PermissionsManager.shared.openSettings()
        }
    }
}
