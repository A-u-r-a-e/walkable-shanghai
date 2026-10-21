import Foundation
import CoreLocation
import Observation

/// A walk in progress.
///
/// The state machine is deliberately small — idle, running, paused, ended — and
/// every number the tracking screen shows is derived from two things: the
/// distance accumulated from location fixes, and elapsed time.
///
/// **Elapsed time is computed from the wall clock, never counted up by the
/// timer.** The timer only decides how often the screen redraws. This is the
/// difference between a clock that survives the phone locking and one that
/// quietly loses however long the app spent suspended, and it is why
/// `backgrounding the app and returning shows the clock has kept running` is a
/// property of the design rather than something that needs a background task to
/// hold up.
@MainActor
@Observable
final class TrackingSession {

    enum State: Equatable {
        case idle
        case running
        case paused
        case ended
    }

    private(set) var state: State = .idle
    private(set) var route: Route?

    /// Metres accumulated from successive fixes. Raw: no snapping to the route
    /// line and no GPS smoothing, both of which PLAN.md excludes from this phase.
    private(set) var distanceMeters: Double = 0
    private(set) var elapsed: TimeInterval = 0
    private(set) var walkedCoordinates: [CLLocationCoordinate2D] = []
    private(set) var locationDenied = false
    /// Wall-clock bounds of the walk, for the summary's date and time range.
    private(set) var startedAt: Date?
    private(set) var endedAt: Date?

    @ObservationIgnored private var provider: LocationProviding
    @ObservationIgnored private var lastFix: CLLocation?
    @ObservationIgnored private var runStartedAt: Date?
    @ObservationIgnored private var accumulated: TimeInterval = 0
    @ObservationIgnored private var ticker: Task<Void, Never>?
    @ObservationIgnored private let tickInterval: Duration

    init(provider: LocationProviding, tickInterval: Duration = .milliseconds(500)) {
        self.provider = provider
        self.tickInterval = tickInterval
        self.provider.onUpdate = { [weak self] fix in
            self?.ingest(fix)
        }
        self.provider.onAuthorizationDenied = { [weak self] in
            self?.locationDenied = true
        }
    }

    deinit {
        ticker?.cancel()
    }

    // MARK: - Derived figures

    var distanceKm: Double { distanceMeters / 1000 }

    /// How far along this particular route the walk has got, 0 to 1.
    ///
    /// Distance covered over the route's own length — not a projection of the
    /// walker onto the line, which would be route snapping and is excluded here.
    var progress: Double {
        guard let route, routeTotalMeters > 0 else { return 0 }
        _ = route
        return min(1, max(0, distanceMeters / routeTotalMeters))
    }

    var remainingKm: Double {
        guard let route else { return 0 }
        return max(0, route.km - distanceKm)
    }

    /// Minutes per kilometre, or nil until enough ground is covered for the
    /// figure to mean anything. Below ~50 m it swings wildly and reads as noise.
    var paceSecondsPerKm: Double? {
        guard distanceMeters > 50, elapsed > 0 else { return nil }
        return elapsed / distanceKm
    }

    /// Where to draw the walker, and how much of the line to draw as walked.
    /// On a free walk there is no line to measure along, so it is the last fix.
    var walkerCoordinate: CLLocationCoordinate2D? {
        guard let route else { return walkedCoordinates.last }
        return RouteGeometry.point(along: route.points.map(\.clLocationCoordinate), fraction: progress)
    }

    @ObservationIgnored private var cachedTotalMeters: Double?
    private var routeTotalMeters: Double {
        if let cachedTotalMeters { return cachedTotalMeters }
        guard let route else { return 0 }
        let total = RouteGeometry.totalMeters(route.points.map(\.clLocationCoordinate))
        cachedTotalMeters = total
        return total
    }

    // MARK: - Transitions

    /// Starts a walk along `route`, or a free walk when it is nil: REC with
    /// no route chosen, which records wherever the walker goes.
    func start(route: Route?) {
        self.route = route
        cachedTotalMeters = nil
        distanceMeters = 0
        walkedCoordinates = []
        lastFix = nil
        accumulated = 0
        elapsed = 0
        locationDenied = false

        state = .running
        let now = Date()
        runStartedAt = now
        startedAt = now
        endedAt = nil
        provider.requestAuthorization()
        provider.start()
        startTicking()
    }

    func pause() {
        guard state == .running else { return }
        // Bank the time run so far, then stop the clock. Nothing is lost and
        // nothing keeps counting.
        accumulated += Date().timeIntervalSince(runStartedAt ?? Date())
        runStartedAt = nil
        state = .paused
        provider.stop()
        stopTicking()
        refreshElapsed()
    }

    func resume() {
        guard state == .paused else { return }
        runStartedAt = Date()
        state = .running
        // Drop the stale fix: the gap across a pause is not distance walked.
        lastFix = nil
        provider.start()
        startTicking()
    }

    func end() {
        if state == .running {
            accumulated += Date().timeIntervalSince(runStartedAt ?? Date())
        }
        runStartedAt = nil
        endedAt = Date()
        state = .ended
        provider.stop()
        stopTicking()
        refreshElapsed()
    }

    /// Called when the app comes back to the foreground, so the clock catches up
    /// in one step rather than resuming from where it was suspended.
    func refreshElapsed() {
        elapsed = accumulated + (runStartedAt.map { Date().timeIntervalSince($0) } ?? 0)
    }

    // MARK: - Location

    private func ingest(_ fix: CLLocation) {
        guard state == .running else { return }

        if let previous = lastFix {
            let step = fix.distance(from: previous)
            // A fix that jumps implausibly far is noise, not walking.
            if step.isFinite, step < 500 {
                distanceMeters += step
            }
        }
        lastFix = fix
        walkedCoordinates.append(fix.coordinate)
        refreshElapsed()
    }

    // MARK: - Ticking
    //
    // The ticker exists only to make the screen redraw. It never adds to
    // elapsed; it just asks for the wall clock again.

    private func startTicking() {
        stopTicking()
        ticker = Task { [weak self, tickInterval] in
            while !Task.isCancelled {
                try? await Task.sleep(for: tickInterval)
                guard let self else { return }
                guard self.state == .running else { continue }
                self.refreshElapsed()
            }
        }
    }

    private func stopTicking() {
        ticker?.cancel()
        ticker = nil
    }
}

// MARK: - Formatting

extension TrackingSession {

    /// `MM:SS`, or `H:MM:SS` past an hour. Monospaced digits in the view keep it
    /// from jittering as the numbers change.
    static func clock(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, secs)
            : String(format: "%02d:%02d", minutes, secs)
    }

    /// Pace as `MM:SS` per kilometre, or an em dash before it means anything.
    var paceText: String {
        guard let paceSecondsPerKm else { return "—" }
        return Self.clock(paceSecondsPerKm)
    }

    var elapsedText: String { Self.clock(elapsed) }
    var distanceText: String { String(format: "%.1f", distanceKm) }
    var remainingText: String { String(format: "%.1f", remainingKm) }
    var progressPercentText: String { "\(Int((progress * 100).rounded()))%" }
}
