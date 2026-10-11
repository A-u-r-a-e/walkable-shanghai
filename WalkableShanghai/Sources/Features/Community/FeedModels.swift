import Foundation

/// One card in the Friends feed, whoever wrote it.
///
/// The feed mixes two sources that have nothing structurally in common: seeded
/// `Post` values from the catalogue, and `StoredWalk` rows the walker chose to
/// post in Phase 5. Rather than teach the view about both, each is flattened
/// into this once. The view then has no idea which is which, which is the point
/// — a walk you posted should sit in the feed looking like any other.
struct FeedPost: Identifiable, Hashable {

    /// Stable across launches, because it keys the persisted like.
    let id: String
    let authorName: String
    let authorInitial: String
    let routeId: String
    let routeName: String
    let timeText: String
    let km: Double
    let minutes: Int
    let note: String
    let replyCount: Int
    /// Likes from everyone else. The current walker's own like is added on top
    /// at display time, so toggling it never has to rewrite this.
    let baseLikes: Int
    /// True for the walker's own posted walks, which get a gold ring on the
    /// avatar and no photograph placeholder they cannot fill.
    let isMine: Bool

    static func fromSeed(_ post: Post, route: Route?, language: AppLanguage, replyCount: Int) -> FeedPost {
        FeedPost(
            id: "seed-\(post.id)",
            authorName: post.authorName,
            authorInitial: post.authorInitial,
            routeId: post.routeId,
            routeName: route?.name(language) ?? post.routeId,
            timeText: post.relativeTime(language),
            km: post.km,
            minutes: post.minutes,
            note: post.note(language),
            // The real number of notes on this route, not the seeded post's
            // own figure. Otherwise a card claims "4 replies" and opens a
            // thread with none, and a note you just wrote never shows up in
            // the count.
            replyCount: replyCount,
            baseLikes: post.baseLikes,
            isMine: false
        )
    }

    static func fromWalk(
        _ walk: StoredWalk,
        route: Route?,
        profile: UserProfileSeed?,
        language: AppLanguage,
        replyCount: Int,
        now: Date = Date()
    ) -> FeedPost {
        FeedPost(
            id: "walk-\(walk.id.uuidString)",
            authorName: profile?.name ?? "",
            authorInitial: profile?.initial ?? "",
            routeId: walk.routeId,
            routeName: route?.name(language) ?? walk.routeId,
            timeText: RelativeTime.text(since: walk.endedAt, language: language, now: now),
            km: (walk.distanceKm * 10).rounded() / 10,
            minutes: Int((walk.elapsedSeconds / 60).rounded()),
            note: walk.note,
            replyCount: replyCount,
            // Nobody has seen it yet, so it starts at nothing rather than
            // borrowing a number from the seeded posts.
            baseLikes: 0,
            isMine: true
        )
    }
}

/// One note under a route, seeded or written by the walker.
struct ThreadComment: Identifiable, Hashable {
    let id: String
    let authorName: String
    let authorInitial: String
    let timeText: String
    let body: String
    /// "Wukang Rd × Hunan Rd", or empty. The walker's own notes never carry one
    /// — attaching a place is excluded from this phase, as in the mockup.
    let pinnedPlace: String
    let isMine: Bool
    /// Sort key. Seeded notes have no real timestamp, so they fall back to
    /// distant past and sit under anything the walker writes.
    let sortDate: Date
}
