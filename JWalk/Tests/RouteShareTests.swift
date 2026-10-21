import XCTest
@testable import JWalk

/// Sharing a route without a server: the link and the file carry the route,
/// and the app takes back only what is a usable route.
@MainActor
final class RouteShareTests: XCTestCase {

    private func catalogueRoute(_ id: String) throws -> Route {
        let hostBundle = Bundle(identifier: "com.jwalk.app") ?? Bundle(for: Self.self)
        let data = try SampleDataLoader.load(from: hostBundle)
        return try XCTUnwrap(data.routes.first { $0.id == id })
    }

    /// A route as a walker would record it, unknown to the catalogue.
    private func walkerRoute() -> Route {
        Route(
            id: "draft-1a2b3c4d",
            km: 1.2,
            minutes: 14,
            name: LocalizedText(en: "Donghu Road shade", zh: "Donghu Road shade"),
            note: LocalizedText(en: "", zh: ""),
            authorName: "Lin",
            authorInitial: "L",
            tags: [],
            updatedAt: Date(timeIntervalSince1970: 1_790_000_000),
            points: [
                Coordinate(lat: 31.21523, lng: 121.44871),
                Coordinate(lat: 31.21688, lng: 121.45102),
                Coordinate(lat: 31.21790, lng: 121.45333),
            ],
            pin: Coordinate(lat: 31.21523, lng: 121.44871)
        )
    }

    func testALinkCarriesTheRouteAcross() throws {
        let route = walkerRoute()
        let link = try XCTUnwrap(SharedRoute(route: route).link)
        XCTAssertEqual(link.scheme, "jwalk")
        XCTAssertEqual(link.host, "route")

        let received = try XCTUnwrap(SharedRoute.route(from: link))
        XCTAssertEqual(received.id, route.id)
        XCTAssertEqual(received.name, route.name)
        XCTAssertEqual(received.authorName, "Lin")
        XCTAssertEqual(received.points, route.points)
        XCTAssertEqual(received.updatedAt, route.updatedAt)
    }

    func testAFileCarriesTheRouteAcross() throws {
        let route = walkerRoute()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("share-test.jwalk")
        try SharedRoute(route: route).data().write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let received = try XCTUnwrap(SharedRoute.route(from: url))
        XCTAssertEqual(received.points, route.points)
    }

    func testACatalogueRouteFitsInALink() throws {
        // The longest bundled line, with both languages' names and notes.
        let route = try catalogueRoute("wukang")
        let link = try XCTUnwrap(SharedRoute(route: route).link)
        XCTAssertLessThan(link.absoluteString.count, 8000)
        XCTAssertEqual(SharedRoute.route(from: link)?.note, route.note)
    }

    func testAReceivedRouteCarriesNoTags() throws {
        let route = try catalogueRoute("wukang")
        XCTAssertFalse(route.tags.isEmpty, "the test needs a tagged route")
        let link = try XCTUnwrap(SharedRoute(route: route).link)
        XCTAssertEqual(SharedRoute.route(from: link)?.tags, [])
    }

    func testLinksThatHoldNoRouteAreRefused() throws {
        let bad = [
            "jwalk://route",
            "jwalk://route?d=not-base64-json",
            "jwalk://elsewhere?d=e30",
            "https://example.com/route?d=e30",
        ]
        for string in bad {
            XCTAssertNil(SharedRoute.route(from: try XCTUnwrap(URL(string: string))), string)
        }

        // A line of one point is not a route.
        let short = try JSONSerialization.data(withJSONObject: [
            "v": 1, "id": "x", "name": ["en": "a", "zh": "a"], "note": ["en": "", "zh": ""],
            "author": "", "initial": "", "km": 0, "minutes": 0, "updated": 0, "line": [[3121523, 12144871]],
        ])
        XCTAssertNotNil(SharedRoute.decode(short), "the payload itself should decode")
        XCTAssertNil(SharedRoute.decode(short)?.route)

        // Nor is one from a newer version of the format.
        let future = try JSONSerialization.data(withJSONObject: [
            "v": 2, "id": "x", "name": ["en": "a", "zh": "a"], "note": ["en": "", "zh": ""],
            "author": "", "initial": "", "km": 0, "minutes": 0, "updated": 0,
            "line": [[3121523, 12144871], [3121688, 12145102]],
        ])
        XCTAssertNil(SharedRoute.decode(future)?.route)
    }

