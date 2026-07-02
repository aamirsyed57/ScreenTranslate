import Foundation

struct LanguageOption: Identifiable, Hashable {
    let id: String  // ISO 639-1 code
    let name: String
    let flag: String

    static let all: [LanguageOption] = [
        LanguageOption(id: "en", name: "English",              flag: "🇬🇧"),
        LanguageOption(id: "es", name: "Spanish",              flag: "🇪🇸"),
        LanguageOption(id: "fr", name: "French",               flag: "🇫🇷"),
        LanguageOption(id: "de", name: "German",               flag: "🇩🇪"),
        LanguageOption(id: "it", name: "Italian",              flag: "🇮🇹"),
        LanguageOption(id: "pt", name: "Portuguese",           flag: "🇵🇹"),
        LanguageOption(id: "ru", name: "Russian",              flag: "🇷🇺"),
        LanguageOption(id: "ja", name: "Japanese",             flag: "🇯🇵"),
        LanguageOption(id: "ko", name: "Korean",               flag: "🇰🇷"),
        LanguageOption(id: "zh", name: "Chinese (Simplified)", flag: "🇨🇳"),
        LanguageOption(id: "ar", name: "Arabic",               flag: "🇸🇦"),
        LanguageOption(id: "hi", name: "Hindi",                flag: "🇮🇳"),
        LanguageOption(id: "nl", name: "Dutch",                flag: "🇳🇱"),
        LanguageOption(id: "pl", name: "Polish",               flag: "🇵🇱"),
        LanguageOption(id: "tr", name: "Turkish",              flag: "🇹🇷"),
        LanguageOption(id: "sv", name: "Swedish",              flag: "🇸🇪"),
        LanguageOption(id: "da", name: "Danish",               flag: "🇩🇰"),
        LanguageOption(id: "fi", name: "Finnish",              flag: "🇫🇮"),
        LanguageOption(id: "nb", name: "Norwegian",            flag: "🇳🇴"),
        LanguageOption(id: "uk", name: "Ukrainian",            flag: "🇺🇦"),
        LanguageOption(id: "cs", name: "Czech",                flag: "🇨🇿"),
        LanguageOption(id: "ro", name: "Romanian",             flag: "🇷🇴"),
        LanguageOption(id: "hu", name: "Hungarian",            flag: "🇭🇺"),
        LanguageOption(id: "el", name: "Greek",                flag: "🇬🇷"),
        LanguageOption(id: "th", name: "Thai",                 flag: "🇹🇭"),
        LanguageOption(id: "vi", name: "Vietnamese",           flag: "🇻🇳"),
        LanguageOption(id: "id", name: "Indonesian",           flag: "🇮🇩"),
    ]

    static func find(code: String) -> LanguageOption? {
        all.first { $0.id == code }
    }
}
