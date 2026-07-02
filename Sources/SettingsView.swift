import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var perms = PermissionsManager.shared

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    permissionsSection
                    Divider().opacity(0.4)
                    translationSection
                    Divider().opacity(0.4)
                    displaySection
                    Divider().opacity(0.4)
                    shortcutSection
                }
                .padding(22)
            }
        }
        .frame(width: 420, height: 490)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(hue: 0.58, saturation: 0.8, brightness: 0.9),
                                 Color(hue: 0.65, saturation: 0.85, brightness: 0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                Image(systemName: "character.bubble.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Translate")
                    .font(.system(size: 16, weight: .bold))
                Text("Select text anywhere, press ⌘⇧T")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $settings.isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
    }

    // MARK: - Accessibility

    private var permissionsSection: some View {
        SectionCard(title: "Accessibility", icon: "lock.shield.fill", color: .blue) {
            HStack(spacing: 10) {
                Image(systemName: perms.hasAccessibilityPermission
                      ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(perms.hasAccessibilityPermission ? .green : .red)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 2) {
                    Text(perms.hasAccessibilityPermission
                         ? "Access granted"
                         : "Permission required")
                        .font(.system(size: 13, weight: .medium))
                    if !perms.hasAccessibilityPermission {
                        Text("Required to read selected text from other apps.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if !perms.hasAccessibilityPermission {
                    Button("Grant Access") {
                        perms.requestPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(12)
            .background(
                (perms.hasAccessibilityPermission ? Color.green : Color.red).opacity(0.07),
                in: RoundedRectangle(cornerRadius: 8)
            )
        }
    }

    // MARK: - Translation

    private var translationSection: some View {
        SectionCard(title: "Translation", icon: "globe", color: .indigo) {
            HStack {
                Text("Translate to")
                    .font(.system(size: 13))
                Spacer()
                Picker("", selection: $settings.targetLanguageCode) {
                    ForEach(LanguageOption.all) { lang in
                        Text("\(lang.flag)  \(lang.name)").tag(lang.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 210)
            }
        }
    }

    // MARK: - Display

    private var displaySection: some View {
        SectionCard(title: "Display", icon: "eye.fill", color: .teal) {
            Toggle(isOn: $settings.showSourceText) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Show original text")
                        .font(.system(size: 13))
                    Text("Displays the selected text above the translation.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Shortcut

    private var shortcutSection: some View {
        SectionCard(title: "Keyboard Shortcut", icon: "keyboard", color: .purple) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Translate selected text")
                        .font(.system(size: 13))
                    Text("Click the shortcut to record a new one")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                ShortcutRecorderView()
            }
        }
    }
}

// MARK: - Reusable sub-views

private struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            content()
        }
    }
}

private struct KeyCap: View {
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
                    .shadow(color: .black.opacity(0.25), radius: 0, y: 1.5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}
