import AppKit
import SwiftUI

/// Manages the floating, non-activating translation popup panel.
///
/// The panel is created once and reused across invocations.
/// State updates flow through the `PopupState` observable object,
/// so SwiftUI re-renders automatically when phase/result/error change.
@MainActor
final class PopupWindowController: NSObject {

    // MARK: - Public interface

    func showLoading(near screenPoint: NSPoint) {
        state.phase = .loading
        state.result = nil
        state.errorMessage = nil

        buildPanelIfNeeded()
        positionPanel(near: screenPoint)

        panel?.alphaValue = 0
        panel?.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            panel?.animator().alphaValue = 1
        }

        installDismissMonitor()
        resizePanel(animated: false)
    }

    func showResult(_ result: TranslationResult) {
        state.phase = .result
        state.result = result
        state.errorMessage = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.resizePanel(animated: true)
        }
    }

    func showError(_ message: String) {
        state.phase = .error
        state.errorMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.resizePanel(animated: true)
        }
    }

    func dismiss() {
        removeDismissMonitor()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            panel?.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.panel?.orderOut(nil)
        }
    }

    // MARK: - Private state

    let state = PopupState()
    private var panel: NSPanel?
    private var hostingView: NSHostingView<PopupView>?
    private var dismissMonitor: Any?

    // MARK: - Panel construction

    private func buildPanelIfNeeded() {
        guard panel == nil else { return }

        // NSVisualEffectView gives the frosted-glass look
        let vfxView = NSVisualEffectView()
        vfxView.material = .hudWindow
        vfxView.blendingMode = .behindWindow
        vfxView.state = .active
        vfxView.wantsLayer = true
        vfxView.layer?.cornerRadius = 14
        vfxView.layer?.masksToBounds = true

        let contentView = PopupView(state: state, onDismiss: { [weak self] in self?.dismiss() })
        let hosting = NSHostingView(rootView: contentView)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        vfxView.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: vfxView.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: vfxView.bottomAnchor),
            hosting.leadingAnchor.constraint(equalTo: vfxView.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: vfxView.trailingAnchor),
        ])

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 80),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.isOpaque = false
        p.backgroundColor = .clear
        // Using .screenSaver level ensures it sits on top of all standard windows, fullscreen apps, and other overlay menus.
        p.level = .screenSaver
        p.hasShadow = true
        p.isMovableByWindowBackground = false
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        p.contentView = vfxView

        self.panel = p
        self.hostingView = hosting
    }

    // MARK: - Positioning

    private func positionPanel(near pt: NSPoint) {
        guard let panel = panel else { return }
        let size = panel.frame.size
        let screen = NSScreen.screens.first { $0.frame.contains(pt) } ?? NSScreen.main!
        let vis = screen.visibleFrame

        var x = pt.x + 12
        var y = pt.y - size.height - 12

        if x + size.width > vis.maxX { x = pt.x - size.width - 12 }
        if x < vis.minX { x = vis.minX + 8 }
        if y < vis.minY { y = pt.y + 20 }
        if y + size.height > vis.maxY { y = vis.maxY - size.height - 8 }

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Dynamic resizing

    private func resizePanel(animated: Bool) {
        guard let panel = panel, let hosting = hostingView else { return }
        let fitted = hosting.fittingSize
        let newH = max(60, min(fitted.height, 460))
        var frame = panel.frame
        let dy = newH - frame.height
        frame.origin.y -= dy          // grow upward so cursor stays above
        frame.size.height = newH
        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.2
                ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }
    }

    // MARK: - Dismiss monitor

    private func installDismissMonitor() {
        removeDismissMonitor()
        // Delay monitor activation slightly to prevent the triggering hotkey event
        // or click from immediately dismissing the window.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self, self.dismissMonitor == nil else { return }
            self.dismissMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown, .keyDown]
            ) { [weak self] event in
                guard let self = self, let panel = self.panel, panel.isVisible else { return }

                if event.type == .keyDown, event.keyCode == 53 {   // Esc
                    self.dismiss(); return
                }
                if event.type == .leftMouseDown || event.type == .rightMouseDown {
                    let loc = NSEvent.mouseLocation
                    if !panel.frame.contains(loc) { self.dismiss() }
                }
            }
        }
    }

    private func removeDismissMonitor() {
        if let m = dismissMonitor { NSEvent.removeMonitor(m); dismissMonitor = nil }
    }
}
