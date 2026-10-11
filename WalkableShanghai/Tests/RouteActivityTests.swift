import XCTest
@testable import WalkableShanghai

final class RouteActivityTests: XCTestCase {

    func testWalkingNowIsZeroWithoutAServer() {
        let provider = OfflineActivityProvider(counts: ["wukang": WalkCounts(today: 2, week: 9, month: 30, allTime: 120)])
        XCTAssertEqual(provider.walkingNow(routeId: "wukang"), 0)
        XCTAssertEqual(provider.walkingNow(routeId: "unknown"), 0)
    }

    func testPeriodCountsComeFromTheBundle() {
        let provider = OfflineActivityProvider(counts: ["wukang": WalkCounts(today: 2, week: 9, month: 30, allTime: 120)])
        XCTAssertEqual(provider.walks(routeId: "wukang", period: .today), 2)
        XCTAssertEqual(provider.walks(routeId: "wukang", period: .week), 9)
        XCTAssertEqual(provider.walks(routeId: "wukang", period: .month), 30)
        XCTAssertEqual(provider.walks(routeId: "wukang", period: .allTime), 120)
        XCTAssertEqual(provider.walks(routeId: "unknown", period: .week), 0)
    }

    func testTheStoreServesTheBundledCounts() {
        let store = RouteStore()
        XCTAssertGreaterThan(store.activity.walks(routeId: "wukang", period: .allTime), 0)
        XCTAssertEqual(store.activity.walkingNow(routeId: "wukang"), 0)
    }

    func testEveryPeriodHasBothLanguages() {
        for period in ActivityPeriod.allCases {
            XCTAssertNotEqual(L10n.string(period.localizationKey, .english), period.localizationKey)
            XCTAssertNotEqual(L10n.string(period.localizationKey, .chinese), period.localizationKey)
        }
    }
}
