import XCTest
import CoreLocation
@testable import JWalk

/// The tracking state machine and the geometry under it.
///
/// These drive the session through a fake location source, so a walk that would
/// take an hour outdoors runs in milliseconds and lands on exact numbers.
@MainActor
final class TrackingTests: XCTestCase {

    /// A location source the test drives by hand.
    private final class ManualLocationProvider: LocationProviding {
        var onUpdate: ((CLLocation) -> Void)?
        var onAuthorizationDenied: (() -> Void)?

        private(set) var isRunning = false
        private(set) var authorizationRequests = 0

        func requestAuthorization() { authorizationRequests += 1 }
        func start() { isRunning = true }
        func stop() { isRunning = false }

        func emit(_ coordinate: CLLocationCoordinate2D) {
            onUpdate?(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        }

        func deny() { onAuthorizationDenied?() }
    }

    private func loadRoute(_ id: String) throws -> Route {
        let hostBundle = Bundle(identifier: "com.jwalk.app") ?? Bundle(for: Self.self)
        let data = try SampleDataLoader.load(from: hostBundle)
        return try XCTUnwrap(data.routes.first { $0.id == id })
    }

    // MARK: - Geometry

    func testTotalMetersMatchesTheRoutesPublishedDistance() throws {
        // The geometry in the catalogue should agree with the km each route
        // advertises. Loose tolerance: the stored line is a simplification.
        for id in ["wukang", "creek", "fuxing", "bund", "century"] {
            let route = try loadRoute(id)
            let meters = RouteGeometry.totalMeters(route.points.map(\.clLocationCoordinate))
            XCTAssertGreaterThan(meters, 300, "\(id) has an implausibly short line")
            XCTAssertLessThan(meters, route.km * 1000 * 2.5, "\(id)'s line is far longer than its stated km")
        }
    }

    func testPrefixGrowsMonotonicallyAndEndsWhereItStarted() {
        let line = [
            CLLocationCoordinate2D(latitude: 31.20, longitude: 121.44),
            CLLocationCoordinate2D(latitude: 31.21, longitude: 121.44),
            CLLocationCoordinate2D(latitude: 31.22, longitude: 121.45),
        ]
        let total = RouteGeometry.totalMeters(line)

        var previous = 0.0
        for step in stride(from: 0.0, through: 1.0, by: 0.1) {
            let walked = RouteGeometry.totalMeters(RouteGeometry.prefix(line, fraction: step))
            XCTAssertGreaterThanOrEqual(walked, previous - 0.5, "the walked line went backwards at \(step)")
            previous = walked
        }
        XCTAssertEqual(previous, total, accuracy: 1.0, "a full prefix should be the whole line")
        XCTAssertTrue(RouteGeometry.prefix(line, fraction: 0).isEmpty)
    }

    func testPrefixCutsBetweenPointsRatherThanSnapping() throws {
        // Two points 1 km apart; half of it must land in the middle, not on
        // either end.
        let line = [
            CLLocationCoordinate2D(latitude: 31.20, longitude: 121.44),
            CLLocationCoordinate2D(latitude: 31.20, longitude: 121.4505),
        ]
        let half = try XCTUnwrap(RouteGeometry.point(along: line, fraction: 0.5))
        let midpoint = RouteGeometry.interpolate(line[0], line[1], 0.5)
        XCTAssertEqual(half.longitude, midpoint.longitude, accuracy: 0.0002)
    }

    func testDensifyAddsPointsWithoutMovingTheLine() {
        let line = [
            CLLocationCoordinate2D(latitude: 31.20, longitude: 121.44),
            CLLocationCoordinate2D(latitude: 31.21, longitude: 121.45),
        ]
        let dense = RouteGeometry.densified(line, everyMeters: 25)
        XCTAssertGreaterThan(dense.count, line.count)
        XCTAssertEqual(
            RouteGeometry.totalMeters(dense),
            RouteGeometry.totalMeters(line),
            accuracy: 1.0,
            "densifying changed the length of the line"
        )
    }

    func testThinningDropsCloseFixesAndKeepsTheEnds() {
        let line = [
            CLLocationCoordinate2D(latitude: 31.20, longitude: 121.44),
            CLLocationCoordinate2D(latitude: 31.21, longitude: 121.45),
        ]
        // A fix every 2 m, as a phone held by a slow walker would give.
        let fixes = RouteGeometry.densified(line, everyMeters: 2)
        let thinned = RouteGeometry.thinned(fixes, minimumMeters: 10)

        XCTAssertLessThan(thinned.count, fixes.count / 3)
        XCTAssertEqual(thinned.first?.latitude, fixes.first?.latitude)
        XCTAssertEqual(thinned.last?.latitude, fixes.last?.latitude)
        XCTAssertEqual(RouteGeometry.totalMeters(thinned), RouteGeometry.totalMeters(fixes), accuracy: 1.0)
    }

