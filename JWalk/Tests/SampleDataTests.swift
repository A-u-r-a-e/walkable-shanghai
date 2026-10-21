import XCTest
@testable import JWalk

/// Phase 1's acceptance test: the bundled catalogue decodes, and it contains
/// what the mockup contained.
///
/// The count is not arbitrary — it is the five routes defined in the source
/// design. If a future edit to `SampleData.json` breaks the shape or drops a
/// record, this fails before anyone opens the simulator.
final class SampleDataTests: XCTestCase {

    private var data: SampleData!

    override func setUpWithError() throws {
        // The app bundle, not the test bundle: the JSON ships with the app.
        let appBundle = Bundle(for: type(of: self))
        let hostBundle = Bundle(identifier: "com.jwalk.app") ?? appBundle
        data = try SampleDataLoader.load(from: hostBundle)
    }

    func testCatalogueDecodesWithExpectedCounts() {
        XCTAssertEqual(data.routes.count, 5, "five routes came from the mockup")
    }

    func testEveryRouteIsFullyBilingual() {
        for route in data.routes {
            XCTAssertFalse(route.name.en.isEmpty, "\(route.id) is missing an English name")
            XCTAssertFalse(route.name.zh.isEmpty, "\(route.id) is missing a Chinese name")
            XCTAssertFalse(route.note.en.isEmpty, "\(route.id) is missing an English note")
            XCTAssertFalse(route.note.zh.isEmpty, "\(route.id) is missing a Chinese note")
        }
    }

    func testTagsComeFromTheFixedListAndFeaturedIsATag() throws {
        let data = try SampleDataLoader.load()
        let featured = data.routes.filter(\.isFeatured)
        XCTAssertEqual(featured.map(\.id), ["wukang"])
        XCTAssertTrue(featured[0].tags.contains(.featured))
    }

    func testEveryRouteHasAnUpdatedDate() throws {
        let data = try SampleDataLoader.load()
        let calendar = Calendar(identifier: .gregorian)
        for route in data.routes {
            XCTAssertGreaterThanOrEqual(calendar.component(.year, from: route.updatedAt), 2026, route.id)
        }
    }

    func testEveryTagHasBothLanguages() {
        for tag in RouteTag.allCases {
            XCTAssertNotEqual(L10n.string(tag.localizationKey, .english), tag.localizationKey)
            XCTAssertNotEqual(L10n.string(tag.localizationKey, .chinese), tag.localizationKey)
        }
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
