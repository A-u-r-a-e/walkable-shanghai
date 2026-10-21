import Foundation

/// The app runs in one language at a time, chosen by the user inside the app —
/// not inherited from the phone's system setting. That is a product decision
/// from the design: a bilingual Shanghai audience often wants the app in the
/// language they are *reading the city* in, which is not always their phone's.
///
/// The system setting is still used, but only to pick the initial value on a
/// first launch.
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english
    case chinese

    var id: String { rawValue }

    /// The `.lproj` folder name and `Locale` identifier this language resolves
    /// against. These must match the project's `knownRegions`.
    var localeIdentifier: String {
        switch self {
        case .english: return "en"
        case .chinese: return "zh-Hans"
        }
    }

    var locale: Locale { Locale(identifier: localeIdentifier) }

    /// Shown in the language switch. Each name is written in its own language,
    /// which is the convention for a language picker — a reader looking for
    /// Chinese should not have to read English to find it.
    var endonym: String {
        switch self {
        case .english: return "English"
        case .chinese: return "简体中文"
        }
    }

    /// The best match for the phone's current setting, used only on first
    /// launch. Anything not Chinese falls to English.
    static var systemDefault: AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("zh") ? .chinese : .english
    }
}
