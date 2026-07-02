import SwiftUI
import CoreGraphics

/// A button that displays the current global shortcut and lets the user
/// record a new one by clicking and pressing the desired key combination.
///
/// Recording state:
/// - A local key monitor captures the next non-modifier keyDown.
/// - Esc cancels without saving.
/// - Any other key combo (with at least one modifier) is saved to AppSettings.
struct ShortcutRecorderView: View {
    @ObservedObject private var settings = AppSettings.shared

    @State private var isRecording = false
    @State private var localMonitor: Any?
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 8) {
            mainButton

            if isRecording {
                Button("Cancel") { stopRecording(save: false) }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .onDisappear { stopRecording(save: false) }
    }

    // MARK: - Main button

    private var mainButton: some View {
        Button(action: isRecording ? { stopRecording(save: false) } : startRecording) {
            if isRecording {
                recordingLabel
            } else {
                currentShortcutLabel
            }
        }
        .buttonStyle(.plain)
    }

    // "● Press shortcut…" with pulsing red outline
    private var recordingLabel: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.red)
                .frame(width: 7, height: 7)
                .opacity(pulse ? 1 : 0.4)
                .animation(.easeInOut(duration: 0.7).repeatForever(), value: pulse)
                .onAppear { pulse = true }
                .onDisappear { pulse = false }

            Text("Press shortcut…")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color.red.opacity(0.35), lineWidth: 1)
        )
    }

    // Stack of KeyCap chips showing the current shortcut
    private var currentShortcutLabel: some View {
        HStack(spacing: 4) {
            if settings.hotkeyUsesControl { ShortcutKeyCap("⌃") }
            if settings.hotkeyUsesOption  { ShortcutKeyCap("⌥") }
            if settings.hotkeyUsesShift   { ShortcutKeyCap("⇧") }
            if settings.hotkeyUsesCmd     { ShortcutKeyCap("⌘") }
            ShortcutKeyCap(Self.keyName(for: settings.hotkeyKeyCode))
        }
    }

    // MARK: - Recording logic

    private func startRecording() {
        isRecording = true
        // Local monitor fires only while our app (Settings window) is active.
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            handleKeyEvent(event)
            return nil   // consume — don't let the key reach the Settings UI
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let code = Int(event.keyCode)

        // Esc → cancel recording without saving
        if code == 53 { stopRecording(save: false); return }

        // Ignore bare modifier key presses (Cmd, Shift, Option, Control, Caps Lock, Fn)
        let modifierKeyCodes: Set<Int> = [54, 55, 56, 57, 58, 59, 60, 61, 63]
        guard !modifierKeyCodes.contains(code) else { return }

        // Require at least one modifier so we don't steal plain letter keys
        let mods = event.modifierFlags
        guard mods.contains(.command) || mods.contains(.control) || mods.contains(.option) else {
            return   // silently ignore — keeps recording active
        }

        // Save new shortcut
        settings.hotkeyKeyCode    = code
        settings.hotkeyUsesCmd    = mods.contains(.command)
        settings.hotkeyUsesShift  = mods.contains(.shift)
        settings.hotkeyUsesOption = mods.contains(.option)
        settings.hotkeyUsesControl = mods.contains(.control)

        stopRecording(save: true)
    }

    private func stopRecording(save: Bool) {
        if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
        isRecording = false
        pulse = false
    }

    // MARK: - Key name lookup

    /// Maps CGKeyCode → human-readable label.
    static func keyName(for keyCode: Int) -> String {
        let map: [Int: String] = [
            0: "A",  1: "S",  2: "D",  3: "F",  4: "H",  5: "G",
            6: "Z",  7: "X",  8: "C",  9: "V",  11: "B", 12: "Q",
            13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1",
            19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=",
            25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]",
            31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "↩",
            37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\",
            43: ",", 44: "/", 45: "N", 46: "M", 47: ".", 48: "⇥",
            49: "Space", 51: "⌫", 53: "⎋",
            96: "F5",  97: "F6",  98: "F7",  99: "F3",
            100: "F8", 101: "F9", 103: "F11", 109: "F10",
            111: "F12", 118: "F4", 120: "F2", 122: "F1",
            123: "←", 124: "→", 125: "↓", 126: "↑",
        ]
        return map[keyCode] ?? "?\(keyCode)"
    }
}

// MARK: - KeyCap chip (private to this file)

private struct ShortcutKeyCap: View {
    let label: String
    init(_ label: String) { self.label = label }

    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(.primary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.22), radius: 0, y: 1.5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}
