import SwiftUI

/// The two-tab shell: the map, and the walker's own settings.
///
/// Each tab owns its own `NavigationStack`, so a push inside one does not
/// disturb the other.
struct MainTabView: View {

    @Environment(AppSettings.self) private var settings

    enum Tab: Hashable { case map, you }

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
                ProfileScreen()
            }
            .tabItem {
                Label("tab.you".localized(language), systemImage: "person")
            }
            .tag(Tab.you)
        }
        .tint(Theme.accent)
    }
}
