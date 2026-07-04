import SwiftUI

struct PopupView: View {
    @ObservedObject var state: PopupState
    let onDismiss: () -> Void

    @State private var copied = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            contentView
                .padding(18)

            // Dismiss button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(5)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(10)
        }
        .frame(width: 360)
    }

    // MARK: - Content switch

    @ViewBuilder
    private var contentView: some View {
        switch state.phase {
        case .loading: loadingView
        case .result:
            if let r = state.result { resultView(r) } else { loadingView }
        case .error:
            errorView(state.errorMessage ?? "An unknown error occurred.")
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
                .scaleEffect(0.9)
            Text("Translating…")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }

    // MARK: - Result

    private func resultView(_ r: TranslationResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Language route pill
            languagePillRow(r)

            Divider()
                .background(Color.white.opacity(0.12))

            // Source text (optional)
            if AppSettings.shared.showSourceText && !r.originalText.isEmpty {
                Text(r.originalText.count > 120
                     ? String(r.originalText.prefix(120)) + "…"
                     : r.originalText)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Translated text — the hero element
            Text(r.translatedText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .lineLimit(8)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Footer: copy button
            HStack {
                Spacer()
                Button(action: copyResult) {
                    Label(copied ? "Copied!" : "Copy Translation",
                          systemImage: copied ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(copied ? .green : .accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            (copied ? Color.green : Color.accentColor).opacity(0.15),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: copied)
            }
        }
    }

    private func languagePillRow(_ r: TranslationResult) -> some View {
        HStack(spacing: 6) {
            Menu {
                Button(action: { state.onReTranslate?("auto") }) {
                    Text("🌐  Auto-detect")
                }
                Divider()
                ForEach(LanguageOption.all) { lang in
                    Button(action: { state.onReTranslate?(lang.id) }) {
                        Text("\(lang.flag)  \(lang.name)")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(flagFor(r.detectedSourceCode)).font(.system(size: 12))
                    Text(r.detectedSourceLanguage)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.09), in: Capsule())
            }
            .buttonStyle(.plain)

            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)

            if let target = LanguageOption.find(code: r.targetLanguageCode) {
                langPill(flag: target.flag, name: target.name)
            }

            Spacer()
        }
        .padding(.trailing, 28) // avoid overlap with dismiss button
    }

    private func langPill(flag: String, name: String) -> some View {
        HStack(spacing: 4) {
            Text(flag).font(.system(size: 12))
            Text(name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.09), in: Capsule())
    }

    private func flagFor(_ code: String) -> String {
        LanguageOption.find(code: code)?.flag ?? "🌐"
    }

    private func copyResult() {
        guard let text = state.result?.translatedText else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
        }
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 15))
                Text("Translation Failed")
                    .font(.system(size: 14, weight: .semibold))
            }
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.trailing, 28)
        .padding(.vertical, 4)
    }
}
