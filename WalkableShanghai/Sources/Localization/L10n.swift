import Foundation

/// Interface-string lookup.
///
/// Why this exists rather than plain `Text("some.key")`: SwiftUI resolves a
/// `LocalizedStringKey` against the *bundle's* preferred localisation, which
/// follows the phone's language setting. Our language is an in-app choice that
/// can disagree with the phone, so we resolve explicitly against the `.lproj`
/// bundle for the chosen language instead. That behaviour is deterministic and
/// does not depend on how SwiftUI happens to treat the environment locale.
///
/// The environment locale is *also* set at the root (see `RootView`), because
/// dates, numbers and measurements still need it for formatting.
///
/// This is the single choke point for interface strings. Content strings —
/// route names, walker notes — are data, not resources, and go through
/// `LocalizedText` instead.
enum L10n {

    private static let cache = BundleCache()

    static func string(_ key: String, _ language: AppLanguage) -> String {
        NSLocalizedString(key, bundle: cache.bundle(for: language), value: key, comment: "")
    }

    /// Interpolating variant, for the handful of strings with a value in them.
    static func string(_ key: String, _ language: AppLanguage, _ arguments: CVarArg...) -> String {
        String(format: string(key, language), arguments: arguments)
    }

    /// Counting variant: picks the right plural form for the chosen language.
    ///
    /// Two things make this its own entry point rather than a special case of
    /// the one above. First, plural forms live in the String Catalog as
    /// *variations*, which compile to a format carrying a plural token — only
    /// `String(format:locale:)` resolves that token, plain interpolation leaves
    /// it in the string. Second, the locale passed must be **the app's**, not
    /// the phone's: this app can run in Chinese on an English phone, and the
    /// phone's locale would then apply English plural rules to Chinese text.
    ///
    /// Chinese has one form for every count, English has two. Both are declared
    /// in the catalogue, so neither is decided here.
    static func string(_ key: String, _ language: AppLanguage, count: Int) -> String {
        String(format: string(key, language), locale: language.locale, count)
    }

    private final class BundleCache: @unchecked Sendable {
        private var bundles: [AppLanguage: Bundle] = [:]
        private let lock = NSLock()

        func bundle(for language: AppLanguage) -> Bundle {
            lock.lock()
            defer { lock.unlock() }
            if let cached = bundles[language] { return cached }
            let resolved = Self.load(language)
            bundles[language] = resolved
            return resolved
        }

        /// Falls back through `zh-Hans` → `zh` → main bundle, so a missing
        /// `.lproj` degrades to the development language instead of crashing.
        private static func load(_ language: AppLanguage) -> Bundle {
            let candidates: [String]
            switch language {
            case .english: candidates = ["en", "Base"]
            case .chinese: candidates = ["zh-Hans", "zh-Hans-CN", "zh"]
            }
            for name in candidates {
                if let path = Bundle.main.path(forResource: name, ofType: "lproj"),
                   let bundle = Bundle(path: path) {
                    return bundle
                }
            }
            return .main
        }
    }
}

extension String {
    /// `"onboarding.headline".localized(language)`
    func localized(_ language: AppLanguage) -> String {
        L10n.string(self, language)
    }

    /// `"placeholder.phase".localized(language, "5")` — for the few strings that
    /// carry a value.
    func localized(_ language: AppLanguage, _ arguments: CVarArg...) -> String {
        String(format: L10n.string(self, language), arguments: arguments)
    }

    /// `"saved.count".localized(language, count: 1)` → "1 route", not "1 routes".
    func localized(_ language: AppLanguage, count: Int) -> String {
        L10n.string(self, language, count: count)
    }
}
