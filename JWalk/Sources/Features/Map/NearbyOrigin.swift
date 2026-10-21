import CoreLocation

/// The walker's last known position, for ordering Nearby.
///
/// Reads what Core Location already has rather than asking for permission:
/// the map should not open with a prompt. With no permission or no fix, Nearby
/// measures from People's Square (`RouteList.peoplesSquare`). UI tests pass
/// `-uitest.ignoreLocation` so the order does not depend on the simulator.
@MainActor
enum NearbyOrigin {
    static func current() -> Coordinate? {
        if ProcessInfo.processInfo.arguments.contains("-uitest.ignoreLocation") { return nil }
        let manager = CLLocationManager()
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            guard let location = manager.location else { return nil }
            return Coordinate(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
        default:
            return nil
        }
    }
}