    // MARK: - The state machine

    func testAFreeWalkRecordsWhereverTheWalkerGoes() {
        let provider = ManualLocationProvider()
        let session = TrackingSession(provider: provider)
        session.start(route: nil)

        let a = CLLocationCoordinate2D(latitude: 31.2000, longitude: 121.4400)
        let b = CLLocationCoordinate2D(latitude: 31.2010, longitude: 121.4400)
        provider.emit(a)
        provider.emit(b)

        XCTAssertNil(session.route)
        XCTAssertEqual(session.walkedCoordinates.count, 2)
        XCTAssertEqual(session.distanceMeters, RouteGeometry.distance(a, b), accuracy: 0.5)
        XCTAssertEqual(session.progress, 0, "a free walk has no route to progress along")
        XCTAssertEqual(session.walkerCoordinate?.latitude, b.latitude, "the walker is drawn at the last fix")
    }

    func testStartPausesResumesAndEnds() throws {
        let provider = ManualLocationProvider()
        let session = TrackingSession(provider: provider)
        let route = try loadRoute("wukang")

        XCTAssertEqual(session.state, .idle)

        session.start(route: route)
        XCTAssertEqual(session.state, .running)
        XCTAssertTrue(provider.isRunning, "starting a walk should start the location feed")
        XCTAssertEqual(provider.authorizationRequests, 1, "starting should ask for permission once")

        session.pause()
        XCTAssertEqual(session.state, .paused)
        XCTAssertFalse(provider.isRunning, "pausing should stop the location feed")

        session.resume()
        XCTAssertEqual(session.state, .running)
        XCTAssertTrue(provider.isRunning)

        session.end()
        XCTAssertEqual(session.state, .ended)
        XCTAssertFalse(provider.isRunning)
    }

    func testIllegalTransitionsAreIgnored() throws {
        let session = TrackingSession(provider: ManualLocationProvider())
        let route = try loadRoute("wukang")

        // Resuming a walk that was never started, or pausing a paused one,
        // should do nothing rather than corrupt the state.
        session.resume()
        XCTAssertEqual(session.state, .idle)

        session.start(route: route)
        session.pause()
        session.pause()
        XCTAssertEqual(session.state, .paused)

        session.resume()
        session.resume()
        XCTAssertEqual(session.state, .running)
    }

    func testDistanceAccumulatesOnlyWhileRunning() throws {
        let provider = ManualLocationProvider()
        let session = TrackingSession(provider: provider)
        let route = try loadRoute("wukang")
        let line = route.points.map(\.clLocationCoordinate)

        session.start(route: route)
        provider.emit(line[0])
        provider.emit(line[1])
        let afterTwo = session.distanceMeters
        XCTAssertGreaterThan(afterTwo, 0, "walking between two points should cover ground")

        // Fixes that arrive while paused must not count.
        session.pause()
        provider.emit(line[2])
        XCTAssertEqual(session.distanceMeters, afterTwo, accuracy: 0.001,
                       "distance grew while the walk was paused")

        // And the jump across the pause must not count either.
        session.resume()
        provider.emit(line[2])
        XCTAssertEqual(session.distanceMeters, afterTwo, accuracy: 0.001,
                       "the gap across a pause was counted as distance walked")

        provider.emit(line[3])
        XCTAssertGreaterThan(session.distanceMeters, afterTwo, "walking after resume should count again")
    }

    func testImplausibleJumpsAreRejected() throws {
        let provider = ManualLocationProvider()
        let session = TrackingSession(provider: provider)
        session.start(route: try loadRoute("wukang"))

        provider.emit(CLLocationCoordinate2D(latitude: 31.21, longitude: 121.44))
        // Beijing. Not a step.
        provider.emit(CLLocationCoordinate2D(latitude: 39.90, longitude: 116.40))
        XCTAssertEqual(session.distanceMeters, 0, accuracy: 0.001,
                       "a 1000 km jump was counted as walking")
        XCTAssertEqual(session.walkedCoordinates.count, 1, "the jump was drawn into the walked line")
    }

    func testStaleAndInaccurateFixesAreIgnored() {
        let provider = ManualLocationProvider()
        let session = TrackingSession(provider: provider)
        session.start(route: nil)
        let here = CLLocationCoordinate2D(latitude: 31.2000, longitude: 121.4400)

        // The phone's last known position, from an hour ago.
        provider.onUpdate?(CLLocation(coordinate: here, altitude: 0, horizontalAccuracy: 5,
                                      verticalAccuracy: 5, timestamp: Date().addingTimeInterval(-3600)))
        // An invalid fix, and one too rough to draw.
        provider.onUpdate?(CLLocation(coordinate: here, altitude: 0, horizontalAccuracy: -1,
                                      verticalAccuracy: 5, timestamp: Date()))
        provider.onUpdate?(CLLocation(coordinate: here, altitude: 0, horizontalAccuracy: 400,
                                      verticalAccuracy: 5, timestamp: Date()))
        XCTAssertTrue(session.walkedCoordinates.isEmpty)

        provider.onUpdate?(CLLocation(coordinate: here, altitude: 0, horizontalAccuracy: 8,
                                      verticalAccuracy: 5, timestamp: Date()))
        XCTAssertEqual(session.walkedCoordinates.count, 1)
    }

