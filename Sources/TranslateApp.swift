import SwiftUI

@main
struct TranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Pure menu-bar app — no dock window.
        // AppDelegate handles the NSStatusItem and popup.
        // We provide an empty Settings scene to satisfy the App protocol.
        Settings {
            EmptyView()
        }
    }
}
