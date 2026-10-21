import Foundation
import SwiftData
import CoreLocation

/// A walk the user actually finished.
///
/// This is the record Phase 8's profile reads to compute walks, total distance
/// and longest walk. `UserProfileSeed` deliberately stores none of those, so
/// this table is their only source. A walk is written here when the walker
/// taps Done on the summary.
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
        photo: Data? = nil
    ) {
        self.id = id
        self.routeId = routeId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.distanceMeters = distanceMeters
        self.elapsedSeconds = elapsedSeconds
        self.note = note
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
    var createdAt: Date

    init(
        id: String = "draft-\(UUID().uuidString.prefix(8))",
        name: String,
        coordinates: [CLLocationCoordinate2D],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.latitudes = coordinates.map(\.latitude)
        self.longitudes = coordinates.map(\.longitude)
        self.createdAt = createdAt
    }

    var coordinates: [CLLocationCoordinate2D] {
        zip(latitudes, longitudes).map { CLLocationCoordinate2D(latitude: $0, longitude: $1) }
    }
}
