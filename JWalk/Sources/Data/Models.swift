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

/// The core entity: a walk someone has done end to end and published.
struct Route: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let km: Double
    let minutes: Int

    let name: LocalizedText
    /// The description shown on the route card.
    let note: LocalizedText

    let authorName: String
    /// One character, drawn in the avatar circle.
    let authorInitial: String

    /// From the fixed list in `RouteTag`. Order is display order.
    let tags: [RouteTag]
    /// When the route's line or description last changed.
    let updatedAt: Date

    let points: [Coordinate]
    /// Where the map pin sits — not necessarily on the line.
    let pin: Coordinate

    var isFeatured: Bool { tags.contains(.featured) }
}

extension Route {
    /// Distance and time as the list rows and the route card show them,
    /// "3.4 km · 52 min", so the two never drift apart.
    func figures(_ language: AppLanguage) -> String {
        "\(String(format: "%.1f", km)) \("unit.km".localized(language)) · \(minutes) \("unit.min".localized(language))"
    }

    /// The day the route last changed, as "Oct 3". Formatted in Shanghai time
    /// because catalogue dates decode as midnight there; in the device's zone a
    /// phone west of UTC+8 would show the day before.
    func updatedDay(_ language: AppLanguage) -> String {
        var style = Date.FormatStyle.dateTime.day().month(.abbreviated).locale(language.locale)
        style.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return updatedAt.formatted(style)
    }
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
    let activity: [String: WalkCounts]
}
