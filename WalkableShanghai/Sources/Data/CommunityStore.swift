import Foundation
import Observation
import SwiftData

/// A post the walker has liked.
///
/// A row means liked; no row means not. Storing the negative case too would let
/// the table grow with every post ever scrolled past for no gain.
@Model
final class PostLike {
    @Attribute(.unique) var postKey: String
    var likedAt: Date

    init(postKey: String, likedAt: Date = Date()) {
        self.postKey = postKey
        self.likedAt = likedAt
    }
}

/// A note the walker left on a route.
///
/// Kept apart from the seeded `RouteComment` values, which are catalogue
/// content and read-only. Merging happens at read time, so a catalogue refresh
/// can never overwrite something the walker wrote.
@Model
final class UserComment {
    @Attribute(.unique) var id: UUID
    var routeId: String
    var body: String
    var createdAt: Date

    init(id: UUID = UUID(), routeId: String, body: String, createdAt: Date = Date()) {
        self.id = id
        self.routeId = routeId
        self.body = body
        self.createdAt = createdAt
    }
}

/// Likes and the walker's own comments.
@MainActor
@Observable
final class CommunityStore {

    private(set) var likedPostKeys: Set<String> = []
    private(set) var comments: [UserComment] = []
    /// Followed curators. Local state only — PLAN.md excludes real following
    /// from this phase, so this deliberately does not persist.
    var followedCollectionIds: Set<String> = []

    @ObservationIgnored private let context: ModelContext

    init(container: ModelContainer, resetForTests: Bool = false) {
        self.context = ModelContext(container)
        if resetForTests { wipe() }
        reload()
    }

    // MARK: - Likes

    func isLiked(_ postKey: String) -> Bool { likedPostKeys.contains(postKey) }

    /// The count to show: the post's own likes plus this walker's, if given.
    func likeCount(base: Int, postKey: String) -> Int {
        base + (isLiked(postKey) ? 1 : 0)
    }

    func toggleLike(_ postKey: String) {
        if let existing = likeRow(postKey) {
            context.delete(existing)
        } else {
            context.insert(PostLike(postKey: postKey))
        }
        persist()
        reload()
    }

    // MARK: - Comments

    /// The walker's notes on one route, newest first.
    func comments(forRoute routeId: String) -> [UserComment] {
        comments.filter { $0.routeId == routeId }.sorted { $0.createdAt > $1.createdAt }
    }

    /// Adds a note. Blank input is ignored rather than stored as an empty row.
    @discardableResult
    func addComment(routeId: String, body: String) -> UserComment? {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let comment = UserComment(routeId: routeId, body: trimmed)
        context.insert(comment)
        persist()
        reload()
        return comment
    }

    // MARK: - Store plumbing

    private func likeRow(_ postKey: String) -> PostLike? {
        let key = postKey
        let descriptor = FetchDescriptor<PostLike>(predicate: #Predicate { $0.postKey == key })
        return try? context.fetch(descriptor).first
    }

    private func reload() {
        likedPostKeys = Set(((try? context.fetch(FetchDescriptor<PostLike>())) ?? []).map(\.postKey))
        comments = (try? context.fetch(FetchDescriptor<UserComment>())) ?? []
    }

    private func persist() {
        do {
            try context.save()
        } catch {
            print("[WalkableShanghai] Could not save community state: \(error)")
        }
    }

    private func wipe() {
        for row in (try? context.fetch(FetchDescriptor<PostLike>())) ?? [] { context.delete(row) }
        for row in (try? context.fetch(FetchDescriptor<UserComment>())) ?? [] { context.delete(row) }
        persist()
    }
}

// MARK: - Relative time

/// "Just now", "3 hours ago", "2 days ago", in either language.
///
/// The seeded posts and comments carry frozen strings because they are content;
/// anything the walker writes gets a real timestamp and is formatted here, so it
/// ages correctly instead of saying "Just now" forever.
enum RelativeTime {

    static func text(since date: Date, language: AppLanguage, now: Date = Date()) -> String {
        let seconds = max(0, now.timeIntervalSince(date))

        switch seconds {
        case ..<60:
            return "time.justNow".localized(language)
        case ..<3600:
            return "time.minutesAgo".localized(language, count: Int(seconds / 60))
        case ..<86_400:
            return "time.hoursAgo".localized(language, count: Int(seconds / 3600))
        default:
            return "time.daysAgo".localized(language, count: Int(seconds / 86_400))
        }
    }
}
