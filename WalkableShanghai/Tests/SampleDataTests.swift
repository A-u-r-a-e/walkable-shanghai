import XCTest
@testable import WalkableShanghai

/// Phase 1's acceptance test: the bundled catalogue decodes, and it contains
/// what the mockup contained.
///
/// These counts are not arbitrary — they are the five routes, four walker notes,
/// three feed posts and two collections defined in the source design. If a
/// future edit to `SampleData.json` breaks the shape or drops a record, this
/// fails before anyone opens the simulator.
final class SampleDataTests: XCTestCase {

    private var data: SampleData!

    override func setUpWithError() throws {
        // The app bundle, not the test bundle: the JSON ships with the app.
        let appBundle = Bundle(for: type(of: self))
        let hostBundle = Bundle(identifier: "com.walkableshanghai.app") ?? appBundle
        data = try SampleDataLoader.load(from: hostBundle)
    }

    func testCatalogueDecodesWithExpectedCounts() {
        XCTAssertEqual(data.routes.count, 5, "five routes came from the mockup")
        XCTAssertEqual(data.comments.count, 4, "four walker notes came from the mockup")
        XCTAssertEqual(data.posts.count, 3, "three feed posts came from the mockup")
        XCTAssertEqual(data.collections.count, 2, "two collections came from the mockup")
    }

    func testEveryRouteIsFullyBilingual() {
        for route in data.routes {
            XCTAssertFalse(route.name.en.isEmpty, "\(route.id) is missing an English name")
            XCTAssertFalse(route.name.zh.isEmpty, "\(route.id) is missing a Chinese name")
            XCTAssertFalse(route.note.en.isEmpty, "\(route.id) is missing an English note")
            XCTAssertFalse(route.note.zh.isEmpty, "\(route.id) is missing a Chinese note")
            XCTAssertFalse(route.area.en.isEmpty, "\(route.id) is missing an English area")
            XCTAssertFalse(route.area.zh.isEmpty, "\(route.id) is missing a Chinese area")
        }
    }

    func testExactlyOneFeaturedRoute() {
        let featured = data.routes.filter(\.isFeatured)
        XCTAssertEqual(featured.count, 1, "the Featured screen shows exactly one route")
        XCTAssertEqual(featured.first?.id, "wukang")
    }

    func testEveryRouteHasDrawableGeometry() {
        for route in data.routes {
            XCTAssertGreaterThan(route.points.count, 1, "\(route.id) needs at least two points to draw a line")
            for point in route.points {
                // Shanghai, loosely bounded. Catches a lat/lng swap, which is
                // the failure mode that otherwise shows up as an empty map.
                XCTAssertTrue((30.6...31.9).contains(point.lat), "\(route.id) has a latitude outside Shanghai")
                XCTAssertTrue((120.8...122.2).contains(point.lng), "\(route.id) has a longitude outside Shanghai")
            }
        }
    }

    func testEveryReferenceResolves() {
        let routeIds = Set(data.routes.map(\.id))
        for comment in data.comments {
            XCTAssertTrue(routeIds.contains(comment.routeId), "comment \(comment.id) points at a missing route")
        }
        for post in data.posts {
            XCTAssertTrue(routeIds.contains(post.routeId), "post \(post.id) points at a missing route")
        }
        for collection in data.collections {
            for id in collection.routeIds {
                XCTAssertTrue(routeIds.contains(id), "collection \(collection.id) points at a missing route")
            }
        }
    }

    func testCollectionTotalsAreComputedNotStored() {
        let store = RouteStore()
        guard let concession = store.collections().first(where: { $0.id == "concession" }) else {
            return XCTFail("expected the concession collection")
        }
        // wukang 3.4 + fuxing 2.1 + bund 2.9
        XCTAssertEqual(store.totalKm(of: concession), 8.4, accuracy: 0.001)
    }

    func testBothLanguagesResolveInterfaceStrings() {
        // Proves the String Catalog compiled into both .lproj bundles and that
        // the explicit lookup finds them. A missing key returns the key itself.
        let english = "onboarding.headline".localized(.english)
        let chinese = "onboarding.headline".localized(.chinese)

        XCTAssertNotEqual(english, "onboarding.headline", "English lookup fell through to the key")
        XCTAssertNotEqual(chinese, "onboarding.headline", "Chinese lookup fell through to the key")
        XCTAssertNotEqual(english, chinese, "both languages resolved to the same string")
    }
}
