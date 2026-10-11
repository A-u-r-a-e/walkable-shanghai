import XCTest
import SwiftData
import CoreLocation
@testable import WalkableShanghai

/// Finished walks and drawn routes: what gets stored, what survives, and the
/// arithmetic the summary screen reports.
@MainActor
final class WalkStoreTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        try UserStateContainer.make(inMemory: true)
    }

    private func loadCatalogue() throws -> SampleData {
        let hostBundle = Bundle(identifier: "com.walkableshanghai.app") ?? Bundle(for: Self.self)
        return try SampleDataLoader.load(from: hostBundle)
    }

    private let line = [
        CLLocationCoordinate2D(latitude: 31.2103, longitude: 121.4349),
        CLLocationCoordinate2D(latitude: 31.2126, longitude: 121.4337),
        CLLocationCoordinate2D(latitude: 31.2148, longitude: 121.4326),
    ]

    // MARK: - Walks

    func testAFinishedWalkIsStoredAndReadBackByANewStore() throws {
        let container = try makeContainer()
        let start = Date(timeIntervalSince1970: 1_770_000_000)

        let first = WalkStore(container: container)
        XCTAssertEqual(first.walkCount, 0, "a fresh store should hold no walks")

        first.record(
            routeId: "wukang",
            startedAt: start,
            endedAt: start.addingTimeInterval(3120),
            distanceMeters: 3400,
            elapsedSeconds: 3120,
            note: "Quiet before nine.",
            photo: nil
        )

        // A second store on the same container stands in for a relaunch.
        let reopened = WalkStore(container: container)
        XCTAssertEqual(reopened.walkCount, 1, "the walk did not survive a relaunch")
        let walk = try XCTUnwrap(reopened.walks.first)
        XCTAssertEqual(walk.routeId, "wukang")
        XCTAssertEqual(walk.distanceMeters, 3400, accuracy: 0.001)
        XCTAssertEqual(walk.note, "Quiet before nine.")
    }

    func testDoneStoresTheWalk() throws {
        let container = try UserStateContainer.make(inMemory: true)
        let store = WalkStore(container: container)
        store.record(
            routeId: "wukang",
            startedAt: Date(timeIntervalSince1970: 0),
            endedAt: Date(timeIntervalSince1970: 3_000),
            distanceMeters: 3_400,
            elapsedSeconds: 3_000,
            note: "",
            photo: nil
        )
        XCTAssertEqual(WalkStore(container: container).walkCount, 1)
    }

    func testAPhotoSurvivesTheRoundTrip() throws {
        let container = try makeContainer()
        let bytes = Data((0..<2048).map { UInt8($0 % 251) })

        let first = WalkStore(container: container)
        first.record(routeId: "wukang", startedAt: Date(), endedAt: Date(), distanceMeters: 100,
                     elapsedSeconds: 60, note: "", photo: bytes)

        let reopened = WalkStore(container: container)
        XCTAssertEqual(reopened.walks.first?.photo, bytes, "the photograph did not persist")
    }

    // MARK: - "km over your best"

    func testOverBestIsWithheldOnTheFirstEverWalk() throws {
        let store = WalkStore(container: try makeContainer())
        // Nothing to beat yet. Reporting the whole distance as an improvement
        // would be a lie, so this must be nil rather than a number.
        XCTAssertNil(store.metersOverBest(3400))
    }

    func testOverBestIsMeasuredAgainstThePreviousBest() throws {
        let store = WalkStore(container: try makeContainer())
        let now = Date()

        store.record(routeId: "a", startedAt: now, endedAt: now, distanceMeters: 2800,
                     elapsedSeconds: 1, note: "", photo: nil)
        store.record(routeId: "b", startedAt: now, endedAt: now, distanceMeters: 2100,
                     elapsedSeconds: 1, note: "", photo: nil)

        // Best so far is 2800.
        XCTAssertEqual(try XCTUnwrap(store.metersOverBest(3400)), 600, accuracy: 0.001)
        // A shorter walk reports a negative, not a hidden zero.
        XCTAssertEqual(try XCTUnwrap(store.metersOverBest(2000)), -800, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(store.bestDistanceMeters), 2800, accuracy: 0.001)
    }

    func testOverBestExcludesTheWalkBeingReportedOn() throws {
        let store = WalkStore(container: try makeContainer())
        let now = Date()
        store.record(routeId: "a", startedAt: now, endedAt: now, distanceMeters: 2000,
                     elapsedSeconds: 1, note: "", photo: nil)
        let latest = store.record(routeId: "b", startedAt: now, endedAt: now, distanceMeters: 5000,
                                  elapsedSeconds: 1, note: "", photo: nil)

        // Without the exclusion a stored walk would be compared against itself
        // and always report exactly zero.
        XCTAssertEqual(try XCTUnwrap(store.metersOverBest(5000, excluding: latest.id)), 3000, accuracy: 0.001)
    }

    // MARK: - Drawn routes

    func testADrawnRouteIsStoredAndSurvivesRelaunch() throws {
        let container = try makeContainer()

        let first = WalkStore(container: container)
        first.saveDraftRoute(name: "Evening loop", coordinates: line, tagKeys: ["green", "loop"])

        let reopened = WalkStore(container: container)
        XCTAssertEqual(reopened.draftRoutes.count, 1, "the drawn route did not survive a relaunch")
        let draft = try XCTUnwrap(reopened.draftRoutes.first)
        XCTAssertEqual(draft.name, "Evening loop")
        XCTAssertEqual(draft.coordinates.count, 3)
        XCTAssertEqual(draft.tagKeys.sorted(), ["green", "loop"])
        XCTAssertEqual(draft.coordinates[1].latitude, line[1].latitude, accuracy: 0.00001)
    }

    func testADrawnRouteBecomesAnOrdinaryRoute() throws {
        let store = WalkStore(container: try makeContainer())
        let draft = store.saveDraftRoute(name: "Evening loop", coordinates: line, tagKeys: ["green"])

        let route = draft.asRoute(authorName: "Ben Qiu", authorInitial: "邱")
        XCTAssertEqual(route.id, draft.id)
        XCTAssertEqual(route.name(.english), "Evening loop")
        XCTAssertGreaterThan(route.km, 0, "a drawn route should have a real distance")
        XCTAssertEqual(route.points.count, 3)
        // Route tags come from the fixed list the developers own, so the
        // walker's builder tags do not become route tags.
        XCTAssertTrue(route.tags.isEmpty)
        XCTAssertEqual(route.updatedAt, draft.createdAt)
        XCTAssertTrue(route.note(.english).isEmpty)
    }

    func testDrawnRoutesFollowTheCatalogueAndAreMarkedMine() throws {
        let container = try UserStateContainer.make(inMemory: true)
        let walks = WalkStore(container: container)
        _ = walks.saveDraftRoute(
            name: "Mine",
            coordinates: [
                CLLocationCoordinate2D(latitude: 31.21, longitude: 121.43),
                CLLocationCoordinate2D(latitude: 31.22, longitude: 121.44),
            ],
            tagKeys: []
        )
        let store = RouteStore()
        let catalogueCount = store.routes.count
        store.setDrawnRoutes(walks.draftRoutes, authorName: "Ben Qiu", authorInitial: "邱")

        XCTAssertEqual(store.routes.count, catalogueCount + 1)
        let drawn = try XCTUnwrap(store.routes.last)
        XCTAssertEqual(store.mineRouteIds, [drawn.id])
        XCTAssertTrue(drawn.tags.isEmpty)
    }

    func testTheCatalogueStillResolvesAfterMerging() throws {
        let routeStore = RouteStore()
        let store = WalkStore(container: try makeContainer())
        store.saveDraftRoute(name: "Mine", coordinates: line, tagKeys: [])
        routeStore.setDrawnRoutes(store.draftRoutes, authorName: "x", authorInitial: "x")

        // Merging must not shadow the bundled routes.
        XCTAssertNotNil(routeStore.route(id: "wukang"))
        XCTAssertEqual(routeStore.featuredRoute()?.id, "wukang")
    }

    // MARK: - Builder tags

    func testEveryBuilderTagIsBilingual() throws {
        for tag in BuilderTag.allCases {
            let en = L10n.string(tag.localizationKey, .english)
            let zh = L10n.string(tag.localizationKey, .chinese)
            XCTAssertFalse(en.contains("builder."), "\(tag) has no English string")
            XCTAssertFalse(zh.contains("builder."), "\(tag) has no Chinese string")
            XCTAssertNotEqual(en, zh, "\(tag) is not actually translated")
        }
        XCTAssertEqual(BuilderTag.allCases.count, 4)
    }
}