    func testProgressAndRemainingTrackDistance() throws {
        let provider = ManualLocationProvider()
        let session = TrackingSession(provider: provider)
        let route = try loadRoute("wukang")
        let dense = RouteGeometry.densified(route.points.map(\.clLocationCoordinate), everyMeters: 20)

        session.start(route: route)
        XCTAssertEqual(session.progress, 0)
        XCTAssertEqual(session.remainingKm, route.km, accuracy: 0.01)

        for coordinate in dense { provider.emit(coordinate) }

        XCTAssertEqual(session.progress, 1.0, accuracy: 0.01, "walking the whole line should finish it")
        XCTAssertLessThan(session.remainingKm, route.km, "remaining should have come down")
        XCTAssertNotNil(session.walkerCoordinate)
    }

    func testProgressNeverExceedsOne() throws {
        let provider = ManualLocationProvider()
        let session = TrackingSession(provider: provider)
        let route = try loadRoute("fuxing")
        let dense = RouteGeometry.densified(route.points.map(\.clLocationCoordinate), everyMeters: 20)

        session.start(route: route)
        // Walk it twice.
        for coordinate in dense + dense.reversed() { provider.emit(coordinate) }
        XCTAssertEqual(session.progress, 1.0, "progress ran past the end of the route")
        XCTAssertEqual(session.remainingKm, 0, accuracy: 0.01)
    }

    // MARK: - The clock

    func testElapsedComesFromTheWallClockNotTheTicker() throws {
        let session = TrackingSession(provider: ManualLocationProvider(), tickInterval: .seconds(60))
        session.start(route: try loadRoute("wukang"))

        // The ticker will not fire for a minute, but elapsed must still be right
        // the moment anyone asks. This is the property that makes the clock
        // survive backgrounding: nothing counts up, it is all derived.
        Thread.sleep(forTimeInterval: 0.4)
        session.refreshElapsed()
        XCTAssertGreaterThan(session.elapsed, 0.3, "the clock did not advance without a tick")
    }

    func testPauseStopsTheClockAndResumeContinuesIt() throws {
        let session = TrackingSession(provider: ManualLocationProvider(), tickInterval: .seconds(60))
        session.start(route: try loadRoute("wukang"))

        Thread.sleep(forTimeInterval: 0.3)
        session.pause()
        let atPause = session.elapsed
        XCTAssertGreaterThan(atPause, 0.2)

        Thread.sleep(forTimeInterval: 0.3)
        session.refreshElapsed()
        XCTAssertEqual(session.elapsed, atPause, accuracy: 0.05, "the clock kept running while paused")

        session.resume()
        Thread.sleep(forTimeInterval: 0.3)
        session.refreshElapsed()
        XCTAssertGreaterThan(session.elapsed, atPause + 0.2, "the clock did not restart on resume")
    }

    func testPaceIsWithheldUntilItMeansSomething() throws {
        let provider = ManualLocationProvider()
        let session = TrackingSession(provider: provider)
        let route = try loadRoute("wukang")
        session.start(route: route)

        XCTAssertNil(session.paceSecondsPerKm, "pace should not be reported from a standing start")
        XCTAssertEqual(session.paceText, "—")

        for coordinate in RouteGeometry.densified(route.points.map(\.clLocationCoordinate), everyMeters: 20) {
            provider.emit(coordinate)
        }
        session.refreshElapsed()
        XCTAssertNotNil(session.paceSecondsPerKm, "pace should be available after a real distance")
    }

    func testDeniedPermissionIsSurfaced() throws {
        let provider = ManualLocationProvider()
        let session = TrackingSession(provider: provider)
        session.start(route: try loadRoute("wukang"))

        XCTAssertFalse(session.locationDenied)
        provider.deny()
        XCTAssertTrue(session.locationDenied, "a refused permission should be visible to the UI")
    }

    // MARK: - Formatting

    func testClockFormatting() {
        XCTAssertEqual(TrackingSession.clock(0), "00:00")
        XCTAssertEqual(TrackingSession.clock(9), "00:09")
        XCTAssertEqual(TrackingSession.clock(70), "01:10")
        XCTAssertEqual(TrackingSession.clock(599), "09:59")
        XCTAssertEqual(TrackingSession.clock(3600), "1:00:00")
        XCTAssertEqual(TrackingSession.clock(3725), "1:02:05")
        // Never a negative clock, whatever the arithmetic upstream did.
        XCTAssertEqual(TrackingSession.clock(-5), "00:00")
    }
}
