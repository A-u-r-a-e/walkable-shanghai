import Foundation
import Observation
import SwiftData

/// Which routes the walker has saved, and which they have downloaded.
///
/// Phase 2 backed this with a plain `Set` and a note saying SwiftData would
/// take over "without the call sites changing". This is that swap, and the
/// promise held: the public surface below — `isSaved`, `isOffline`,
/// `toggleSaved`, `toggleOffline`, `savedCount` — is unchanged, so the map
/// screen and its filter needed no edits.
///
/// It keeps the two id sets in memory and writes through to SwiftData on every
/// toggle. That is deliberate rather than querying the store on each read: the
/// map re-evaluates `isSaved` for every route on every filter change and every
/// redraw, and a `@Query` per row would turn a cheap set lookup into a fetch.
/// The sets are the read path; SwiftData is the durability.
@Observable
final class SavedRoutesStore {

    /// The state a fresh install starts with, matching the source design.
    /// Seeded once, then owned by the walker.
    static let seededSaved: Set<String> = ["wukang", "creek", "century"]
    static let seededOffline: Set<String> = ["fuxing", "wukang"]

    private(set) var savedRouteIds: Set<String> = []
    private(set) var offlineRouteIds: Set<String> = []

    @ObservationIgnored private let context: ModelContext

    /// - Parameter resetToSeed: wipes the stored rows and seeds again. Only the
    ///   UI tests pass this, so each test starts from a known state; without it
    ///   the store is left exactly as the walker left it.
    init(container: ModelContainer, resetToSeed: Bool = false) {
        self.context = ModelContext(container)

        if resetToSeed {
            wipe()
        }
        seedIfEmpty()
        reload()
    }

    // MARK: - Reading

    func isSaved(_ routeId: String) -> Bool { savedRouteIds.contains(routeId) }
    func isOffline(_ routeId: String) -> Bool { offlineRouteIds.contains(routeId) }

    var savedCount: Int { savedRouteIds.count }
    var offlineCount: Int { offlineRouteIds.count }

    // MARK: - Writing

    func toggleSaved(_ routeId: String) {
        let row = rowOrCreate(routeId)
        row.isSaved.toggle()
        persist()
        reload()
    }

    func toggleOffline(_ routeId: String) {
        let row = rowOrCreate(routeId)
        row.isOffline.toggle()
        persist()
        reload()
    }

    // MARK: - Store plumbing

    private func rowOrCreate(_ routeId: String) -> RouteUserState {
        if let existing = row(for: routeId) { return existing }
        let created = RouteUserState(routeId: routeId)
        context.insert(created)
        return created
    }

    private func row(for routeId: String) -> RouteUserState? {
        // The predicate captures a plain local, which is what SwiftData's macro
        // expects — it cannot capture a property access.
        let id = routeId
        let descriptor = FetchDescriptor<RouteUserState>(
            predicate: #Predicate { $0.routeId == id }
        )
        return try? context.fetch(descriptor).first
    }

    private func allRows() -> [RouteUserState] {
        (try? context.fetch(FetchDescriptor<RouteUserState>())) ?? []
    }

    /// Rebuilds the in-memory sets from the store, so what the UI reads is
    /// always what was actually written.
    private func reload() {
        let rows = allRows()
        savedRouteIds = Set(rows.filter(\.isSaved).map(\.routeId))
        offlineRouteIds = Set(rows.filter(\.isOffline).map(\.routeId))
    }

    private func persist() {
        do {
            try context.save()
        } catch {
            print("[WalkableShanghai] Could not save route user state: \(error)")
        }
    }

    private func seedIfEmpty() {
        guard allRows().isEmpty else { return }
        let ids = Self.seededSaved.union(Self.seededOffline)
        for id in ids {
            context.insert(
                RouteUserState(
                    routeId: id,
                    isSaved: Self.seededSaved.contains(id),
                    isOffline: Self.seededOffline.contains(id)
                )
            )
        }
        persist()
    }

    private func wipe() {
        for row in allRows() {
            context.delete(row)
        }
        persist()
    }
}
