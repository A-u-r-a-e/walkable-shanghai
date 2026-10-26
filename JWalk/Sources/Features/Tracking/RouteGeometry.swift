import Foundation
import CoreLocation

/// Distance and position along a route line.
///
/// Pure functions over coordinates, deliberately kept out of `TrackingSession`
/// so the arithmetic can be tested on its own without a clock or a location
/// feed. Everything is in metres; kilometres are a display concern.
enum RouteGeometry {

    /// Length of the whole line, following it point to point.
    static func totalMeters(_ coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count > 1 else { return 0 }
        return zip(coordinates, coordinates.dropFirst()).reduce(0) { sum, pair in
            sum + distance(pair.0, pair.1)
        }
    }

    static func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }

    /// The leading part of the line, up to `fraction` of its total length.
    ///
    /// The cut lands *between* two stored points rather than snapping to the
    /// nearest one, so the walked line grows smoothly instead of jumping a whole
    /// segment at a time.
    static func prefix(_ coordinates: [CLLocationCoordinate2D], fraction: Double) -> [CLLocationCoordinate2D] {
        guard coordinates.count > 1 else { return coordinates }
        let clamped = min(max(fraction, 0), 1)
        if clamped <= 0 { return [] }
        if clamped >= 1 { return coordinates }

        let target = totalMeters(coordinates) * clamped
        var walked: Double = 0
        var result: [CLLocationCoordinate2D] = [coordinates[0]]

        for (a, b) in zip(coordinates, coordinates.dropFirst()) {
            let segment = distance(a, b)
            if walked + segment >= target {
                let into = segment > 0 ? (target - walked) / segment : 0
                result.append(interpolate(a, b, into))
                return result
            }
            walked += segment
            result.append(b)
        }
        return result
    }

    /// Where along the line a given fraction falls. This is where the walker dot
    /// is drawn.
    static func point(along coordinates: [CLLocationCoordinate2D], fraction: Double) -> CLLocationCoordinate2D? {
        guard !coordinates.isEmpty else { return nil }
        guard coordinates.count > 1 else { return coordinates[0] }
        return prefix(coordinates, fraction: fraction).last ?? coordinates[0]
    }

    /// Straight-line blend between two coordinates. Fine at street scale, where
    /// segments are tens of metres and the earth's curvature is irrelevant.
    static func interpolate(
        _ a: CLLocationCoordinate2D,
        _ b: CLLocationCoordinate2D,
        _ t: Double
    ) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: a.latitude + (b.latitude - a.latitude) * t,
            longitude: a.longitude + (b.longitude - a.longitude) * t
        )
    }

    /// Drops points closer than `minimumMeters` to the last one kept, so a
    /// recorded walk becomes a route of a sensible size. A fix arrives every
    /// second or so; most of them only restate where the walker already was.
    /// The first and last points are always kept.
    static func thinned(_ coordinates: [CLLocationCoordinate2D], minimumMeters: Double) -> [CLLocationCoordinate2D] {
        guard coordinates.count > 2, let first = coordinates.first, let last = coordinates.last else { return coordinates }
        var result = [first]
        for coordinate in coordinates.dropFirst().dropLast() where distance(result[result.count - 1], coordinate) >= minimumMeters {
            result.append(coordinate)
        }
        result.append(last)
        return result
    }

    /// Densifies a line so a simulated walk moves in small steps rather than
    /// teleporting between the handful of points a route stores.
    static func densified(_ coordinates: [CLLocationCoordinate2D], everyMeters: Double) -> [CLLocationCoordinate2D] {
        guard coordinates.count > 1, everyMeters > 0 else { return coordinates }
        var result: [CLLocationCoordinate2D] = [coordinates[0]]

        for (a, b) in zip(coordinates, coordinates.dropFirst()) {
            let segment = distance(a, b)
            let steps = max(1, Int((segment / everyMeters).rounded(.up)))
            for step in 1...steps {
                result.append(interpolate(a, b, Double(step) / Double(steps)))
            }
        }
        return result
    }
}
