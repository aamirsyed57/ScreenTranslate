# Translate — macOS Accessibility App

A native macOS menu-bar app that translates any selected text system-wide using a global keyboard shortcut.

## ✅ Build Status: Succeeded

Built with **Xcode 26.6** — `BUILD SUCCEEDED` (1 non-fatal warning).

---

## Project Layout

```
Translate/
├── TranslateApp.xcodeproj/      ← Open in Xcode
├── Sources/
│   ├── TranslateApp.swift       ← @main entry point
│   ├── AppDelegate.swift        ← Status bar, hotkey, orchestration
│   ├── HotkeyManager.swift      ← Global CGEventTap (⌘⇧T)
│   ├── AccessibilityHelper.swift← AX API + clipboard fallback
│   ├── TranslationService.swift ← MyMemory free API
│   ├── PopupState.swift         ← Observable popup state
│   ├── PopupWindowController.swift ← Frosted glass panel
│   ├── PopupView.swift          ← SwiftUI result/loading/error UI
│   ├── SettingsView.swift       ← Settings panel UI
│   ├── PermissionsManager.swift ← Polls AXIsProcessTrusted()
│   ├── AppSettings.swift        ← UserDefaults-backed settings
│   └── LanguageOption.swift     ← 27 languages with flags
├── Info.plist                   ← LSUIElement=true (menu bar only)
├── TranslateApp.entitlements    ← No sandbox, network client
└── ScreenTranslate.app                ← Pre-built debug binary
```

---

## How to Use

### First Launch

1. **Run the app** — double-click `ScreenTranslate.app` in the project folder, or press **⌘R** in Xcode.
2. **Grant Accessibility access** — the app will immediately prompt you. Go to:
   **System Settings → Privacy & Security → Accessibility → enable Translate**
3. A **`⊕` bubble icon** appears in your menu bar.

### Translating Text

1. Select any text in **any app** (Safari, Mail, Terminal, PDF viewer, etc.)
2. Press **⌘⇧T** (Cmd + Shift + T)
3. A frosted-glass popup appears near your cursor with the translation

### Popup Controls
- Click **Copy Translation** to copy the result to your clipboard
- Press **Esc** or click anywhere outside to dismiss
- Original text and detected source language are shown above the translation

### Menu Bar
- **Enable Translation** — toggle the app on/off
- **Settings…** — change target language, show/hide source text, view shortcut

---

## Open in Xcode

```bash
open TranslateApp.xcodeproj
```

> **Xcode License**: If you haven't accepted the Xcode license yet, run this in Terminal before building:
> ```
> sudo xcodebuild -license accept
> ```

---

## Technical Details

| Component | Approach |
|---|---|
| Global hotkey | `CGEventTap` (listen-only, non-consuming) |
| Text extraction | `kAXSelectedTextAttribute` → clipboard fallback |
| Translation | [MyMemory free API](https://mymemory.translated.net) (5000 chars/day, no key) |
| Language detection | `NLLanguageRecognizer` (on-device, instant) |
| Popup UI | `NSPanel` + `NSVisualEffectView` (frosted glass) + SwiftUI |
| Settings | `UserDefaults` + SwiftUI |
| Code signing | Ad-hoc (`-`) — no Apple Developer account needed |

---

## What's Tested

- ✅ Compiles clean with Xcode 26.6 (Swift 5.9)
- ✅ `ScreenTranslate.app` binary produced and runs
- 🔲 Live accessibility grant → translation flow (manual test needed)
- 🔲 Safari, Notes, Chrome text selection (manual test needed)

---

## Possible Next Steps

- Add **custom hotkey** picker in Settings
- Add **history** panel of recent translations
- Add **auto-dismiss** timer option
- Add **menu bar extra** (macOS 13+) for a richer status menu
- Upgrade translation backend to **DeepL** (better quality, free API key)
- Support **text-to-speech** of the translation result
