import Foundation
import CoreLocation

/// The five ways the Routes sheet can list routes.
enum RouteListOption: String, CaseIterable, Sendable {
    case nearby, popular, featured, mine, saved

    var localizationKey: String { "routes.option.\(rawValue)" }
}

/// Everything that decides the sheet's contents.
struct RouteListQuery: Equatable, Sendable {
    var option: RouteListOption = .nearby
    /// Only Popular reads this.
    var period: ActivityPeriod = .week
    var searchText = ""
}

struct RouteListSection: Equatable, Sendable {
    enum Kind: Sendable { case all, mine, saved }

    let kind: Kind
    let routes: [Route]
    /// The walker's own section carries the New route button.
    let offersNewRoute: Bool
}

/// What the sheet lists, decided without any view.
///
/// Kept pure so every ordering rule is a unit test rather than a screenshot.
/// The map's pins are drawn from the same sections, so the two never disagree.
enum RouteList {

    /// Where Nearby measures from when the walker's location is unknown.
    static let peoplesSquare = Coordinate(lat: 31.2304, lng: 121.4737)

    static func sections(
        routes: [Route],
        query: RouteListQuery,
        mineIds: Set<String>,
        savedIds: Set<String>,
        origin: Coordinate?,
        activity: any RouteActivityProvider
    ) -> [RouteListSection] {
        let visible = routes.filter { matches($0, search: query.searchText) }

        switch query.option {
        case .nearby:
            let from = location(origin ?? peoplesSquare)
            let sorted = visible.sorted {
                location($0.pin).distance(from: from) < location($1.pin).distance(from: from)
            }
            return [RouteListSection(kind: .all, routes: sorted, offersNewRoute: false)]

        case .popular:
            let ranked = visible
                .map { ($0, activity.walks(routeId: $0.id, period: query.period)) }
                .filter { $0.1 > 0 }
                .enumerated()
                // Ties keep catalogue order, so the list does not shuffle
                // between launches.
                .sorted { $0.element.1 != $1.element.1 ? $0.element.1 > $1.element.1 : $0.offset < $1.offset }
                .map { $0.element.0 }
            return [RouteListSection(kind: .all, routes: ranked, offersNewRoute: false)]

        case .featured:
            return [RouteListSection(kind: .all, routes: visible.filter(\.isFeatured), offersNewRoute: false)]

        case .mine:
            return [RouteListSection(kind: .mine, routes: visible.filter { mineIds.contains($0.id) }, offersNewRoute: true)]

        case .saved:
            let mine = visible.filter { mineIds.contains($0.id) }
            // A route the walker drew and also bookmarked shows once, as theirs.
            let saved = visible.filter { savedIds.contains($0.id) && !mineIds.contains($0.id) }
            return [
                RouteListSection(kind: .mine, routes: mine, offersNewRoute: true),
                RouteListSection(kind: .saved, routes: saved, offersNewRoute: false),
            ]
        }
    }

    /// Case-insensitive match on the route name in either language.
    static func matches(_ route: Route, search: String) -> Bool {
        let needle = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return true }
        return route.name.en.localizedCaseInsensitiveContains(needle)
            || route.name.zh.localizedCaseInsensitiveContains(needle)
    }

    private static func location(_ coordinate: Coordinate) -> CLLocation {
        CLLocation(latitude: coordinate.lat, longitude: coordinate.lng)
    }
}
