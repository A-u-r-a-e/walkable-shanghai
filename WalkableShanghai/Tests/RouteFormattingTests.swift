import XCTest
@testable import WalkableShanghai

/// The figures and date every route row shows.
final class RouteFormattingTests: XCTestCase {

    private var savedTimeZone: TimeZone!
    private var savedTZ: String?

    override func setUp() {
        super.setUp()
        savedTimeZone = NSTimeZone.default
        savedTZ = ProcessInfo.processInfo.environment["TZ"]
    }

    override func tearDown() {
        NSTimeZone.default = savedTimeZone
        if let savedTZ {
            setenv("TZ", savedTZ, 1)
        } else {
            unsetenv("TZ")
        }
        tzset()
        NSTimeZone.resetSystemTimeZone()
        super.tearDown()
    }

    /// Catalogue dates decode as midnight in Shanghai. A phone in New York is
    /// still on the previous day at that moment, so formatting in the device's
    /// zone would show "Oct 2" for a route updated on 3 October.
    func testUpdatedDayIsTheCatalogueDateWestOfShanghai() throws {
        // Date.FormatStyle takes its zone from the system zone, which ignores
        // NSTimeZone.default; TZ moves it for this process.
        NSTimeZone.default = TimeZone(identifier: "America/New_York")!
        setenv("TZ", "America/New_York", 1)
        tzset()
        NSTimeZone.resetSystemTimeZone()
        let route = try XCTUnwrap(SampleDataLoader.load().routes.first { $0.id == "wukang" })

        XCTAssertEqual(route.updatedDay(.english), "Oct 3")
    }

    func testFiguresShowDistanceAndTime() throws {
        let route = try XCTUnwrap(SampleDataLoader.load().routes.first { $0.id == "wukang" })

        XCTAssertEqual(route.figures(.english), "3.4 km · 52 min")
    }
}
