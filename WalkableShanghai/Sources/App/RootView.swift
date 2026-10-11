import SwiftUI

/// Decides between onboarding and the tab shell, and owns the presentations
/// that sit above the tabs.
///
/// Route builder is a full-screen cover rather than a tab or a push, because it
/// is reachable from two unrelated places (onboarding and, later, the profile)
/// and because drawing a route should not leave a tab bar underneath. That
/// matches how Phase 5 will build it for real.
struct RootView: View {

    @Environment(AppSettings.self) private var settings

    @State private var selectedTab: MainTabView.Tab = .map
    @State private var isShowingBuilder = false

    var body: some View {
        let language = settings.language

        Group {
            if settings.hasSeenOnboarding {
                MainTabView(selection: $selectedTab)
            } else {
                OnboardingView(
                    onFindRoute: {
                        selectedTab = .map
                        settings.hasSeenOnboarding = true
                    },
                    onShareRoute: {
                        selectedTab = .map
                        settings.hasSeenOnboarding = true
                        isShowingBuilder = true
                    }
                )
            }
        }
        // Set for date, number and measurement formatting. Interface strings are
        // resolved explicitly through `L10n` instead — see the note there for
        // why we do not rely on this for lookup.
        .environment(\.locale, language.locale)
        // The app follows the system appearance. Every colour in `Theme` is
        // adaptive, so there is nothing here to force — and forcing light, as
        // this line used to, is exactly what stopped dark mode working.
        // "Share a route you know" from onboarding lands straight in the
        // builder. Phase 5 replaced the placeholder that used to sit here; the
        // builder brings its own back button, so no toolbar is needed.
        .fullScreenCover(isPresented: $isShowingBuilder) {
            NavigationStack { RouteBuilderScreen() }
        }
    }
}
