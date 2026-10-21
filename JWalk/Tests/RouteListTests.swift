import XCTest
@testable import JWalk

final class RouteListTests: XCTestCase {

    private func route(_ id: String, lat: Double, lng: Double, tags: [RouteTag] = [], en: String? = nil, zh: String? = nil) -> Route {
        Route(
            id: id, km: 1, minutes: 12,
            name: LocalizedText(en: en ?? id, zh: zh ?? id),
            note: LocalizedText(en: "", zh: ""),
            authorName: "A", authorInitial: "A",
            tags: tags, updatedAt: Date(timeIntervalSince1970: 0),
            points: [Coordinate(lat: lat, lng: lng), Coordinate(lat: lat + 0.001, lng: lng)],
            pin: Coordinate(lat: lat, lng: lng)
        )
    }

    private let near = Coordinate(lat: 31.2304, lng: 121.4737)
    private lazy var routes = [
        route("far", lat: 31.30, lng: 121.60, tags: [.featured], en: "Far Loop", zh: "远环"),
        route("close", lat: 31.231, lng: 121.474, en: "Close Lane", zh: "近巷"),
        route("mid", lat: 31.25, lng: 121.50, tags: [.popular], en: "Middle Walk", zh: "中段"),
        route("draft-1", lat: 31.24, lng: 121.48, en: "My Line", zh: "My Line"),
    ]
    private let activity = OfflineActivityProvider(counts: [
        "far": WalkCounts(today: 0, week: 2, month: 9, allTime: 50),
        "close": WalkCounts(today: 1, week: 7, month: 8, allTime: 20),
        "mid": WalkCounts(today: 0, week: 0, month: 30, allTime: 90),
    ])

    private func ids(_ query: RouteListQuery, origin: Coordinate? = nil, saved: Set<String> = []) -> [[String]] {
        RouteList.sections(routes: routes, query: query, mineIds: ["draft-1"], savedIds: saved, origin: origin, activity: activity)
            .map { $0.routes.map(\.id) }
    }

    func testNearbyIsTheDefaultAndSortsByDistance() {
        XCTAssertEqual(RouteListQuery().option, .nearby)
        XCTAssertEqual(ids(RouteListQuery(), origin: near), [["close", "draft-1", "mid", "far"]])
    }

    func testNearbyFallsBackToPeoplesSquare() {
        XCTAssertEqual(ids(RouteListQuery(), origin: nil), ids(RouteListQuery(), origin: RouteList.peoplesSquare))
    }

    func testPopularRanksByThePeriodAndDropsUnwalkedRoutes() {
        XCTAssertEqual(ids(RouteListQuery(option: .popular, period: .week)), [["close", "far"]])
        XCTAssertEqual(ids(RouteListQuery(option: .popular, period: .month)), [["mid", "far", "close"]])
        XCTAssertEqual(ids(RouteListQuery(option: .popular, period: .today)), [["close"]])
        XCTAssertEqual(ids(RouteListQuery(option: .popular, period: .allTime)), [["mid", "far", "close"]])
    }

    func testFeaturedKeepsOnlyFeaturedRoutes() {
        XCTAssertEqual(ids(RouteListQuery(option: .featured)), [["far"]])
    }

    func testMineListsOnlyTheWalkersRoutesAndOffersANewOne() {
        let sections = RouteList.sections(routes: routes, query: RouteListQuery(option: .mine), mineIds: ["draft-1"], savedIds: [], origin: nil, activity: activity)
        XCTAssertEqual(sections.map(\.kind), [.mine])
        XCTAssertEqual(sections[0].routes.map(\.id), ["draft-1"])
        XCTAssertTrue(sections[0].offersNewRoute)
    }

    func testSavedShowsMineFirstThenSavedWithoutRepeats() {
        let sections = RouteList.sections(routes: routes, query: RouteListQuery(option: .saved), mineIds: ["draft-1"], savedIds: ["mid", "draft-1"], origin: nil, activity: activity)
        XCTAssertEqual(sections.map(\.kind), [.mine, .saved])
        XCTAssertEqual(sections[0].routes.map(\.id), ["draft-1"])
        XCTAssertTrue(sections[0].offersNewRoute)
        XCTAssertEqual(sections[1].routes.map(\.id), ["mid"])
        XCTAssertFalse(sections[1].offersNewRoute)
    }

    func testSearchMatchesEitherLanguageIgnoringCaseAndSpaces() {
        XCTAssertEqual(ids(RouteListQuery(option: .nearby, searchText: "  lane "), origin: near), [["close"]])
        XCTAssertEqual(ids(RouteListQuery(option: .nearby, searchText: "远"), origin: near), [["far"]])
        XCTAssertEqual(ids(RouteListQuery(option: .nearby, searchText: ""), origin: near).first?.count, 4)
    }

    func testEmptySectionsAreStillReturnedSoTheSheetCanExplainThem() {
        let sections = RouteList.sections(routes: routes, query: RouteListQuery(option: .saved), mineIds: [], savedIds: [], origin: nil, activity: activity)
        XCTAssertEqual(sections.map(\.kind), [.mine, .saved])
        XCTAssertTrue(sections.allSatisfy { $0.routes.isEmpty })
    }

    func testEveryOptionHasBothLanguages() {
        for option in RouteListOption.allCases {
            XCTAssertNotEqual(L10n.string(option.localizationKey, .english), option.localizationKey)
            XCTAssertNotEqual(L10n.string(option.localizationKey, .chinese), option.localizationKey)
        }
    }
}
