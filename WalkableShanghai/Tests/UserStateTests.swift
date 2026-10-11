import XCTest
import SwiftData
@testable import WalkableShanghai

/// Unit tests for the state the walker owns, and for the Featured route flag.
///
/// These run against an in-memory SwiftData container, so they never touch the
/// simulator's real database and each test starts clean.
final class UserStateTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        try UserStateContainer.make(inMemory: true)
    }

    /// The catalogue ships in the *app* bundle, not the test bundle, so the
    /// host has to be asked for it explicitly.
    private func loadCatalogue() throws -> SampleData {
        let hostBundle = Bundle(identifier: "com.walkableshanghai.app") ?? Bundle(for: Self.self)
        return try SampleDataLoader.load(from: hostBundle)
    }

    // MARK: - Seeding

    func testAFreshStoreSeedsTheDesignedState() throws {
        let store = SavedRoutesStore(container: try makeContainer())

        XCTAssertEqual(store.savedRouteIds, ["wukang", "creek", "century"])
        XCTAssertEqual(store.offlineRouteIds, ["fuxing", "wukang"])
        XCTAssertEqual(store.savedCount, 3)
        XCTAssertEqual(store.offlineCount, 2)
    }

    func testSeedingHappensOnceNotOnEveryLaunch() throws {
        let container = try makeContainer()

        let first = SavedRoutesStore(container: container)
        first.toggleSaved("wukang")          // now unsaved
        XCTAssertFalse(first.isSaved("wukang"))

        // A second store on the same container stands in for a relaunch. It
        // must not re-seed over the walker's choice.
        let second = SavedRoutesStore(container: container)
        XCTAssertFalse(
            second.isSaved("wukang"),
            "re-seeding overwrote a choice the walker had already made"
        )
        XCTAssertEqual(second.savedRouteIds, ["creek", "century"])
    }

    // MARK: - Toggling and persistence

    func testTogglesWriteThroughAndAreReadBackByANewStore() throws {
        let container = try makeContainer()

        let first = SavedRoutesStore(container: container)
        first.toggleSaved("bund")            // seeded unsaved → saved
        first.toggleOffline("bund")          // seeded not-offline → offline
        XCTAssertTrue(first.isSaved("bund"))
        XCTAssertTrue(first.isOffline("bund"))

        // This is the assertion the phase exists for: a different store reading
        // the same container sees what the first one wrote.
        let second = SavedRoutesStore(container: container)
        XCTAssertTrue(second.isSaved("bund"), "the saved flag did not persist")
        XCTAssertTrue(second.isOffline("bund"), "the offline flag did not persist")
    }

    func testSavedAndOfflineAreIndependent() throws {
        let store = SavedRoutesStore(container: try makeContainer())

        // fuxing is seeded offline but not saved, which is the case that would
        // break if the two flags shared one row-level boolean.
        XCTAssertTrue(store.isOffline("fuxing"))
        XCTAssertFalse(store.isSaved("fuxing"))

        store.toggleSaved("fuxing")
        XCTAssertTrue(store.isSaved("fuxing"))
        XCTAssertTrue(store.isOffline("fuxing"), "saving a route should not change its offline flag")
    }

    func testTogglingARouteWithNoRowYetCreatesOne() throws {
        let container = try makeContainer()
        let store = SavedRoutesStore(container: container)

        // "bund" and "century" have rows from the seed; a route that is in
        // neither seeded set still has a row because the seed inserts the union.
        // Use an id outside the catalogue to prove the create path works.
        XCTAssertFalse(store.isSaved("some-new-route"))
        store.toggleSaved("some-new-route")
        XCTAssertTrue(store.isSaved("some-new-route"))

        let reopened = SavedRoutesStore(container: container)
        XCTAssertTrue(reopened.isSaved("some-new-route"))
    }

    func testResetToSeedRestoresTheDesignedState() throws {
        let container = try makeContainer()

        let dirty = SavedRoutesStore(container: container)
        dirty.toggleSaved("wukang")
        dirty.toggleSaved("bund")
        XCTAssertNotEqual(dirty.savedRouteIds, SavedRoutesStore.seededSaved)

        let reset = SavedRoutesStore(container: container, resetToSeed: true)
        XCTAssertEqual(reset.savedRouteIds, SavedRoutesStore.seededSaved)
        XCTAssertEqual(reset.offlineRouteIds, SavedRoutesStore.seededOffline)
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
