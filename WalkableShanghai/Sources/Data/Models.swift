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

/// A note left by someone who walked the route, optionally pinned to a specific
/// corner of it.
struct RouteComment: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let routeId: String
    let authorName: String
    let authorInitial: String
    /// Relative, and therefore localised as content: "3 days ago" / "3 天前".
    /// Real comments will carry a timestamp and format this at read time; the
    /// seeded ones are frozen strings.
    let relativeTime: LocalizedText
    let body: LocalizedText
    /// "Wukang Rd × Hunan Rd". Empty means the row is hidden entirely.
    let pinnedPlace: LocalizedText
}

/// A walk someone finished and chose to share. The published form of a Walk.
struct Post: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let authorName: String
    let authorInitial: String
    let routeId: String
    let relativeTime: LocalizedText
    let km: Double
    let minutes: Int
    let replyCount: Int
    /// Likes excluding the current user. The UI adds one when you have liked it.
    let baseLikes: Int
    let note: LocalizedText
}

/// A curated set of routes from one walker.
///
/// Route count and total distance are computed from `routeIds`, never stored —
/// a stored total goes stale the moment a route is edited.
struct RouteCollection: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: LocalizedText
    let curatorName: LocalizedText
    let routeIds: [String]
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

/// The editorial wrapper around the monthly Featured route.
///
/// Note what is *not* here: which route is featured. That is the `isFeatured`
/// flag on `Route`, so there is one source of truth and a unit test can assert
/// exactly one route claims it. This type only carries the writing around it.
struct FeaturedEdition: Codable, Hashable, Sendable {
    let month: LocalizedText
    /// Why this route, this month — the curator's argument, distinct from the
    /// route's own practical note.
    let editorial: LocalizedText
    let curatorName: String
    let curatorInitial: String
    let walkersThisMonth: Int
}

/// The whole bundled catalogue, as decoded from `SampleData.json`.
struct SampleData: Codable, Sendable {
    let routes: [Route]
    let comments: [RouteComment]
    let posts: [Post]
    let collections: [RouteCollection]
    let profile: UserProfileSeed
    let featured: FeaturedEdition
}
