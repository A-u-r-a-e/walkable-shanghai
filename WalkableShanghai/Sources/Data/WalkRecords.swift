import Foundation
import SwiftData
import CoreLocation

/// A walk the user actually finished.
///
/// This is the record Phase 8's profile reads to compute walks, total distance
/// and longest walk. `UserProfileSeed` deliberately stores none of those, so
/// this table is their only source — which is why a walk is written here
/// whether or not the walker chooses to post it.
@Model
final class StoredWalk {

    @Attribute(.unique) var id: UUID
    /// Which route was being followed. A string id, matching the rest of the
    /// app, so a walk survives the catalogue moving to a server.
    var routeId: String
    var startedAt: Date
    var endedAt: Date
    var distanceMeters: Double
    var elapsedSeconds: Double
    var note: String
    /// "Post to feed" versus "Keep it private". The feed does not exist until
    /// Phase 6, so this phase stores the choice and Phase 6 honours it.
    var isPosted: Bool
    /// The photograph, if one was attached. Stored inline: a walk photo is one
    /// image, and `.externalStorage` lets SwiftData spill it to a file anyway
    /// once it is large.
    @Attribute(.externalStorage) var photo: Data?

    init(
        id: UUID = UUID(),
        routeId: String,
        startedAt: Date,
        endedAt: Date,
        distanceMeters: Double,
        elapsedSeconds: Double,
        note: String = "",
        isPosted: Bool = false,
        photo: Data? = nil
    ) {
        self.id = id
        self.routeId = routeId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.distanceMeters = distanceMeters
        self.elapsedSeconds = elapsedSeconds
        self.note = note
        self.isPosted = isPosted
        self.photo = photo
    }

    var distanceKm: Double { distanceMeters / 1000 }
}

/// A route the user drew themselves.
///
/// Stored separately from the bundled catalogue because it is theirs: a
/// catalogue refresh must never touch it. `RouteStore` merges these into the
/// route list so the map cannot tell the two apart.
@Model
final class DraftRoute {

    @Attribute(.unique) var id: String
    var name: String
    /// Latitudes and longitudes as flat arrays. SwiftData stores arrays of
    /// scalars directly; a `[Coordinate]` would need a transformer for no gain.
    var latitudes: [Double]
    var longitudes: [Double]
    /// Tag keys, not display text, so a saved route re-reads correctly in the
    /// other language.
    var tagKeys: [String]
    var createdAt: Date

    init(
        id: String = "draft-\(UUID().uuidString.prefix(8))",
        name: String,
        coordinates: [CLLocationCoordinate2D],
        tagKeys: [String],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.latitudes = coordinates.map(\.latitude)
        self.longitudes = coordinates.map(\.longitude)
        self.tagKeys = tagKeys
        self.createdAt = createdAt
    }

    var coordinates: [CLLocationCoordinate2D] {
        zip(latitudes, longitudes).map { CLLocationCoordinate2D(latitude: $0, longitude: $1) }
    }
}

// MARK: - The four builder tags

/// The tag vocabulary offered by the builder.
///
/// A fixed set, unlike a route's free-text `tag1`/`tag2` from the catalogue:
/// these are chosen by tapping, so they have to be enumerable and translatable.
enum BuilderTag: String, CaseIterable, Identifiable, Sendable {
    case green, flat, night, loop

    var id: String { rawValue }
    var localizationKey: String { "builder.tag.\(rawValue)" }
}
