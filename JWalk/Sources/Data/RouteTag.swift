import Foundation

/// The tags a route can carry.
///
/// A fixed list the developers own, not free text: tags mark something the
/// app vouches for, like a featured or popular walk. Adding one means adding a
/// case here and its two strings (`tag.<case>`) to the string catalogue.
enum RouteTag: String, Codable, CaseIterable, Sendable {
    case featured
    case popular

    var localizationKey: String { "tag.\(rawValue)" }
}
