import Foundation
import Observation
import SwiftData

/// Everything kept on the phone so one route works with no network.
///
/// This is PLAN.md's option (a), and the coordinator's call: a route is
/// "downloaded" when its own data and a picture of its line are both sitting
/// in the database. No map tiles, which is what makes it cheap
/// — and, given that Shanghai tiles come from Apple's China endpoints via
/// AutoNavi (see the README), what makes it work at all without solving tile
/// hosting first.
///
/// The size shown to the walker is the byte count of exactly these two
/// fields. The mockup printed a flat "18 MB" for every route; that number was
/// fiction, and a storage figure a walker cannot verify is worse than none.
@Model
final class OfflineBundle {

    @Attribute(.unique) var routeId: String
    /// The route itself, encoded. Snapshotted rather than read from the
    /// catalogue at display time so that when routes come from a server, a
    /// downloaded route keeps working after the catalogue moves on.
    var routeData: Data
    /// A picture of the route line, drawn from its own geometry. Externally
    /// stored: it is the only large field here, and the size query does not
    /// need to fault it in.
    @Attribute(.externalStorage) var mapImage: Data
    var downloadedAt: Date

    init(routeId: String, routeData: Data, mapImage: Data, downloadedAt: Date = Date()) {
        self.routeId = routeId
        self.routeData = routeData
        self.mapImage = mapImage
        self.downloadedAt = downloadedAt
    }

    /// What this route actually occupies. Real bytes, not a guess.
    var byteCount: Int { routeData.count + mapImage.count }
}

@MainActor
@Observable
final class OfflineStore {

    private(set) var bundles: [OfflineBundle] = []

    @ObservationIgnored private let context: ModelContext

    init(container: ModelContainer, resetForTests: Bool = false) {
        self.context = ModelContext(container)
        if resetForTests { wipe() }
        reload()
    }

    // MARK: - Reading

    func bundle(for routeId: String) -> OfflineBundle? {
        bundles.first { $0.routeId == routeId }
    }

    func hasBundle(_ routeId: String) -> Bool { bundle(for: routeId) != nil }

    var totalBytes: Int { bundles.reduce(0) { $0 + $1.byteCount } }

    /// The route as it was when downloaded, decoded from the bundle.
    ///
    /// This is the offline read path: it touches the stored snapshot and
    /// nothing else — not the catalogue, not the network.
    func storedRoute(_ routeId: String) -> Route? {
        guard let data = bundle(for: routeId)?.routeData else { return nil }
        return try? JSONDecoder().decode(Route.self, from: data)
    }

    /// Human-readable size, in the walker's language.
    func sizeText(_ routeId: String, language: AppLanguage) -> String {
        Self.sizeText(bytes: bundle(for: routeId)?.byteCount ?? 0, language: language)
    }

    static func sizeText(bytes: Int, language: AppLanguage) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return formatter.string(fromByteCount: Int64(bytes))
    }

    // MARK: - Writing

    /// Builds and stores everything the route needs to work offline.
    ///
    /// Synchronous on purpose: drawing one line onto a small bitmap takes
    /// milliseconds, and there is no network involved. Nothing here is worth a
    /// progress bar, and pretending otherwise would be theatre.
    @discardableResult
    func download(route: Route, imageSize: CGSize = CGSize(width: 900, height: 560)) -> OfflineBundle? {
        guard let routeData = try? JSONEncoder().encode(route),
              let image = RouteImageRenderer.pngData(for: route, size: imageSize)
        else { return nil }

        // Replace rather than duplicate, so re-downloading refreshes.
        remove(routeId: route.id)

        let bundle = OfflineBundle(routeId: route.id, routeData: routeData, mapImage: image)
        context.insert(bundle)
        persist()
        reload()
        return bundle
    }

    func remove(routeId: String) {
        for existing in bundles where existing.routeId == routeId {
            context.delete(existing)
        }
        persist()
        reload()
    }

    // MARK: - Store plumbing

    private func reload() {
        bundles = (try? context.fetch(FetchDescriptor<OfflineBundle>())) ?? []
    }

    private func persist() {
        do {
            try context.save()
        } catch {
            print("[JWalk] Could not save offline bundle: \(error)")
        }
    }

    private func wipe() {
        for bundle in (try? context.fetch(FetchDescriptor<OfflineBundle>())) ?? [] {
            context.delete(bundle)
        }
        persist()
    }
}
