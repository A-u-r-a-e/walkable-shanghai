import Foundation
import CoreLocation

/// Where positions come from while a walk is being recorded.
///
/// A protocol rather than a direct `CLLocationManager` because tracking has to
/// be testable. A unit test cannot make a real device move, and a UI test that
/// depended on the simulator's location feature would be timing-dependent and
/// flaky. Both real and synthetic sources implement this, and `TrackingSession`
/// cannot tell them apart.
@MainActor
protocol LocationProviding: AnyObject {
    /// Called for each new fix, on the main actor.
    var onUpdate: ((CLLocation) -> Void)? { get set }
    /// Called when the walker refuses permission, so the UI can say why nothing
    /// is happening rather than showing a frozen zero.
    var onAuthorizationDenied: (() -> Void)? { get set }

    func requestAuthorization()
    func start()
    func stop()
}

// MARK: - The real one

/// `CLLocationManager`, configured for walking.
final class CoreLocationProvider: NSObject, LocationProviding, CLLocationManagerDelegate {

    var onUpdate: ((CLLocation) -> Void)?
    var onAuthorizationDenied: (() -> Void)?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        // Report every metre. A walk is a slow, detailed thing; the default
        // filter would drop most of it.
        manager.distanceFilter = 1
        manager.activityType = .fitness
        // Keeps the track and the clock going with the screen locked, which is
        // the normal way to carry a phone on a walk.
        //
        // Guarded rather than set outright: CLLocationManager throws — killing
        // the app at launch — if the Info.plist does not declare the `location`
        // background mode. A missing plist key should degrade to
        // foreground-only tracking, not a crash on every device.
        let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]
        if backgroundModes?.contains("location") == true {
            manager.allowsBackgroundLocationUpdates = true
        } else {
            print("[WalkableShanghai] No `location` background mode in Info.plist; "
                  + "tracking will pause when the app is suspended.")
        }
        manager.pausesLocationUpdatesAutomatically = false
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func start() {
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    // MARK: CLLocationManagerDelegate
    //
    // These arrive on the queue the manager was created on. They are marked
    // `nonisolated` and hop to the main actor explicitly, so the isolation is
    // stated in the code rather than assumed.

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let fixes = locations
        Task { @MainActor [weak self] in
            guard let self else { return }
            for fix in fixes {
                self.onUpdate?(fix)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch status {
            case .denied, .restricted:
                self.onAuthorizationDenied?()
            case .authorizedWhenInUse, .authorizedAlways:
                self.start()
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // A single failed fix is normal in a street canyon; the manager keeps
        // trying. Nothing to do but not crash.
        print("[WalkableShanghai] Location error: \(error.localizedDescription)")
    }
}

// MARK: - The synthetic one

/// Replays a route's own line as if someone were walking it.
///
/// This is what makes tracking testable and its screenshots reproducible. It is
/// reached only through a launch argument, never in a shipping run, and it is
/// honest about being synthetic: it emits the route's stored geometry, so a test
/// can assert exactly how far the walk should have got by a given tick.
@MainActor
final class SimulatedLocationProvider: LocationProviding {

    var onUpdate: ((CLLocation) -> Void)?
    var onAuthorizationDenied: (() -> Void)?

    private let path: [CLLocationCoordinate2D]
    private let interval: Duration
    private var index = 0
    private var task: Task<Void, Never>?

    /// - Parameters:
    ///   - route: the line to walk along.
    ///   - metersPerStep: how far each emitted fix advances. 25 m at 4 fixes a
    ///     second is roughly 100 m/s — far faster than walking, on purpose, so a
    ///     UI test covers a visible stretch of route in a few seconds.
    init(route: Route, metersPerStep: Double = 25, interval: Duration = .milliseconds(250)) {
        self.path = RouteGeometry.densified(
            route.points.map(\.clLocationCoordinate),
            everyMeters: metersPerStep
        )
        self.interval = interval
    }

    func requestAuthorization() {}

    func start() {
        guard task == nil else { return }
        task = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                guard self.index < self.path.count else { return }

                let coordinate = self.path[self.index]
                self.index += 1
                self.onUpdate?(
                    CLLocation(
                        coordinate: coordinate,
                        altitude: 4,
                        horizontalAccuracy: 5,
                        verticalAccuracy: 5,
                        timestamp: Date()
                    )
                )
                try? await Task.sleep(for: self.interval)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
