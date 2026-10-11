import SwiftUI
import SwiftData

@main
struct WalkableShanghaiApp: App {

    /// Two app-wide stores, both created once and handed down through the
    /// environment. Neither holds screen state — `AppSettings` is the user's
    /// choices, `RouteStore` is where data comes from.
    @State private var settings = AppSettings()
    @State private var store: RouteStore
    /// Saved routes, persisted by SwiftData. Saving a route downloads it.
    @State private var savedRoutes: SavedRoutesStore

    @State private var tracking: TrackingSession
    /// Finished walks and drawn routes.
    @State private var walkStore: WalkStore
    /// Downloaded routes.
    @State private var offline: OfflineStore

    private let container: ModelContainer

    init() {
        Appearance.apply()

        let container = UserStateContainer.makeOrFallBack()
        self.container = container

        // The UI tests need a known starting state, and one of them needs the
        // opposite: to relaunch and find what the previous launch wrote. So the
        // reset is an explicit launch argument rather than something that
        // happens on every test launch.
        let arguments = ProcessInfo.processInfo.arguments
        let shouldReset = arguments.contains("-uitest.resetUserState")
        let offlineStore = OfflineStore(container: container, resetForTests: shouldReset)
        _offline = State(initialValue: offlineStore)
        let savedRoutesStore = SavedRoutesStore(container: container, offline: offlineStore, resetToSeed: shouldReset)
        _savedRoutes = State(initialValue: savedRoutesStore)

        // Tracking's location source is chosen once, here. A UI test asks for a
        // synthetic walk so the screen can be driven deterministically; every
        // other run gets CoreLocation. Nothing downstream knows the difference.
        let provider: LocationProviding
        if let index = arguments.firstIndex(of: "-uitest.simulateWalk"),
           index + 1 < arguments.count,
           let data = try? SampleDataLoader.load(),
           let route = data.routes.first(where: { $0.id == arguments[index + 1] }) {
            provider = SimulatedLocationProvider(route: route)
        } else {
            provider = CoreLocationProvider()
        }
        _tracking = State(initialValue: TrackingSession(provider: provider))

        let walkStore = WalkStore(container: container, resetForTests: shouldReset)
        _walkStore = State(initialValue: walkStore)

        // Drawn routes join the catalogue before the first screen draws, so a
        // route saved in a previous session is already on the map at launch.
        let routeStore = RouteStore()
        routeStore.setDrawnRoutes(
            walkStore.draftRoutes,
            authorName: routeStore.profile?.name ?? "",
            authorInitial: routeStore.profile?.initial ?? ""
        )
        _store = State(initialValue: routeStore)

        // A saved route is a downloaded route. The seeded routes, and any saved
        // before saving meant downloading, get their bytes built here.
        savedRoutesStore.ensureDownloads(routes: routeStore.routes)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(store)
                .environment(savedRoutes)
                .environment(tracking)
                .environment(walkStore)
                .environment(offline)
                .modelContainer(container)
        }
    }
}

/// UIKit-side chrome.
///
/// This used to repaint the tab bar and navigation bar in paper so they sat
/// flush with a print-inspired ground. The redesign hands them back to the
/// system: on iOS 26 that means Liquid Glass, on iOS 18 the standard translucent
/// bar, and on both it means the app's chrome matches every other app on the
/// phone. That is the point of moving to Apple's design language, and it also
/// retires the "known cosmetic deviation" the old override created on iOS 26.
///
/// Kept as a call site rather than deleted outright: the tint below is a real
/// decision, and a later phase may need somewhere to put bar-level appearance
/// again.
enum Appearance {
    static func apply() {
        // Selected tab items take the app's green rather than the system blue.
        // Navigation bar buttons stay neutral: a back button is chrome, not a
        // selected state or a primary action.
        UITabBar.appearance().tintColor = UIColor(Theme.accent)
        UINavigationBar.appearance().tintColor = UIColor(Theme.label)
    }
}
