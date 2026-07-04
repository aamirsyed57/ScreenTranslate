import Foundation
import NaturalLanguage

// MARK: - Result & Errors

struct TranslationResult {
    let originalText: String
    let translatedText: String
    let detectedSourceLanguage: String  // Human-readable, e.g. "French"
    let detectedSourceCode: String      // ISO code, e.g. "fr"
    let targetLanguageCode: String      // ISO code, e.g. "en"
}

enum TranslationError: LocalizedError {
    case emptyText
    case network(Error)
    case parsing
    case allBackendsFailed

    var errorDescription: String? {
        switch self {
        case .emptyText:          return "No text to translate."
        case .network(let e):    return "Network error: \(e.localizedDescription)"
        case .parsing:           return "Couldn't understand the translation response."
        case .allBackendsFailed: return "Translation failed. Check your internet connection and try again."
        }
    }
}

// MARK: - Service

final class TranslationService {
    static let shared = TranslationService()
    private init() {}

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        return URLSession(configuration: config)
    }()

    /// Translate `text` to `targetCode` (ISO 639-1).
    /// Tries Google Translate (unofficial, no key/limit) first, falls back to MyMemory.
    /// If `overrideSourceCode` is provided (e.g. 'auto' or 'fr'), it will use that instead of the setting.
    func translate(text: String, targetCode: String, overrideSourceCode: String? = nil) async throws -> TranslationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TranslationError.emptyText }

        let sourceSetting = overrideSourceCode ?? AppSettings.shared.sourceLanguageCode

        // 1️⃣  Primary: unofficial Google Translate endpoint — no API key, no daily limit
        if let result = try? await translateViaGoogle(text: trimmed, targetCode: targetCode, sourceSetting: sourceSetting) {
            return result
        }

        // 2️⃣  Fallback: MyMemory free API
        if let result = try? await translateViaMyMemory(text: trimmed, targetCode: targetCode, sourceSetting: sourceSetting) {
            return result
        }

        throw TranslationError.allBackendsFailed
    }

    // MARK: - Google Translate (unofficial)
    //
    // Uses the same public endpoint the browser widget calls.
    // Format: https://translate.googleapis.com/translate_a/single
    //         ?client=gtx&sl=auto&tl=<target>&dt=t&q=<text>
    // Response: [ [[translated, original], …], null, detectedLangCode, … ]

    private func translateViaGoogle(text: String, targetCode: String, sourceSetting: String) async throws -> TranslationResult {
        var comps = URLComponents(string: "https://translate.googleapis.com/translate_a/single")!
        comps.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl",     value: sourceSetting),
            URLQueryItem(name: "tl",     value: targetCode),
            URLQueryItem(name: "dt",     value: "t"),
            URLQueryItem(name: "q",      value: text),
        ]
        guard let url = comps.url else { throw TranslationError.parsing }

        let (data, _) = try await session.data(from: url)

        // Parse the nested JSON array
        guard let outer = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
            throw TranslationError.parsing
        }

        // Collect all translated segments from outer[0]
        guard let segments = outer[safe: 0] as? [[Any]] else { throw TranslationError.parsing }
        let translated = segments.compactMap { $0[safe: 0] as? String }.joined()
        guard !translated.isEmpty else { throw TranslationError.parsing }

        // Detected source language is at outer[2] (if auto), otherwise we use the requested sourceSetting
        let sourceCode = sourceSetting == "auto" ? ((outer[safe: 2] as? String) ?? detectLanguage(in: text)) : sourceSetting
        let sourceName = sourceCode == "auto" ? "Auto-detect" : (Locale(identifier: "en").localizedString(forLanguageCode: sourceCode) ?? sourceCode)

        return TranslationResult(
            originalText: text,
            translatedText: translated,
            detectedSourceLanguage: sourceName,
            detectedSourceCode: sourceCode,
            targetLanguageCode: targetCode
        )
    }

    // MARK: - MyMemory (fallback)

    private func translateViaMyMemory(text: String, targetCode: String, sourceSetting: String) async throws -> TranslationResult {
        let sourceCode = sourceSetting == "auto" ? detectLanguage(in: text) : sourceSetting
        let sourceName = sourceCode == "auto" ? "Auto-detect" : (Locale(identifier: "en").localizedString(forLanguageCode: sourceCode) ?? sourceCode)

        var comps = URLComponents(string: "https://api.mymemory.translated.net/get")!
        comps.queryItems = [
            URLQueryItem(name: "q",        value: text),
            URLQueryItem(name: "langpair", value: "\(sourceCode)|\(targetCode)"),
        ]
        guard let url = comps.url else { throw TranslationError.parsing }

        let (data, _) = try await session.data(from: url)

        guard
            let json       = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let respData   = json["responseData"] as? [String: Any],
            let translated = respData["translatedText"] as? String,
            !translated.uppercased().hasPrefix("MYMEMORY WARNING"),
            !translated.uppercased().contains("QUERY LENGTH LIMIT")
        else { throw TranslationError.parsing }

        return TranslationResult(
            originalText: text,
            translatedText: translated,
            detectedSourceLanguage: sourceName,
            detectedSourceCode: sourceCode,
            targetLanguageCode: targetCode
        )
    }

    // MARK: - Helpers

    private func detectLanguage(in text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let lang = recognizer.dominantLanguage?.rawValue else { return "auto" }
        return String(lang.prefix(2))
    }
}

// MARK: - Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

