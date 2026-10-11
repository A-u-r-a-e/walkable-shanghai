import XCTest
import MapKit
@testable import WalkableShanghai

@MainActor
final class MapStyleTests: XCTestCase {

    func testEachStyleMapsToItsMapKitConfiguration() throws {
        let standard = try XCTUnwrap(RouteMapView.configuration(for: .standard) as? MKStandardMapConfiguration)
        XCTAssertEqual(standard.emphasisStyle, .muted)
        XCTAssertFalse(standard.showsTraffic)

        let traffic = try XCTUnwrap(RouteMapView.configuration(for: .traffic) as? MKStandardMapConfiguration)
        XCTAssertTrue(traffic.showsTraffic)

        XCTAssertTrue(RouteMapView.configuration(for: .satellite) is MKHybridMapConfiguration)
    }

    func testTheChoicePersistsAndDefaultsToStandard() {
        let defaults = UserDefaults(suiteName: "MapStyleTests")!
        defaults.removePersistentDomain(forName: "MapStyleTests")

        XCTAssertEqual(AppSettings(defaults: defaults).mapStyle, .standard)

        let settings = AppSettings(defaults: defaults)
        settings.mapStyle = .satellite
        XCTAssertEqual(AppSettings(defaults: defaults).mapStyle, .satellite)
    }

    func testEveryStyleHasBothLanguages() {
        for style in MapStyleOption.allCases {
            XCTAssertNotEqual(L10n.string(style.localizationKey, .english), style.localizationKey)
            XCTAssertNotEqual(L10n.string(style.localizationKey, .chinese), style.localizationKey)
        }
    }
}