    func testDistanceAndTimeAreMeasuredFromTheLine() throws {
        // The walker route claims 1.2 km; its three points span about 0.5 km.
        let route = walkerRoute()
        let received = try XCTUnwrap(SharedRoute.route(from: try XCTUnwrap(SharedRoute(route: route).link)))
        let measured = RouteGeometry.totalMeters(route.points.map(\.clLocationCoordinate)) / 1000
        XCTAssertEqual(received.km, (measured * 10).rounded() / 10)
        XCTAssertEqual(received.minutes, Int((received.km * 12).rounded()))
    }

    func testOversizedTextAndFutureDatesAreNotTaken() throws {
        func payload(name: String, updated: Double) throws -> Data {
            try JSONSerialization.data(withJSONObject: [
                "v": 1, "id": "x", "name": ["en": name, "zh": name], "note": ["en": "", "zh": ""],
                "author": "Mei", "initial": "Mei", "updated": updated,
                "line": [[3121523, 12144871], [3121688, 12145102]],
            ])
        }
        let longName = String(repeating: "a", count: SharedRoute.maxNameLength + 1)
        XCTAssertNil(SharedRoute.decode(try payload(name: longName, updated: 0))?.route)

        let future = Date().addingTimeInterval(86_400 * 365).timeIntervalSince1970
        let route = try XCTUnwrap(SharedRoute.decode(try payload(name: "a", updated: future))?.route)
        XCTAssertLessThanOrEqual(route.updatedAt, Date())
        XCTAssertEqual(route.authorInitial, "M")
    }

    func testAnOversizedFileIsNotRead() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("huge.jwalk")
        try Data(count: SharedRoute.maxBytes + 1).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertNil(SharedRoute.route(from: url))
    }

    // MARK: - Into the route list

    func testAReceivedRouteJoinsTheListAndWaitsToOpen() {
        let store = RouteStore(bundle: Bundle(identifier: "com.jwalk.app") ?? .main)
        let count = store.routes.count
        let route = walkerRoute()

        store.receive(route)
        XCTAssertEqual(store.routes.count, count + 1)
        XCTAssertEqual(store.route(id: route.id)?.name, route.name)
        XCTAssertEqual(store.pendingRouteId, route.id)

        // Opening the same link twice does not list it twice.
        store.receive(route)
        XCTAssertEqual(store.routes.count, count + 1)
    }

    func testAReceivedCatalogueRouteOpensAsItself() throws {
        let store = RouteStore(bundle: Bundle(identifier: "com.jwalk.app") ?? .main)
        let count = store.routes.count
        let wukang = try catalogueRoute("wukang")
        let link = try XCTUnwrap(SharedRoute(route: wukang).link)

        store.receive(try XCTUnwrap(SharedRoute.route(from: link)))
        XCTAssertEqual(store.routes.count, count)
        XCTAssertEqual(store.route(id: "wukang")?.tags, wukang.tags, "the catalogue's own route was replaced")
        XCTAssertEqual(store.pendingRouteId, "wukang")
    }

    func testSavedReceivedRoutesComeBackAndDrawnRoutesKeepThem() {
        let store = RouteStore(bundle: Bundle(identifier: "com.jwalk.app") ?? .main)
        let count = store.routes.count
        store.setReceivedRoutes([walkerRoute()])
        XCTAssertEqual(store.routes.count, count + 1)

        // Drawing a route afterwards leaves the received one in place.
        store.setDrawnRoutes([], authorName: "", authorInitial: "")
        XCTAssertNotNil(store.route(id: walkerRoute().id))
        XCTAssertFalse(store.mineRouteIds.contains(walkerRoute().id), "a received route is not the walker's own")
    }
}
