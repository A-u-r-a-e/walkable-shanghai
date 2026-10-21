import XCTest
import SwiftData
@testable import JWalk

/// Unit tests for the state the walker owns, and for the Featured route flag.
///
/// These run against an in-memory SwiftData container, so they never touch the
/// simulator's real database and each test starts clean.
@MainActor
final class UserStateTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        try UserStateContainer.make(inMemory: true)
    }

    private func route(_ id: String) -> Route {
        RouteStore().route(id: id)!
    }

    /// The catalogue ships in the *app* bundle, not the test bundle, so the
    /// host has to be asked for it explicitly.
    private func loadCatalogue() throws -> SampleData {
        let hostBundle = Bundle(identifier: "com.jwalk.app") ?? Bundle(for: Self.self)
        return try SampleDataLoader.load(from: hostBundle)
    }

    // MARK: - Seeding

    func testAFreshStoreSeedsTheDesignedState() throws {
        let container = try makeContainer()
        let store = SavedRoutesStore(container: container, offline: OfflineStore(container: container))

        XCTAssertEqual(store.savedRouteIds, SavedRoutesStore.seededSaved)
    }

    func testSeedingHappensOnceNotOnEveryLaunch() throws {
        let container = try makeContainer()

        let first = SavedRoutesStore(container: container, offline: OfflineStore(container: container))
        first.toggleSaved(route("wukang"))   // now unsaved
        XCTAssertFalse(first.isSaved("wukang"))

        // A second store on the same container stands in for a relaunch. It
        // must not re-seed over the walker's choice.
        let second = SavedRoutesStore(container: container, offline: OfflineStore(container: container))
        XCTAssertFalse(
            second.isSaved("wukang"),
            "re-seeding overwrote a choice the walker had already made"
        )
        XCTAssertEqual(second.savedRouteIds, ["creek", "century"])
    }

    // MARK: - Toggling and persistence

    func testTogglesWriteThroughAndAreReadBackByANewStore() throws {
        let container = try makeContainer()

        let first = SavedRoutesStore(container: container, offline: OfflineStore(container: container))
        first.toggleSaved(route("bund"))     // seeded unsaved → saved
        XCTAssertTrue(first.isSaved("bund"))

        // This is the assertion the phase exists for: a different store reading
        // the same container sees what the first one wrote.
        let second = SavedRoutesStore(container: container, offline: OfflineStore(container: container))
        XCTAssertTrue(second.isSaved("bund"), "the saved flag did not persist")
        XCTAssertTrue(OfflineStore(container: container).hasBundle("bund"), "the download did not persist")
    }

    func testSavingDownloadsAndUnsavingDeletes() throws {
        let container = try UserStateContainer.make(inMemory: true)
        let offline = OfflineStore(container: container)
        let saved = SavedRoutesStore(container: container, offline: offline, resetToSeed: true)

        saved.setSaved(false, route: route("fuxing"))
        XCTAssertFalse(offline.hasBundle("fuxing"))

        saved.setSaved(true, route: route("fuxing"))
        XCTAssertTrue(saved.isSaved("fuxing"))
        XCTAssertTrue(offline.hasBundle("fuxing"))

        saved.setSaved(false, route: route("fuxing"))
        XCTAssertFalse(saved.isSaved("fuxing"))
        XCTAssertFalse(offline.hasBundle("fuxing"))
    }

    func testRemoveAllDownloadsAlsoClearsBookmarks() throws {
        let container = try UserStateContainer.make(inMemory: true)
        let offline = OfflineStore(container: container)
        let saved = SavedRoutesStore(container: container, offline: offline, resetToSeed: true)
        saved.ensureDownloads(routes: RouteStore().routes)
        XCTAssertFalse(offline.bundles.isEmpty)
        // A download left over from when downloading was separate from saving.
        offline.download(route: route("fuxing"))
        XCTAssertFalse(saved.isSaved("fuxing"))

        saved.removeAllDownloads()
        XCTAssertTrue(offline.bundles.isEmpty)
        XCTAssertFalse(offline.hasBundle("fuxing"))
        XCTAssertTrue(saved.savedRouteIds.isEmpty)
    }

    func testEnsureDownloadsDeletesDownloadsOfUnsavedRoutes() throws {
        let container = try UserStateContainer.make(inMemory: true)
        let offline = OfflineStore(container: container)
        let saved = SavedRoutesStore(container: container, offline: offline, resetToSeed: true)
        // fuxing is not saved, but an earlier version could have downloaded it.
        XCTAssertFalse(saved.isSaved("fuxing"))
        offline.download(route: route("fuxing"))
        XCTAssertTrue(offline.hasBundle("fuxing"))

        saved.ensureDownloads(routes: RouteStore().routes)
        XCTAssertFalse(offline.hasBundle("fuxing"))
        XCTAssertEqual(Set(offline.bundles.map(\.routeId)), saved.savedRouteIds)
    }

    func testEnsureDownloadsBacksEverySavedRoute() throws {
        let container = try UserStateContainer.make(inMemory: true)
        let offline = OfflineStore(container: container)
        let saved = SavedRoutesStore(container: container, offline: offline, resetToSeed: true)
        saved.ensureDownloads(routes: RouteStore().routes)
        XCTAssertEqual(Set(offline.bundles.map(\.routeId)), saved.savedRouteIds)
    }

    func testTogglingARouteWithNoRowYetCreatesOne() throws {
        let container = try makeContainer()
        let store = SavedRoutesStore(container: container, offline: OfflineStore(container: container))

        // The seed writes rows only for the saved routes, so "bund" has none
        // yet. Saving it proves the create path works.
        XCTAssertFalse(store.isSaved("bund"))
        store.toggleSaved(route("bund"))
        XCTAssertTrue(store.isSaved("bund"))

        let reopened = SavedRoutesStore(container: container, offline: OfflineStore(container: container))
        XCTAssertTrue(reopened.isSaved("bund"))
    }

    func testResetToSeedRestoresTheDesignedState() throws {
        let container = try makeContainer()

        let dirty = SavedRoutesStore(container: container, offline: OfflineStore(container: container))
        dirty.toggleSaved(route("wukang"))
        dirty.toggleSaved(route("bund"))
        XCTAssertNotEqual(dirty.savedRouteIds, SavedRoutesStore.seededSaved)

        let reset = SavedRoutesStore(container: container, offline: OfflineStore(container: container), resetToSeed: true)
        XCTAssertEqual(reset.savedRouteIds, SavedRoutesStore.seededSaved)
    }

    // MARK: - Featured route

    /// The featured route is resolved from the route's `featured` tag, not
    /// from anything stored beside the catalogue. If that ever stops being
    /// true, this fails.
    func testFeaturedRouteComesFromTheTag() throws {
        let data = try loadCatalogue()
        let source = BundledDataSource(data: data)

        let flagged = data.routes.filter(\.isFeatured)
        XCTAssertEqual(flagged.count, 1, "exactly one route should carry the featured tag")
        XCTAssertEqual(source.featuredRoute()?.id, flagged.first?.id)
    }
}
