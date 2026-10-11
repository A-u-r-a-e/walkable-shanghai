import Foundation
import Observation
import SwiftData
import CoreLocation

/// Finished walks, and the routes the walker drew.
///
/// Sits beside `SavedRoutesStore` rather than inside it: that one holds flags
/// *about* catalogue routes, this one holds things the walker made. Both are
/// theirs, but only these have to be summed and counted later, and Phase 8's
/// profile figures read straight off this type.
@MainActor
@Observable
final class WalkStore {

    private(set) var walks: [StoredWalk] = []
    private(set) var draftRoutes: [DraftRoute] = []

    @ObservationIgnored private let context: ModelContext

    init(container: ModelContainer, resetForTests: Bool = false) {
        self.context = ModelContext(container)
        if resetForTests { wipe() }
        reload()
    }

    // MARK: - Reading

    /// Newest first, which is the order every screen wants.
    var walksNewestFirst: [StoredWalk] {
        walks.sorted { $0.endedAt > $1.endedAt }
    }

    var walkCount: Int { walks.count }
    var totalKm: Double { walks.reduce(0) { $0 + $1.distanceKm } }

    /// The longest walk so far, in metres. Nil until there is one.
    var bestDistanceMeters: Double? {
        walks.map(\.distanceMeters).max()
    }

    /// How much further a given distance is than the best walk *before* it.
    ///
    /// Nil on the first ever walk: there is no previous best to beat, and
    /// reporting the whole distance as an improvement would be a lie.
    func metersOverBest(_ distanceMeters: Double, excluding id: UUID? = nil) -> Double? {
        let previous = walks
            .filter { $0.id != id }
            .map(\.distanceMeters)
            .max()
        guard let previous else { return nil }
        return distanceMeters - previous
    }

    // MARK: - Writing

    @discardableResult
    func record(
        routeId: String,
        startedAt: Date,
        endedAt: Date,
        distanceMeters: Double,
        elapsedSeconds: Double,
        note: String,
        isPosted: Bool,
        photo: Data?
    ) -> StoredWalk {
        let walk = StoredWalk(
            routeId: routeId,
            startedAt: startedAt,
            endedAt: endedAt,
            distanceMeters: distanceMeters,
            elapsedSeconds: elapsedSeconds,
            note: note,
            isPosted: isPosted,
            photo: photo
        )
        context.insert(walk)
        persist()
        reload()
        return walk
    }

    @discardableResult
    func saveDraftRoute(
        name: String,
        coordinates: [CLLocationCoordinate2D],
        tagKeys: [String]
    ) -> DraftRoute {
        let draft = DraftRoute(name: name, coordinates: coordinates, tagKeys: tagKeys)
        context.insert(draft)
        persist()
        reload()
        return draft
    }

    // MARK: - Store plumbing

    private func reload() {
        walks = (try? context.fetch(FetchDescriptor<StoredWalk>())) ?? []
        draftRoutes = (try? context.fetch(FetchDescriptor<DraftRoute>())) ?? []
    }

    private func persist() {
        do {
            try context.save()
        } catch {
            print("[WalkableShanghai] Could not save walk records: \(error)")
        }
    }

    private func wipe() {
        for walk in (try? context.fetch(FetchDescriptor<StoredWalk>())) ?? [] {
            context.delete(walk)
        }
        for draft in (try? context.fetch(FetchDescriptor<DraftRoute>())) ?? [] {
            context.delete(draft)
        }
        persist()
    }
}

// MARK: - Drafts as routes

extension DraftRoute {

    /// Presents a drawn route as an ordinary `Route`, so the map, the sheet and
    /// route detail need no notion of where a route came from.
    ///
    /// The fields the catalogue supplies editorially — a kicker, two character
    /// tags, a walker's note — are left as the walker's own tags or blank
    /// rather than invented. A route you drew this morning has no note from
    /// anyone yet, and pretending otherwise would be filling the screen with
    /// fiction.
    func asRoute(number: Int, authorName: String, authorInitial: String) -> Route {
        let line = coordinates
        let km = ((RouteGeometry.totalMeters(line) / 1000) * 10).rounded() / 10
        // 12 minutes per kilometre: an unhurried city walking pace, and the
        // same figure the builder shows while drawing.
        let minutes = Int((km * 12).rounded())

        // Resolved into both languages here rather than stored as keys.
        // `LocalizedText` carries content, not resource names — a key left in
        // it would render literally as "builder.yourRoute" on screen.
        func bilingual(_ key: String) -> LocalizedText {
            LocalizedText(en: L10n.string(key, .english), zh: L10n.string(key, .chinese))
        }
        let chosen = tagKeys.compactMap { BuilderTag(rawValue: $0) }
        // Empty rather than a placeholder chip when fewer than two tags were
        // picked; the detail screen skips empty tags.
        let empty = LocalizedText(en: "", zh: "")

        return Route(
            id: id,
            number: number,
            km: km,
            minutes: minutes,
            // A drawn route has not been walked yet, so its dead ends are
            // unknown. Zero is a claim this app takes seriously - it is the
            // whole proposition - so it is not an honest default here. Until
            // the route is walked, this reports nothing rather than a zero it
            // has not earned.
            breaks: 0,
            name: LocalizedText(en: name, zh: name),
            area: bilingual("builder.yourRoute.area"),
            kicker: bilingual("builder.yourRoute"),
            tag1: chosen.first.map { bilingual($0.localizationKey) } ?? empty,
            tag2: chosen.dropFirst().first.map { bilingual($0.localizationKey) } ?? empty,
            note: empty,
            authorName: authorName,
            authorInitial: authorInitial,
            walkCount: 0,
            downloadSize: "\u{2014}",
            points: line.map { Coordinate(lat: $0.latitude, lng: $0.longitude) },
            pin: line.first.map { Coordinate(lat: $0.latitude, lng: $0.longitude) }
                ?? Coordinate(lat: 31.2232, lng: 121.4680),
            isFeatured: false
        )
    }
}
