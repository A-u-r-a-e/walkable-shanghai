import Foundation
import Observation
import SwiftData

/// Which routes the walker has saved. A saved route is downloaded
/// automatically, and unsaving it deletes the download, so the walker never
/// manages the two separately.
///
/// It keeps the saved ids in memory and writes through to SwiftData on every
/// change. That is deliberate rather than querying the store on each read: the
/// map re-evaluates `isSaved` for every route on every filter change and every
/// redraw, and a `@Query` per row would turn a cheap set lookup into a fetch.
/// The set is the read path; SwiftData is the durability.
@MainActor
@Observable
final class SavedRoutesStore {

    /// The state a fresh install starts with, matching the source design.
    /// Seeded once, then owned by the walker.
    static let seededSaved: Set<String> = ["wukang", "creek", "century"]

    private(set) var savedRouteIds: Set<String> = []

    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let offline: OfflineStore

    /// - Parameter resetToSeed: wipes the stored rows and seeds again. Only the
    ///   UI tests pass this, so each test starts from a known state; without it
    ///   the store is left exactly as the walker left it.
    init(container: ModelContainer, offline: OfflineStore, resetToSeed: Bool = false) {
        self.context = ModelContext(container)
        self.offline = offline
        if resetToSeed {
            wipe()
        }
        seedIfEmpty()
        reload()
    }

    // MARK: - Reading

    func isSaved(_ routeId: String) -> Bool { savedRouteIds.contains(routeId) }

    var savedCount: Int { savedRouteIds.count }

    // MARK: - Writing

    /// Saving and downloading are one state: a saved route is kept on the
    /// phone so it works without a network, and unsaving frees the space.
    func setSaved(_ isSaved: Bool, route: Route) {
        let row = rowOrCreate(route.id)
        row.isSaved = isSaved
        persist()
        if isSaved {
            offline.download(route: route)
        } else {
            offline.remove(routeId: route.id)
        }
        reload()
    }

    func toggleSaved(_ route: Route) {
        setSaved(!isSaved(route.id), route: route)
    }

    /// Builds the download for any saved route that lacks one — the seeded
    /// routes on first launch, or routes saved before saving meant downloading.
    func ensureDownloads(routes: [Route]) {
        for route in routes where isSaved(route.id) && !offline.hasBundle(route.id) {
            offline.download(route: route)
        }
    }

    /// Frees every download. Because saved and downloaded are one state, this
    /// also clears the bookmarks.
    func removeAllDownloads() {
        for row in allRows() where row.isSaved {
            row.isSaved = false
            offline.remove(routeId: row.routeId)
        }
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
        for id in Self.seededSaved {
            context.insert(RouteUserState(routeId: id, isSaved: true))
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
