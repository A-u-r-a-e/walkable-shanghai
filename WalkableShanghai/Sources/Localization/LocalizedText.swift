import Foundation

/// A piece of *content* that exists in both languages at once.
///
/// This is the important distinction in this app: route names, areas, kickers,
/// tags, walker notes and comment bodies are data, and every record carries
/// both an English and a Chinese version. They are not interface strings and do
/// not belong in the String Catalog — a route added next year will arrive from
/// the server with both fields filled in, not from a `.xcstrings` file.
///
/// In the source mockup these appeared as paired `…En` / `…Zh` keys.
struct LocalizedText: Codable, Hashable, Sendable {
    let en: String
    let zh: String

    init(en: String, zh: String) {
        self.en = en
        self.zh = zh
    }

    func callAsFunction(_ language: AppLanguage) -> String {
        resolved(language)
    }

    func resolved(_ language: AppLanguage) -> String {
        switch language {
        case .english: return en
        case .chinese: return zh
        }
    }

    /// True when this text carries nothing in either language. Used for the
    /// optional fields — a comment's pinned place, for instance — where an empty
    /// value means "hide the row" rather than "show a blank".
    var isEmpty: Bool { en.isEmpty && zh.isEmpty }
}
