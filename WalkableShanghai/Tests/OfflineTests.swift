import XCTest
import SwiftData
import CoreLocation
@testable import WalkableShanghai

/// What "offline" actually stores, what it reports, and that the offline read
/// path touches nothing but the stored bundle.
@MainActor
final class OfflineTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        try UserStateContainer.make(inMemory: true)
    }

    private func catalogue() throws -> BundledDataSource {
        let hostBundle = Bundle(identifier: "com.walkableshanghai.app") ?? Bundle(for: Self.self)
        return BundledDataSource(data: try SampleDataLoader.load(from: hostBundle))
    }

    // MARK: - The rendered map image

    func testTheRouteImageIsRealPNGDataDrawnFromGeometry() throws {
        let source = try catalogue()
        let route = try XCTUnwrap(source.route(id: "wukang"))

        let data = try XCTUnwrap(
            RouteImageRenderer.pngData(for: route, size: CGSize(width: 900, height: 560))
        )
        XCTAssertGreaterThan(data.count, 1000, "the rendered map is implausibly small")

        XCTAssertEqual(Array(data.prefix(4)), [0x89, 0x50, 0x4E, 0x47], "not a PNG")

        // Decoded from PNG bytes the image reports pixels, so 900x560 points at
        // the renderer's fixed scale of 2 is 1800x1120 px. The scale is fixed
        // rather than the device's precisely so the stored file is identical
        // whichever phone downloaded it.
        let image = try XCTUnwrap(UIImage(data: data))
        XCTAssertEqual(image.size.width, 1800, accuracy: 1)
        XCTAssertEqual(image.size.height, 1120, accuracy: 1)
    }

    func testARouteWithNoLineRendersNothingRatherThanABlank() throws {
        let source = try catalogue()
        var route = try XCTUnwrap(source.route(id: "wukang"))
        route = Route(
            id: route.id, km: route.km, minutes: route.minutes,
            name: route.name, note: route.note,
            authorName: route.authorName, authorInitial: route.authorInitial,
            tags: route.tags, updatedAt: route.updatedAt,
            points: [], pin: route.pin
        )
        XCTAssertNil(RouteImageRenderer.pngData(for: route, size: CGSize(width: 100, height: 100)))
    }

    func testProjectionPreservesShapeAndFitsTheBox() {
        // A wide, short L. Projected into a square, it must keep its
        // proportions rather than being stretched to fill.
        let line = [
            CLLocationCoordinate2D(latitude: 31.20, longitude: 121.40),
            CLLocationCoordinate2D(latitude: 31.20, longitude: 121.44),
            CLLocationCoordinate2D(latitude: 31.21, longitude: 121.44),
        ]
        let box = CGRect(x: 0, y: 0, width: 400, height: 400)
        let points = RouteImageRenderer.project(line, into: box)

        XCTAssertEqual(points.count, 3)
        for point in points {
            XCTAssertTrue(box.insetBy(dx: -0.5, dy: -0.5).contains(point),
                          "\(point) fell outside the box")
        }
        // The first two share a latitude, so they must share a y.
        XCTAssertEqual(points[0].y, points[1].y, accuracy: 0.5)
        // The last two share a longitude, so they must share an x.
        XCTAssertEqual(points[1].x, points[2].x, accuracy: 0.5)
        // Wider than tall, as the input is.
        XCTAssertGreaterThan(abs(points[1].x - points[0].x), abs(points[2].y - points[1].y))
        // And north is up: the higher latitude gets the smaller y.
        XCTAssertLessThan(points[2].y, points[1].y)
    }

    // MARK: - The bundle

    func testDownloadingStoresRouteAndImageAndReportsRealBytes() throws {
        let source = try catalogue()
        let route = try XCTUnwrap(source.route(id: "wukang"))

        let store = OfflineStore(container: try makeContainer())
        let bundle = try XCTUnwrap(store.download(route: route))

        XCTAssertGreaterThan(bundle.routeData.count, 0)
        XCTAssertGreaterThan(bundle.mapImage.count, 0)
        // The reported size is the sum of exactly what is stored — no constant,
        // no estimate.
        XCTAssertEqual(
            bundle.byteCount,
            bundle.routeData.count + bundle.mapImage.count
        )
        XCTAssertEqual(store.totalBytes, bundle.byteCount)
    }

    func testSizeTextIsDerivedFromTheStoredBytes() throws {
        let source = try catalogue()
        let store = OfflineStore(container: try makeContainer())
        let route = try XCTUnwrap(source.route(id: "wukang"))
        store.download(route: route)

        let text = store.sizeText("wukang", language: .english)
        XCTAssertFalse(text.isEmpty)
        XCTAssertFalse(text.contains("18 MB"), "the fictional catalogue size leaked through")
        // A route and a picture of its line land in kilobytes, not megabytes.
        XCTAssertTrue(text.contains("KB") || text.contains("MB"), "unexpected size text: \(text)")

        // An un-downloaded route reports zero rather than a borrowed figure.
        XCTAssertEqual(store.bundle(for: "creek"), nil)
    }

    func testTheOfflineReadPathUsesOnlyTheStoredSnapshot() throws {
        let source = try catalogue()
        let route = try XCTUnwrap(source.route(id: "wukang"))

        let store = OfflineStore(container: try makeContainer())
        store.download(route: route)

        // Everything the offline screen needs comes back out of the bundle,
        // decoded — not from the catalogue.
        let stored = try XCTUnwrap(store.storedRoute("wukang"))
        XCTAssertEqual(stored.id, route.id)
        XCTAssertEqual(stored.name(.english), route.name(.english))
        XCTAssertEqual(stored.name(.chinese), route.name(.chinese))
        XCTAssertEqual(stored.points.count, route.points.count, "the line did not survive encoding")
        XCTAssertEqual(stored.km, route.km)
    }

    func testABundleSurvivesRelaunchAndRemovingDeletesIt() throws {
        let container = try makeContainer()
        let source = try catalogue()
        let route = try XCTUnwrap(source.route(id: "creek"))

        let first = OfflineStore(container: container)
        first.download(route: route)
        let size = first.totalBytes

        let reopened = OfflineStore(container: container)
        XCTAssertTrue(reopened.hasBundle("creek"), "the download did not persist")
        XCTAssertEqual(reopened.totalBytes, size)

        reopened.remove(routeId: "creek")
        XCTAssertFalse(OfflineStore(container: container).hasBundle("creek"),
                       "removing the download did not persist")
    }

    func testDownloadingTwiceReplacesRatherThanDuplicates() throws {
        let source = try catalogue()
        let route = try XCTUnwrap(source.route(id: "wukang"))
        let store = OfflineStore(container: try makeContainer())

        store.download(route: route)
        let once = store.totalBytes
        store.download(route: route)

        XCTAssertEqual(store.bundles.count, 1, "re-downloading duplicated the bundle")
        XCTAssertEqual(store.totalBytes, once, "the reported size doubled")
    }
}
