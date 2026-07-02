import Foundation

enum PopupPhase {
    case loading
    case result
    case error
}

@MainActor
final class PopupState: ObservableObject {
    @Published var phase: PopupPhase = .loading
    @Published var result: TranslationResult? = nil
    @Published var errorMessage: String? = nil
}
