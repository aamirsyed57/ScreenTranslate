# ScreenTranslate

> Select text anywhere on your Mac. Press your hotkey (default: **⌘⇧T**). Done.

A lightweight macOS menu-bar accessibility app that translates any selected text system-wide — in Safari, Mail, Terminal, PDFs, or any other app — using a customizable keyboard shortcut.

---

## Features

- 🌍 **Translate from anywhere** — works in every app that supports text selection
- ⌨️ **Customizable global hotkey** — record your own shortcut (e.g. `⌘⌥K`) to trigger translation instantly
- 🔍 **Auto-detects source language** — no need to tell it what language you're reading
- 💬 **Frosted-glass popup** — appears near your cursor, dismisses with `Esc` or a click outside
- 📋 **One-tap copy** — copy the translation to your clipboard from the popup
- 🎛️ **27 target languages** — English, Spanish, French, German, Japanese, Arabic, and more
- 🔒 **Privacy-first** — text is only sent to the translation API when you press the hotkey
- 🆓 **Free** — uses the [MyMemory](https://mymemory.translated.net) API, no account or API key required

---

## Requirements

- macOS 12.0 (Monterey) or later
- Xcode 15+ (to build from source)
- Accessibility permission (granted on first launch)

---

## Quick Start

### Option 1 — Run the pre-built binary

```bash
open ScreenTranslate.app
```

> Located in the project root. Grant Accessibility access when prompted, then start translating!

### Option 2 — Build from source

```bash
# Open in Xcode
open TranslateApp.xcodeproj

# Or build from the command line
xcodebuild -project TranslateApp.xcodeproj \
           -scheme TranslateApp \
           -configuration Debug \
           build
```

> **Note:** If you see a Xcode license error, run `sudo xcodebuild -license accept` first.

---

## Setup

1. **Launch the app** — a `⊕` bubble icon appears in the menu bar
2. **Grant Accessibility access** when prompted:
   `System Settings → Privacy & Security → Accessibility → ✅ ScreenTranslate`
3. That's it — start selecting text and pressing your hotkey.

---

## Usage

| Action | How |
|---|---|
| Translate selected text | Select text in any app → press your hotkey (default: `⌘⇧T`) |
| Copy the translation | Click **Copy Translation** in the popup |
| Dismiss the popup | Press `Esc` or click outside it |
| Change target language | Menu bar icon → **Settings…** |
| Record new shortcut | Menu bar icon → **Settings…** → Click on the hotkey badge and press new keys |
| Pause the app | Menu bar icon → **Enable Translation** (toggle off) |
| Quit | Menu bar icon → **Quit ScreenTranslate** |

---

## Architecture

```
Sources/
├── TranslateApp.swift          @main SwiftUI entry point
├── AppDelegate.swift           Status bar, orchestration
├── HotkeyManager.swift         Global CGEventTap (dynamic hotkey check)
├── ShortcutRecorderView.swift  Interactive keyboard shortcut recorder UI
├── AccessibilityHelper.swift   AX API text extraction + clipboard fallback
├── TranslationService.swift    MyMemory API + NLLanguageRecognizer
├── PopupState.swift            Observable state (loading / result / error)
├── PopupWindowController.swift NSPanel with NSVisualEffectView (frosted glass)
├── PopupView.swift             SwiftUI popup UI
├── SettingsView.swift          SwiftUI settings panel
├── PermissionsManager.swift    Accessibility permission polling
├── AppSettings.swift           UserDefaults-backed preferences & hotkey storage
└── LanguageOption.swift        27 supported languages
```

**Key technical choices:**

- **Not sandboxed** — required for `CGEventTap` global keyboard monitoring
- **`CGEventTap` listen-only** — the hotkey is observed but not consumed, so it still works in other apps
- **AX API first** — reads selection via `kAXSelectedTextAttribute` without touching the clipboard
- **Clipboard fallback** — simulates `⌘C` for apps that don't expose AX selection
- **Ad-hoc code signing** — no Apple Developer account needed to build and run

---

## Translation API

Uses the **[MyMemory Translated](https://mymemory.translated.net)** free API:
- No account or API key required
- 5,000 characters per day (anonymous usage)
- Source language is auto-detected on-device via Apple's `NLLanguageRecognizer`

To increase the daily limit, register a free account at mymemory.translated.net and add your email to the API request (see `TranslationService.swift`).

---

## Privacy

- No data is collected or stored by this app
- Selected text is sent **only** to the MyMemory translation API when you press the hotkey
- The app requires Accessibility permission solely to read your selected text; it does not monitor typing or other input

---

## Documentation

| Document | Description |
|---|---|
| [`WALKTHROUGH.md`](WALKTHROUGH.md) | Build results, testing notes, and next steps |
| [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md) | Architecture decisions and design rationale |

---

## License

MIT — do whatever you want with it.
