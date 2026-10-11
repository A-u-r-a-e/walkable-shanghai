import XCTest
import SwiftData
@testable import WalkableShanghai

/// Likes, comments, and the flattening that lets one feed carry two very
/// different kinds of post.
@MainActor
final class CommunityTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        try UserStateContainer.make(inMemory: true)
    }

    private func loadCatalogue() throws -> SampleData {
        let hostBundle = Bundle(identifier: "com.walkableshanghai.app") ?? Bundle(for: Self.self)
        return try SampleDataLoader.load(from: hostBundle)
    }

    // MARK: - Likes

    func testLikingIsATogglePersistedAcrossStores() throws {
        let container = try makeContainer()

        let first = CommunityStore(container: container)
        XCTAssertFalse(first.isLiked("seed-p1"))
        first.toggleLike("seed-p1")
        XCTAssertTrue(first.isLiked("seed-p1"))

        // A second store on the same container stands in for a relaunch.
        let reopened = CommunityStore(container: container)
        XCTAssertTrue(reopened.isLiked("seed-p1"), "the like did not persist")

        reopened.toggleLike("seed-p1")
        XCTAssertFalse(CommunityStore(container: container).isLiked("seed-p1"),
                       "un-liking did not persist")
    }

    func testLikeAdjustsTheCountByExactlyOne() throws {
        let store = CommunityStore(container: try makeContainer())
        XCTAssertEqual(store.likeCount(base: 12, postKey: "p"), 12)
        store.toggleLike("p")
        XCTAssertEqual(store.likeCount(base: 12, postKey: "p"), 13,
                       "your own like should add exactly one")
        store.toggleLike("p")
        XCTAssertEqual(store.likeCount(base: 12, postKey: "p"), 12)
    }

    func testLikesAreIndependentPerPost() throws {
        let store = CommunityStore(container: try makeContainer())
        store.toggleLike("a")
        XCTAssertTrue(store.isLiked("a"))
        XCTAssertFalse(store.isLiked("b"), "liking one post liked another")
    }

    // MARK: - Comments

    func testACommentPersistsAndIsNewestFirst() throws {
        let container = try makeContainer()

        let first = CommunityStore(container: container)
        first.addComment(routeId: "wukang", body: "Quiet before nine.")
        // Distinct timestamps, so the ordering assertion is about sorting
        // rather than about how fast the test machine is.
        Thread.sleep(forTimeInterval: 0.02)
        first.addComment(routeId: "wukang", body: "The plane trees are the point.")

        let reopened = CommunityStore(container: container)
        let mine = reopened.comments(forRoute: "wukang")
        XCTAssertEqual(mine.count, 2, "the comments did not persist")
        XCTAssertEqual(mine.first?.body, "The plane trees are the point.",
                       "the newest comment should be first")
    }

    func testEmptyCommentsAreIgnored() throws {
        let store = CommunityStore(container: try makeContainer())
        XCTAssertNil(store.addComment(routeId: "wukang", body: ""))
        XCTAssertNil(store.addComment(routeId: "wukang", body: "   \n  "))
        XCTAssertTrue(store.comments(forRoute: "wukang").isEmpty,
                      "blank input was stored as a comment")

        // And a real one is trimmed rather than stored with its whitespace.
        store.addComment(routeId: "wukang", body: "  Good in the rain.  ")
        XCTAssertEqual(store.comments(forRoute: "wukang").first?.body, "Good in the rain.")
    }

    func testCommentsAreScopedToTheirRoute() throws {
        let store = CommunityStore(container: try makeContainer())
        store.addComment(routeId: "wukang", body: "A")
        store.addComment(routeId: "creek", body: "B")

        XCTAssertEqual(store.comments(forRoute: "wukang").map(\.body), ["A"])
        XCTAssertEqual(store.comments(forRoute: "creek").map(\.body), ["B"])
        XCTAssertTrue(store.comments(forRoute: "bund").isEmpty)
    }

    func testFollowingIsLocalAndDoesNotPersist() throws {
        let container = try makeContainer()
        let first = CommunityStore(container: container)
        first.followedCollectionIds.insert("col-concession")

        // PLAN.md excludes real following from this phase, so this must NOT
        // survive - if it ever does, that is a decision, not a side effect.
        let reopened = CommunityStore(container: container)
        XCTAssertFalse(reopened.followedCollectionIds.contains("col-concession"))
    }

    // MARK: - Feed flattening

    func testASeededPostFlattensWithItsRouteName() throws {
        let data = try loadCatalogue()
        let source = BundledDataSource(data: data)
        let post = try XCTUnwrap(data.posts.first)
        let route = source.route(id: post.routeId)

        let flat = FeedPost.fromSeed(post, route: route, language: .english, replyCount: 4)
        XCTAssertEqual(flat.id, "seed-\(post.id)")
        XCTAssertEqual(flat.routeName, route?.name(.english))
        XCTAssertEqual(flat.baseLikes, post.baseLikes)
        XCTAssertEqual(flat.replyCount, 4)
        XCTAssertFalse(flat.isMine)

        // And it is genuinely bilingual, not English text reused.
        let zh = FeedPost.fromSeed(post, route: route, language: .chinese, replyCount: 0)
        XCTAssertNotEqual(zh.routeName, flat.routeName)
        XCTAssertNotEqual(zh.note, flat.note)
    }

    func testAPostedWalkFlattensIntoTheSameShape() throws {
        let data = try loadCatalogue()
        let source = BundledDataSource(data: data)
        let walkStore = WalkStore(container: try makeContainer())
        let end = Date()

        let walk = walkStore.record(
            routeId: "wukang",
            startedAt: end.addingTimeInterval(-3120),
            endedAt: end,
            distanceMeters: 3449,
            elapsedSeconds: 3120,
            note: "Quiet before nine.",
            isPosted: true,
            photo: nil
        )

        let flat = FeedPost.fromWalk(
            walk,
            route: source.route(id: "wukang"),
            profile: data.profile,
            language: .english,
            replyCount: 4,
            now: end
        )
        XCTAssertEqual(flat.id, "walk-\(walk.id.uuidString)")
        XCTAssertEqual(flat.authorName, data.profile.name)
        XCTAssertEqual(flat.routeName, "Wukang Road & the Concession Lanes")
        XCTAssertEqual(flat.km, 3.4, accuracy: 0.001, "distance should round to one decimal")
        XCTAssertEqual(flat.minutes, 52)
        XCTAssertEqual(flat.note, "Quiet before nine.")
        XCTAssertTrue(flat.isMine)
        // Nobody has seen it, so it starts at nothing rather than borrowing a
        // number from the seeded posts.
        XCTAssertEqual(flat.baseLikes, 0)
        XCTAssertEqual(flat.timeText, "Just now")
    }

    func testOnlyPostedWalksAreEligibleForTheFeed() throws {
        let store = WalkStore(container: try makeContainer())
        let now = Date()
        store.record(routeId: "wukang", startedAt: now, endedAt: now, distanceMeters: 100,
                     elapsedSeconds: 60, note: "", isPosted: true, photo: nil)
        store.record(routeId: "creek", startedAt: now, endedAt: now, distanceMeters: 100,
                     elapsedSeconds: 60, note: "", isPosted: false, photo: nil)

        let eligible = store.walksNewestFirst.filter(\.isPosted)
        XCTAssertEqual(eligible.count, 1)
        XCTAssertEqual(eligible.first?.routeId, "wukang")
        // But both are still stored, because the profile counts them all.
        XCTAssertEqual(store.walkCount, 2)
    }

    // MARK: - Relative time

    func testRelativeTimeReadsInBothLanguages() {
        let now = Date()
        XCTAssertEqual(RelativeTime.text(since: now, language: .english, now: now), "Just now")
        XCTAssertEqual(RelativeTime.text(since: now, language: .chinese, now: now), "刚刚")

        let cases: [(TimeInterval, String)] = [
            (600, "10 minutes ago"),
            (7200, "2 hours ago"),
            (86_400 * 3, "3 days ago"),
        ]
        for (ago, expected) in cases {
            XCTAssertEqual(
                RelativeTime.text(since: now.addingTimeInterval(-ago), language: .english, now: now),
                expected
            )
            // The Chinese form must differ, not fall through to English.
            XCTAssertNotEqual(
                RelativeTime.text(since: now.addingTimeInterval(-ago), language: .chinese, now: now),
                expected
            )
        }
    }

    // MARK: - Collections

    func testCollectionTotalsAreComputedFromMembers() throws {
        let data = try loadCatalogue()
        let store = RouteStore()

        for collection in data.collections {
            let members = collection.routeIds.compactMap { store.route(id: $0) }
            XCTAssertEqual(members.count, collection.routeIds.count,
                           "\(collection.id) references a route that does not exist")
            let expected = ((members.reduce(0) { $0 + $1.km }) * 10).rounded() / 10
            XCTAssertEqual(store.totalKm(of: collection), expected, accuracy: 0.001)
        }
        XCTAssertEqual(data.collections.count, 2)
    }
}
