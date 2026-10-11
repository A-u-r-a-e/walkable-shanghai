import Foundation
import SwiftData

/// What *this walker* has decided about a route: kept it. Keeping a route
/// also downloads it, so there is no separate offline flag.
///
/// This is the first thing in the app that SwiftData owns, and the split it
/// marks is the one `Repositories.swift` set up in Phase 1. The catalogue —
/// routes, their geometry, their notes — is read-only and will one day come
/// from a server. Choices belong to the person holding the phone, must survive
/// a relaunch, and must never be overwritten by a catalogue refresh. So they
/// live here instead.
///
/// Keyed by `routeId` rather than by a relationship to a `Route`, because
/// `Route` is a decoded value type from the bundled JSON, not a stored model.
/// When routes eventually come from a backend, this table still works: it
/// references them by the same string id the server uses.
@Model
final class RouteUserState {

    /// One row per route. Unique so a toggle can never create a duplicate.
    @Attribute(.unique) var routeId: String
    var isSaved: Bool

    init(routeId: String, isSaved: Bool = false) {
        self.routeId = routeId
        self.isSaved = isSaved
    }
}

// MARK: - Container

enum UserStateContainer {

    /// The models SwiftData manages. Everything here is the walker's own;
    /// nothing from the bundled catalogue ever will be.
    static let schema = Schema([
        RouteUserState.self, StoredWalk.self, DraftRoute.self,
        OfflineBundle.self,
    ])

    /// Builds the store the app runs on.
    ///
    /// `inMemory` is for tests, which need a fresh store per run and must never
    /// touch the simulator's real database.
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Falls back to an in-memory store if the on-disk one cannot be opened.
    ///
    /// A corrupt or unreadable store is worth surviving: the walker loses their
    /// saved flags, which is bad, but the app still opens, which is the
    /// difference between a bug report and a one-star review. The failure is
    /// printed rather than swallowed silently.
    static func makeOrFallBack(inMemory: Bool = false) -> ModelContainer {
        do {
            return try make(inMemory: inMemory)
        } catch {
            print("[WalkableShanghai] Could not open the user-state store, continuing in memory: \(error)")
            // If even this throws the app genuinely cannot run.
            return try! make(inMemory: true)
        }
    }
}
