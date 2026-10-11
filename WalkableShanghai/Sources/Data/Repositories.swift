import Foundation
import Observation

/// Read access to the route catalogue.
///
/// Every screen goes through this protocol rather than touching a file or a
/// network client. Today the only implementation reads the bundled JSON; when a
/// backend exists it gets a networked implementation with a cache, and no view
/// changes. That is the whole reason the protocol is here this early.
protocol RouteRepository: Sendable {
    func allRoutes() -> [Route]
    func route(id: String) -> Route?
    func featuredRoute() -> Route?
}

// MARK: - Bundled implementation

/// Decodes `SampleData.json` once and serves it from memory.
///
/// Phase 1–2 storage. Note the split this sets up and that a backend would keep:
/// the *catalogue* (routes and the profile seed) is read-only and server-owned;
/// anything the user creates or chooses — saved and offline flags, walks,
/// drafts — goes to SwiftData from Phase 3.
struct BundledDataSource: RouteRepository {

    let data: SampleData

    init(data: SampleData) {
        self.data = data
    }

    // MARK: RouteRepository

    func allRoutes() -> [Route] {
        data.routes
    }

    func route(id: String) -> Route? {
        data.routes.first { $0.id == id }
    }

    func featuredRoute() -> Route? {
        data.routes.first { $0.isFeatured }
    }
}

// MARK: - Loading

enum SampleDataLoader {

    enum LoadError: Error, CustomStringConvertible {
        case missingFile
        case decodingFailed(Error)

        var description: String {
            switch self {
            case .missingFile:
                return "SampleData.json is not in the app bundle."
            case .decodingFailed(let underlying):
                return "SampleData.json did not match the model: \(underlying)"
            }
        }
    }

    /// The one decoder for catalogue JSON. Dates are ISO 8601 calendar dates
    /// ("2026-10-03") so the file stays readable.
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "yyyy-MM-dd"
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }

    /// Loads and decodes the bundled catalogue.
    ///
    /// Throws rather than returning an optional: a missing or malformed bundled
    /// resource is a build mistake, and it should be loud during development
    /// rather than quietly producing an empty app.
    static func load(from bundle: Bundle = .main) throws -> SampleData {
        guard let url = bundle.url(forResource: "SampleData", withExtension: "json") else {
            throw LoadError.missingFile
        }
        do {
            let raw = try Data(contentsOf: url)
            return try decoder.decode(SampleData.self, from: raw)
        } catch {
            throw LoadError.decodingFailed(error)
        }
    }
}

// MARK: - App-wide store

/// Holds the loaded catalogue and hands it to views through the environment.
///
/// Deliberately thin. It is not a view model and holds no screen state — it is
/// the seam where "where does data come from" is answered once.
@Observable
final class RouteStore {

    /// Everything the app treats as a route: the bundled catalogue first, then
    /// anything the walker drew. One list, so the map, the sheet, the filters
    /// and route detail need no notion of origin.
    private(set) var routes: [Route] = []
    private(set) var loadFailure: String?
    private(set) var mineRouteIds: Set<String> = []

    @ObservationIgnored private var source: BundledDataSource?
    @ObservationIgnored private var bundledRoutes: [Route] = []

    /// Who is walking what. Offline for now; see `RouteActivityProvider`.
    @ObservationIgnored private(set) var activity: any RouteActivityProvider = OfflineActivityProvider(counts: [:])

    init(bundle: Bundle = .main) {
        do {
            let data = try SampleDataLoader.load(from: bundle)
            let source = BundledDataSource(data: data)
            self.source = source
            self.bundledRoutes = source.allRoutes()
            self.routes = bundledRoutes
            self.activity = OfflineActivityProvider(counts: data.activity)
        } catch {
            self.loadFailure = String(describing: error)
        }
    }

    /// Folds the walker's drawn routes in after the catalogue, oldest first.
    func setDrawnRoutes(_ drafts: [DraftRoute], authorName: String, authorInitial: String) {
        let drawn = drafts
            .sorted { $0.createdAt < $1.createdAt }
            .map { $0.asRoute(authorName: authorName, authorInitial: authorInitial) }
        routes = bundledRoutes + drawn
        mineRouteIds = Set(drawn.map(\.id))
    }

    /// Looks in the merged list, not just the catalogue, so a drawn route
    /// opens its detail screen like any other.
    func route(id: String) -> Route? { routes.first { $0.id == id } }
    func featuredRoute() -> Route? { source?.featuredRoute() }
    var profile: UserProfileSeed? { source?.data.profile }
}
