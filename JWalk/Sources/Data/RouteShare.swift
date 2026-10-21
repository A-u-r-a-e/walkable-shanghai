import Foundation
import CoreTransferable
import UniformTypeIdentifiers

/// How a route travels from one walker to another without a server.
///
/// A route is shared two ways at once, because the apps people share through
/// treat them differently: a `jwalk://route?d=…` link, which Messages and Mail
/// make tappable, and a `.jwalk` file, which WeChat, AirDrop and Files carry
/// when they will not open a link. Both hold the same JSON, and opening either
/// in JWalk shows the route's card. Saving it there keeps it, the same way
/// saving any route does.
///
/// Version 1 of the format. Coordinates are integers in units of 1e-5 degrees
/// (about a metre), which keeps a link short enough to send.
struct SharedRoute: Codable, Equatable {

    static let scheme = "jwalk"
    static let currentVersion = 1
    /// Bounds on what a link or file may hold, so a malformed or hostile one
    /// cannot put an empty or enormous line on the map, or an essay in a row.
    static let maxPoints = 5000
    static let maxBytes = 512 * 1024
    static let maxNameLength = 120
    static let maxNoteLength = 2000
    static let maxAuthorLength = 60

    var v: Int = SharedRoute.currentVersion
    let id: String
    let name: LocalizedText
    let note: LocalizedText
    let author: String
    let initial: String
    /// Seconds since 1970.
    let updated: Double
    /// `[latitude, longitude]` pairs, each times 100 000.
    let line: [[Int]]

    init(route: Route) {
        id = route.id
        name = route.name
        note = route.note
        author = route.authorName
        initial = route.authorInitial
        updated = route.updatedAt.timeIntervalSince1970
        line = route.points.map { [Int(($0.lat * 1e5).rounded()), Int(($0.lng * 1e5).rounded())] }
    }

    /// The route this describes, or nil when it does not hold a usable one.
    ///
    /// Tags are not carried: they are the developers' fixed list, so a
    /// received route has none. Distance and time are not carried either but
    /// measured from the line, the way a drawn route's are, so a link cannot
    /// claim a short walk for a long line.
    var route: Route? {
        guard v <= Self.currentVersion,
              !id.isEmpty, id.count <= 64,
              (2...Self.maxPoints).contains(line.count),
              line.allSatisfy({ $0.count == 2 && abs($0[0]) <= 9_000_000 && abs($0[1]) <= 18_000_000 }),
              [name.en, name.zh].allSatisfy({ $0.count <= Self.maxNameLength }),
              [note.en, note.zh].allSatisfy({ $0.count <= Self.maxNoteLength }),
              author.count <= Self.maxAuthorLength
        else { return nil }
        let points = line.map { Coordinate(lat: Double($0[0]) / 1e5, lng: Double($0[1]) / 1e5) }
        let km = ((RouteGeometry.totalMeters(points.map(\.clLocationCoordinate)) / 1000) * 10).rounded() / 10
        // A date from the future, or none at all, reads as today.
        let now = Date()
        let sent = Date(timeIntervalSince1970: updated)
        return Route(
            id: id,
            km: km,
            // The same unhurried 12 minutes a kilometre as a drawn route.
            minutes: Int((km * 12).rounded()),
            name: name,
            note: note,
            authorName: author,
            authorInitial: String(initial.prefix(1)),
            tags: [],
            updatedAt: updated.isFinite && updated > 0 && sent <= now ? sent : now,
            points: points,
            pin: points[0]
        )
    }

    // MARK: - Encoding

    func data() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) -> SharedRoute? {
        guard data.count <= maxBytes else { return nil }
        return try? JSONDecoder().decode(SharedRoute.self, from: data)
    }

    /// `jwalk://route?d=<base64url JSON>`.
    var link: URL? {
        guard let data = try? data() else { return nil }
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = "route"
        components.queryItems = [URLQueryItem(name: "d", value: Self.base64URL(data))]
        return components.url
    }

    /// Reads a route from a `jwalk://` link or from a `.jwalk` file.
    static func route(from url: URL) -> Route? {
        if url.isFileURL {
            let scoped = url.startAccessingSecurityScopedResource()
            defer {
                if scoped { url.stopAccessingSecurityScopedResource() }
                removeFromInbox(url)
            }
            // Sized before it is read: a file too big to be a route is not
            // loaded at all.
            guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
                  size <= maxBytes,
                  let data = try? Data(contentsOf: url)
            else { return nil }
            return decode(data)?.route
        }
        guard url.scheme == scheme, url.host == "route",
              let value = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "d" })?.value,
              value.count <= maxBytes * 2,
              let data = data(base64URL: value)
        else { return nil }
        return decode(data)?.route
    }

    /// iOS copies an opened file into the app's Documents/Inbox. Once read, the
    /// copy is no longer needed; a route the walker keeps is stored as a saved
    /// route's download instead.
    private static func removeFromInbox(_ url: URL) {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let inbox = documents.appendingPathComponent("Inbox").resolvingSymlinksInPath().path + "/"
        guard url.resolvingSymlinksInPath().path.hasPrefix(inbox) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func data(base64URL value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        return Data(base64Encoded: base64)
    }
}

extension UTType {
    /// A `.jwalk` file. Declared in `Config/Info.plist`, which also makes
    /// JWalk the app that opens it.
    static let jwalkRoute = UTType(exportedAs: "com.jwalk.route")
}

/// A route as a `.jwalk` file, for the share sheet.
struct RouteFile: Transferable {
    let route: Route
    let language: AppLanguage

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .jwalkRoute) { file in
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(file.fileName)
                .appendingPathExtension("jwalk")
            try SharedRoute(route: file.route).data().write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }

    /// The route's name, without characters a file name cannot carry.
    private var fileName: String {
        let name = route.name(language)
            .components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>"))
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? route.id : name
    }
}
