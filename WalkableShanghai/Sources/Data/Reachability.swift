import Foundation
import Network
import Observation

/// Whether the phone currently has a usable network.
///
/// Only one thing depends on this: whether a downloaded route draws its live
/// map or its stored picture. That is deliberately the *only* consumer — an app
/// that changes lots of behaviour based on a connectivity flag tends to be
/// wrong about it, because the flag can be stale by the time anything reads it.
@MainActor
@Observable
final class Reachability {

    private(set) var isOnline: Bool = true

    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private let forced: Bool?

    /// - Parameter forcedOffline: set by a launch argument so the offline path
    ///   can be exercised deterministically. The simulator has no airplane
    ///   mode that `simctl` can reach, so without this the offline branch could
    ///   only ever be verified by hand.
    init(forcedOffline: Bool? = nil) {
        self.forced = forcedOffline

        if let forcedOffline {
            isOnline = !forcedOffline
            return
        }

        monitor.pathUpdateHandler = { [weak self] path in
            let satisfied = path.status == .satisfied
            Task { @MainActor [weak self] in
                self?.isOnline = satisfied
            }
        }
        monitor.start(queue: DispatchQueue(label: "reachability"))
    }

    deinit {
        monitor.cancel()
    }

    /// True when a route should be drawn from its stored picture rather than
    /// from the live map: no network, and the route has actually been
    /// downloaded. Both halves matter — with no network and no download there
    /// is nothing better to show than the empty map.
    func shouldUseStoredMap(hasBundle: Bool) -> Bool {
        hasBundle && !isOnline
    }
}
