import Foundation
import CoreLocation

/// A latitude/longitude pair. Kept as a plain Codable struct rather than
/// `CLLocationCoordinate2D` so it can be decoded directly and compared.
struct Coordinate: Codable, Hashable, Sendable {
    let lat: Double
    let lng: Double

    var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

/// The core entity. A walk someone has already done end to end and published.
///
/// The three figures on its face — `km`, `minutes`, `breaks` — are the app's
/// whole proposition. `breaks` is the distinguishing one: how many times the
/// walk is forced to stop or detour.
struct Route: Codable, Identifiable, Hashable, Sendable {
    let id: String
    /// Display order, and the number drawn inside the map pin.
    let number: Int
    let km: Double
    let minutes: Int
    /// Dead ends: places the walk breaks off. Zero is the thing to aim for.
    let breaks: Int

    let name: LocalizedText
    let area: LocalizedText
    let kicker: LocalizedText
    /// A route-quality tag ("Plane trees, unbroken") and a time-of-day tag
    /// ("Morning"). Free text per route, not a controlled vocabulary.
    let tag1: LocalizedText
    let tag2: LocalizedText
    let note: LocalizedText

    let authorName: String
    /// One character, drawn in the avatar circle.
    let authorInitial: String
    let walkCount: Int
    /// A display string on the route, not a computed download size. It becomes
    /// real in Phase 7 or gets labelled honestly.
    let downloadSize: String

    let points: [Coordinate]
    /// Where the discover marker sits — not necessarily on the line.
    let pin: Coordinate

    /// Drives the Featured screen. In the source mockup that screen was
    /// hardcoded to one route; this flag replaces the hardcoding.
    let isFeatured: Bool
}

/// Seed identity for the signed-in walker.
///
/// Deliberately holds no statistics. The source mockup hardcoded walks, total
/// distance, longest walk and routes-added; those are computed from stored
/// walks in Phase 8, so baking numbers in here would only create something to
/// contradict later.
struct UserProfileSeed: Codable, Hashable, Sendable {
    let name: String
    let initial: String
    let joinedMonth: LocalizedText
}

/// The whole bundled catalogue, as decoded from `SampleData.json`.
struct SampleData: Codable, Sendable {
    let routes: [Route]
    let profile: UserProfileSeed
}
