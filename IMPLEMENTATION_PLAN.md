# macOS Translate Accessibility App — Implementation Plan

A native macOS menu bar app that monitors for a global keyboard shortcut, grabs the currently selected text from anywhere on screen using the Accessibility API, translates it, and displays a sleek floating popup with the result.

---

## Design Decisions

| Question | Decision |
|---|---|
| Translation backend | **MyMemory free API** — no key needed, 5000 chars/day free |
| Language source | **Auto-detect** via `NLLanguageRecognizer` |
| Language target | User-configurable in Settings (default: English) |
| Hotkey | **⌘⇧T** (Cmd + Shift + T), listen-only (non-consuming) |
| Popup placement | Near mouse cursor, repositioned to stay on screen |
| Dismiss | Click outside or press Esc |

---

## Architecture

The app is a pure Swift/SwiftUI project with **no external package dependencies**.

### Key Constraints
- **Not sandboxed** — required for `CGEventTap` to intercept global keyboard events
- **LSUIElement = true** — menu-bar-only app, no Dock icon
- **Accessibility permission required** — for `kAXSelectedTextAttribute` and `CGEventTap`
- **Deployment target: macOS 12.0**

---

## Source Files

### App Entry & Orchestration

#### `Sources/TranslateApp.swift`
`@main` SwiftUI App entry point using `@NSApplicationDelegateAdaptor`. Provides an empty `Settings {}` scene to satisfy the App protocol; all real UI is driven by AppDelegate.

#### `Sources/AppDelegate.swift`
Core orchestrator (`@MainActor`):
- Creates **NSStatusItem** (menu bar icon, toggle, settings)
- Wires **HotkeyManager** callback
- On hotkey: shows loading popup → calls AccessibilityHelper → calls TranslationService → updates popup
- Manages the settings **NSWindow** (custom, not SwiftUI Settings scene for macOS 12 compat)

### Input

#### `Sources/HotkeyManager.swift`
Wraps `CGEventTap` with a **listen-only, non-consuming** tap on `.cgSessionEventTap`. Uses a `@convention(c)` callback with `refcon` (userInfo) to reach the Swift instance without a capturing closure.

#### `Sources/AccessibilityHelper.swift`
Two-step text extraction:
1. `AXUIElementCopyAttributeValue(focused, kAXSelectedTextAttribute)` — silent, no clipboard touch
2. Fallback: simulate `⌘C` via `CGEvent`, wait 200 ms, read `NSPasteboard`

### Translation

#### `Sources/TranslationService.swift`
- Detects source language with `NLLanguageRecognizer`
- Normalises Apple BCP-47 tags → ISO 639-1 (e.g. `zh-Hans` → `zh`)
- Calls `https://api.mymemory.translated.net/get?q=…&langpair=fr|en`
- Returns `TranslationResult` struct with original text, translation, detected language name/code, target code

### State

#### `Sources/PopupState.swift`
`@MainActor ObservableObject` with three phases: `.loading`, `.result`, `.error`. Mutated from `AppDelegate`; observed by `PopupView`.

### UI

#### `Sources/PopupWindowController.swift`
`@MainActor` class managing a single reusable `NSPanel`:
- **Background**: `NSVisualEffectView` (`.hudWindow` material, frosted glass)
- **Sizing**: calls `hostingView.fittingSize` after state changes, animates frame update
- **Positioning**: appears 12 pts below-right of cursor, clamped to visible screen area
- **Dismiss monitor**: `NSEvent.addGlobalMonitorForEvents` watching mouse-down and Esc

#### `Sources/PopupView.swift`
SwiftUI view with three states driven by `PopupState`:
- **Loading**: `ProgressView` + "Translating…"
- **Result**: language-pair pill row → optional source text → large translated text → copy button
- **Error**: orange warning icon + error message

#### `Sources/SettingsView.swift`
Four sections: Accessibility status (live poll), Target language picker, Display toggle (show source text), Shortcut display. Uses `SectionCard` and `KeyCap` sub-components.

### Support

#### `Sources/PermissionsManager.swift`
Polls `AXIsProcessTrusted()` every 2 seconds. Provides `requestPermission()` (shows OS dialog) and `openSettings()` (deep-links to Accessibility pane).

#### `Sources/AppSettings.swift`
`UserDefaults`-backed singleton: `isEnabled`, `targetLanguageCode`, `showSourceText`.

#### `Sources/LanguageOption.swift`
Static list of 27 languages with ISO codes and flag emojis.

---

## Configuration Files

| File | Purpose |
|---|---|
| `Info.plist` | `LSUIElement=true`, privacy usage descriptions, min OS 12.0 |
| `TranslateApp.entitlements` | `app-sandbox=false`, `network.client=true` |
| `TranslateApp.xcodeproj/` | Hand-written `project.pbxproj`, ad-hoc signing, Hardened Runtime off |
| `project.yml` | XcodeGen spec (alternative to hand-written pbxproj) |

---

## Build & Verification

```bash
# Build
xcodebuild -project TranslateApp.xcodeproj -scheme TranslateApp -configuration Debug build

# Result
# BUILD SUCCEEDED (Xcode 26.6, Swift 5.9)
```

### Manual Verification Steps
1. Build and run in Xcode (⌘R)
2. Grant Accessibility access when prompted
3. Open Safari, select some foreign text, press ⌘⇧T → popup appears near cursor
4. Verify loading → result transition with animation
5. Verify Esc and click-outside dismiss
6. Open Settings from menu bar → change target language → re-translate
7. Toggle Enable/Disable from menu bar → hotkey should do nothing when disabled
