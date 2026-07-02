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
    case quotaExceeded

    var errorDescription: String? {
        switch self {
        case .emptyText:       return "No text to translate."
        case .network(let e): return "Network error: \(e.localizedDescription)"
        case .parsing:        return "Couldn't understand the translation response."
        case .quotaExceeded:  return "Daily free quota exceeded. Try again tomorrow."
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
    func translate(text: String, targetCode: String) async throws -> TranslationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TranslationError.emptyText }

        // Detect source language
        let sourceCode = detectLanguage(in: trimmed)
        let sourceName = Locale(identifier: "en").localizedString(forLanguageCode: sourceCode) ?? sourceCode

        // Build MyMemory API request
        // https://mymemory.translated.net/doc/spec.php
        var comps = URLComponents(string: "https://api.mymemory.translated.net/get")!
        comps.queryItems = [
            URLQueryItem(name: "q",        value: trimmed),
            URLQueryItem(name: "langpair", value: "\(sourceCode)|\(targetCode)"),
        ]
        guard let url = comps.url else { throw TranslationError.parsing }

        do {
            let (data, _) = try await session.data(from: url)
            return try parse(data: data,
                             originalText: trimmed,
                             sourceCode: sourceCode,
                             sourceName: sourceName,
                             targetCode: targetCode)
        } catch let error as TranslationError {
            throw error
        } catch {
            throw TranslationError.network(error)
        }
    }

    // MARK: - Helpers

    private func detectLanguage(in text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let lang = recognizer.dominantLanguage?.rawValue else { return "auto" }
        // Normalise BCP-47 → ISO 639-1 (e.g. "zh-Hans" → "zh", "pt-BR" → "pt")
        return String(lang.prefix(2))
    }

    private func parse(data: Data,
                       originalText: String,
                       sourceCode: String,
                       sourceName: String,
                       targetCode: String) throws -> TranslationResult {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let responseData = json["responseData"] as? [String: Any],
            let translated = responseData["translatedText"] as? String
        else { throw TranslationError.parsing }

        // MyMemory returns "QUERY LENGTH LIMIT EXCEDEED" for oversized requests
        if translated.uppercased().contains("QUERY LENGTH LIMIT") {
            throw TranslationError.quotaExceeded
        }

        // MyMemory returns "MYMEMORY WARNING" strings on quota exhaustion
        if translated.uppercased().hasPrefix("MYMEMORY WARNING") {
            throw TranslationError.quotaExceeded
        }

        return TranslationResult(
            originalText: originalText,
            translatedText: translated,
            detectedSourceLanguage: sourceName,
            detectedSourceCode: sourceCode,
            targetLanguageCode: targetCode
        )
    }
}
