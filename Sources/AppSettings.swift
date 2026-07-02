import Foundation
import Combine

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled) }
    }

    @Published var targetLanguageCode: String {
        didSet { UserDefaults.standard.set(targetLanguageCode, forKey: Keys.targetLanguageCode) }
    }

    @Published var showSourceText: Bool {
        didSet { UserDefaults.standard.set(showSourceText, forKey: Keys.showSourceText) }
    }

    // MARK: - Hotkey (default: ⌘⇧T)

    /// Virtual key code (CGKeyCode). Default 17 = 'T'.
    @Published var hotkeyKeyCode: Int {
        didSet { UserDefaults.standard.set(hotkeyKeyCode, forKey: Keys.hotkeyKeyCode) }
    }
    @Published var hotkeyUsesCmd: Bool {
        didSet { UserDefaults.standard.set(hotkeyUsesCmd, forKey: Keys.hotkeyUsesCmd) }
    }
    @Published var hotkeyUsesShift: Bool {
        didSet { UserDefaults.standard.set(hotkeyUsesShift, forKey: Keys.hotkeyUsesShift) }
    }
    @Published var hotkeyUsesOption: Bool {
        didSet { UserDefaults.standard.set(hotkeyUsesOption, forKey: Keys.hotkeyUsesOption) }
    }
    @Published var hotkeyUsesControl: Bool {
        didSet { UserDefaults.standard.set(hotkeyUsesControl, forKey: Keys.hotkeyUsesControl) }
    }

    private enum Keys {
        static let isEnabled           = "isEnabled"
        static let targetLanguageCode  = "targetLanguageCode"
        static let showSourceText      = "showSourceText"
        static let hotkeyKeyCode       = "hotkeyKeyCode"
        static let hotkeyUsesCmd       = "hotkeyUsesCmd"
        static let hotkeyUsesShift     = "hotkeyUsesShift"
        static let hotkeyUsesOption    = "hotkeyUsesOption"
        static let hotkeyUsesControl   = "hotkeyUsesControl"
    }

    private init() {
        let d = UserDefaults.standard
        self.isEnabled           = d.object(forKey: Keys.isEnabled)          as? Bool   ?? true
        self.targetLanguageCode  = d.string(forKey: Keys.targetLanguageCode)             ?? "en"
        self.showSourceText      = d.object(forKey: Keys.showSourceText)     as? Bool   ?? true
        self.hotkeyKeyCode       = d.object(forKey: Keys.hotkeyKeyCode)      as? Int    ?? 17
        self.hotkeyUsesCmd       = d.object(forKey: Keys.hotkeyUsesCmd)      as? Bool   ?? true
        self.hotkeyUsesShift     = d.object(forKey: Keys.hotkeyUsesShift)    as? Bool   ?? true
        self.hotkeyUsesOption    = d.object(forKey: Keys.hotkeyUsesOption)   as? Bool   ?? false
        self.hotkeyUsesControl   = d.object(forKey: Keys.hotkeyUsesControl)  as? Bool   ?? false
    }
}

