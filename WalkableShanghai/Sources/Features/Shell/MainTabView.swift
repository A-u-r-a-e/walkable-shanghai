import SwiftUI

/// The two-tab shell: the map, and the walker's own settings.
///
/// Each tab owns its own `NavigationStack`, so a push inside one does not
/// disturb the other.
struct MainTabView: View {

    @Environment(AppSettings.self) private var settings

    enum Tab: Hashable { case map, me }

    @Binding var selection: Tab

    var body: some View {
        let language = settings.language

        TabView(selection: $selection) {
            NavigationStack {
                MapDiscoverScreen()
            }
            .tabItem {
                Label("tab.map".localized(language), systemImage: "map")
            }
            .tag(Tab.map)

            NavigationStack {
                MeScreen()
            }
            // The tab view's green would otherwise reach the back buttons and
            // dialog actions here; on iOS 18 it outranks the navigation bar's
            // appearance tint. Green is for selected states and primary actions.
            .tint(Theme.label)
            .tabItem {
                Label("tab.me".localized(language), systemImage: "person")
            }
            .tag(Tab.me)
        }
        .tint(Theme.accent)
    }
}
