import SwiftUI

/// The four-tab shell.
///
/// Tabs match the source design's bottom bar exactly: Map, Community, Saved,
/// You. Each owns its own `NavigationStack`, so a push inside one tab does not
/// disturb the others — that is what the source's single global back stack was
/// approximating, and it is the native behaviour readers expect.
struct MainTabView: View {

    @Environment(AppSettings.self) private var settings

    enum Tab: Hashable { case map, community, saved, you }

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
                FeedScreen()
            }
            .tabItem {
                Label("tab.community".localized(language), systemImage: "person.2")
            }
            .tag(Tab.community)

            NavigationStack {
                SavedScreen()
            }
            .tabItem {
                Label("tab.saved".localized(language), systemImage: "bookmark")
            }
            .tag(Tab.saved)

            NavigationStack {
                // The Saved tab is a sibling, not a push, so switching to it
                // is handed back here rather than done from inside the screen.
                ProfileScreen(onOpenSaved: { selection = .saved })
            }
            .tabItem {
                Label("tab.you".localized(language), systemImage: "person")
            }
            .tag(Tab.you)
        }
        // Green selection, per the rule that the accent marks state rather than
        // decorating the chrome.
        .tint(Theme.accent)
    }
}
