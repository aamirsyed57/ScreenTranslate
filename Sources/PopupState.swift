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
    
    /// Callback from view to trigger a re-translation with an overridden source language code
    var onReTranslate: ((String) -> Void)? = nil
}
