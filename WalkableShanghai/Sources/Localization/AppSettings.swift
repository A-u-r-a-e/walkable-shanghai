import Foundation
import Observation

/// App-wide user settings. Small on purpose — right now it holds the language
/// and whether onboarding has been seen.
///
/// Uses `@Observable` rather than `ObservableObject`: views that read
/// `language` re-render when it changes, and views that do not, do not.
@Observable
final class AppSettings {

    private enum Key {
        static let language = "settings.language"
        static let hasSeenOnboarding = "settings.hasSeenOnboarding"
    }

    private let defaults: UserDefaults

    /// The language the whole app renders in. Changing this re-renders every
    /// screen immediately — there is no restart and no reload.
    var language: AppLanguage {
        didSet {
            guard language != oldValue else { return }
            defaults.set(language.rawValue, forKey: Key.language)
        }
    }

    var hasSeenOnboarding: Bool {
        didSet {
            guard hasSeenOnboarding != oldValue else { return }
            defaults.set(hasSeenOnboarding, forKey: Key.hasSeenOnboarding)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // First launch takes the phone's language as a starting point; after
        // that the user's own choice wins, even if it disagrees with the phone.
        if let stored = defaults.string(forKey: Key.language),
           let known = AppLanguage(rawValue: stored) {
            self.language = known
        } else {
            self.language = AppLanguage.systemDefault
        }
        self.hasSeenOnboarding = defaults.bool(forKey: Key.hasSeenOnboarding)
    }

    /// Convenience for the language switch control.
    func select(_ language: AppLanguage) {
        self.language = language
    }
}
