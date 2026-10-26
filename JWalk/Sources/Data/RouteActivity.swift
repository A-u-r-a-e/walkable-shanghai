import Foundation

/// The windows Popular can rank by.
enum ActivityPeriod: String, CaseIterable, Sendable {
    case today, week, month, allTime

    var localizationKey: String { "period.\(rawValue)" }
}

/// How many walks a route had in each window.
struct WalkCounts: Codable, Hashable, Sendable {
    let today: Int
    let week: Int
    let month: Int
    let allTime: Int

    func count(for period: ActivityPeriod) -> Int {
        switch period {
        case .today: return today
        case .week: return week
        case .month: return month
        case .allTime: return allTime
        }
    }
}

/// Live and recent activity on routes: who is walking now, and how often each
/// route was walked lately.
///
/// Only a server can know either. Every screen asks through this protocol so
/// that a networked provider can replace the offline one without any view
/// changing.
protocol RouteActivityProvider: Sendable {
    func walkingNow(routeId: String) -> Int
    func walks(routeId: String, period: ActivityPeriod) -> Int
}

/// The provider the app ships with while there is no server.
///
/// Walking-now is zero, which is also what a connected app should show when
/// it cannot reach the server. Recent walk counts come from the bundled
/// catalogue so Popular has something real to sort.
struct OfflineActivityProvider: RouteActivityProvider {
    let counts: [String: WalkCounts]

    func walkingNow(routeId: String) -> Int { 0 }

    func walks(routeId: String, period: ActivityPeriod) -> Int {
        counts[routeId]?.count(for: period) ?? 0
    }
}
