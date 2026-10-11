import SwiftUI

/// Screen 9 — the community feed.
///
/// Two tabs over one header. Friends is a list of walks people finished;
/// Creators is a list of collections someone assembled. They share nothing but
/// the header, which is why they are two branches rather than one list with a
/// filter.
struct FeedScreen: View {

    @Environment(AppSettings.self) private var settings
    @Environment(RouteStore.self) private var store
    @Environment(WalkStore.self) private var walks
    @Environment(CommunityStore.self) private var community

    enum Tab: Hashable { case friends, creators }

    @State private var tab: Tab = .friends
    @State private var openRouteId: String?
    @State private var commentsRouteId: String?

    var body: some View {
        let language = settings.language

        VStack(spacing: 0) {
            header(language: language)

            ScrollView {
                // Cards with air between them, rather than rows between rules.
                // The order and the contents are untouched; what divides them
                // has moved from the page to the card edge.
                LazyVStack(alignment: .leading, spacing: Theme.Space.s3) {
                    switch tab {
                    case .friends:
                        friends(language: language)
                    case .creators:
                        creators(language: language)
                    }
                }
                .padding(.horizontal, Theme.Space.screen)
                .padding(.top, Theme.Space.s3)
                .padding(.bottom, Theme.Space.s8 + 72)
            }
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $openRouteId) { RouteDetailScreen(routeId: $0) }
        .navigationDestination(item: $commentsRouteId) { CommentsScreen(routeId: $0) }
    }

    // MARK: - Header

    private func header(language: AppLanguage) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s3) {
            HStack(alignment: .firstTextBaseline) {
                Text("feed.title".localized(language))
                    .font(Typography.title)
                    .foregroundStyle(Theme.label)
                Spacer()
                Text("feed.thisWeek".localized(language))
                    .sectionLabel(color: Theme.labelTertiary)
            }

            SegmentedRing(
                options: [
                    (Tab.friends, "feed.friends".localized(language)),
                    (Tab.creators, "feed.creators".localized(language)),
                ],
                selection: $tab,
                identifiers: ["feed-tab-friends", "feed-tab-creators"]
            )
        }
        .padding(.horizontal, Theme.Space.screen)
        .padding(.top, Theme.Space.s3)
        .padding(.bottom, Theme.Space.s3)
    }

    // MARK: - Friends

    /// Seeded posts, with anything the walker posted in front of them.
    ///
    /// The walker's own walks come first because they are the newest thing that
    /// happened; the seeded posts carry frozen relative times and cannot be
    /// interleaved by date honestly.
    private var feedPosts: [FeedPost] {
        let language = settings.language

        let mine = walks.walksNewestFirst
            .filter(\.isPosted)
            .map { walk in
                FeedPost.fromWalk(
                    walk,
                    route: store.route(id: walk.routeId),
                    profile: store.profile,
                    language: language,
                    replyCount: replyCount(for: walk.routeId)
                )
            }

        let seeded = store.posts().map { post in
            FeedPost.fromSeed(
                post,
                route: store.route(id: post.routeId),
                language: language,
                replyCount: replyCount(for: post.routeId)
            )
        }
        return mine + seeded
    }

    private func replyCount(for routeId: String) -> Int {
        store.comments(forRoute: routeId).count + community.comments(forRoute: routeId).count
    }

    @ViewBuilder
    private func friends(language: AppLanguage) -> some View {
        if feedPosts.isEmpty {
            EmptyStateNote(
                text: "feed.empty.friends".localized(language),
                identifier: "feed-empty-friends"
            )
        }
        ForEach(feedPosts) { post in
            VStack(alignment: .leading, spacing: Theme.Space.s2) {

                HStack(alignment: .top, spacing: Theme.Space.s2) {
                    AvatarInitial(initial: post.authorInitial, size: 34, emphasised: post.isMine)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(post.authorName)
                                .font(Typography.rowTitle)
                                .foregroundStyle(Theme.label)
                            Text("feed.walked".localized(language))
                                .font(Typography.meta)
                                .foregroundStyle(Theme.labelTertiary)
                        }
                        // The route name is the link out of the card.
                        Button { openRouteId = post.routeId } label: {
                            Text(post.routeName)
                                .font(Typography.meta)
                                .foregroundStyle(Theme.accent)
                                .multilineTextAlignment(.leading)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("feed-route-link-\(post.id)")
                    }
                    Spacer(minLength: 0)
                    Text(post.timeText)
                        .font(Typography.meta)
                        .foregroundStyle(Theme.labelTertiary)
                }

                if !post.note.isEmpty {
                    Text(post.note)
                        .font(Typography.body)
                        .foregroundStyle(Theme.labelSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: Theme.Space.s3) {
                    Text("\(figure(post.km)) \("unit.km".localized(language)) · \(post.minutes) \("unit.min".localized(language))")
                        .font(Typography.meta)
                        .foregroundStyle(Theme.labelTertiary)

                    Spacer(minLength: 0)

                    Button { community.toggleLike(post.id) } label: {
                        HStack(spacing: 5) {
                            Image(systemName: community.isLiked(post.id) ? "heart.fill" : "heart")
                                .font(.system(size: 13))
                            Text("\(community.likeCount(base: post.baseLikes, postKey: post.id))")
                                .font(Typography.figure(.caption))
                        }
                        .foregroundStyle(community.isLiked(post.id) ? Theme.accent : Theme.labelSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("feed-like-\(post.id)")
                    .accessibilityLabel("feed.like".localized(language))
                    .accessibilityValue("\(community.likeCount(base: post.baseLikes, postKey: post.id))")

                    Button { commentsRouteId = post.routeId } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 13))
                            Text("\(post.replyCount)")
                                .font(Typography.figure(.caption))
                        }
                        .foregroundStyle(Theme.labelSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("feed-replies-\(post.id)")
                    .accessibilityLabel("feed.replies".localized(language))
                }
            }
            .padding(Theme.Space.s3)
            .card(radius: Theme.Radius.lg)
        }
    }

    private func figure(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    // MARK: - Creators

    @ViewBuilder
    private func creators(language: AppLanguage) -> some View {
        if store.collections().isEmpty {
            EmptyStateNote(
                text: "feed.empty.creators".localized(language),
                identifier: "feed-empty-creators"
            )
        }
        ForEach(store.collections()) { collection in
            let members = collection.routeIds.compactMap { store.route(id: $0) }

            VStack(alignment: .leading, spacing: Theme.Space.s2) {
                Text("feed.collection".localized(language))
                    .sectionLabel()

                Text(collection.name(language))
                    .font(Typography.heading)
                    .foregroundStyle(Theme.label)
                    .accessibilityIdentifier("collection-name-\(collection.id)")

                // Both figures computed from the members, never stored — a
                // stored total goes stale the moment a route is edited.
                Text("feed.collectionMeta".localized(
                    language,
                    collection.curatorName(language),
                    String(members.count),
                    figure(store.totalKm(of: collection))
                ))
                .font(Typography.meta)
                .foregroundStyle(Theme.labelTertiary)
                .accessibilityIdentifier("collection-meta-\(collection.id)")

                // The member list is a group inside the collection's card, so
                // its separators are inset to the content and there is no rule
                // above the first row or below the last.
                VStack(spacing: 0) {
                    ForEach(Array(members.enumerated()), id: \.element.id) { index, route in
                        Button { openRouteId = route.id } label: {
                            HStack(spacing: Theme.Space.s2) {
                                Text("\(route.number)")
                                    .font(Typography.figure(.footnote))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 18, alignment: .leading)
                                Text(route.name(language))
                                    .font(Typography.secondary)
                                    .foregroundStyle(Theme.label)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                                Text("\(figure(route.km)) \("unit.km".localized(language))")
                                    .font(Typography.meta)
                                    .foregroundStyle(Theme.labelTertiary)
                            }
                            .padding(.vertical, Theme.Space.s2)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("collection-route-\(route.id)")
                        if index < members.count - 1 {
                            SeparatorRule(inset: 18 + Theme.Space.s2)
                        }
                    }
                }
                .padding(.horizontal, Theme.Space.s3)
                .padding(.vertical, Theme.Space.s1)
                .background(Theme.bg, in: Theme.shape(Theme.Radius.md))

                Button(
                    (community.followedCollectionIds.contains(collection.id)
                        ? "feed.following" : "feed.follow").localized(language)
                ) {
                    if community.followedCollectionIds.contains(collection.id) {
                        community.followedCollectionIds.remove(collection.id)
                    } else {
                        community.followedCollectionIds.insert(collection.id)
                    }
                }
                .buttonStyle(.secondaryClassical)
                .accessibilityIdentifier("collection-follow-\(collection.id)")
                .padding(.top, Theme.Space.s1)
            }
            .padding(Theme.Space.s3)
            .card(radius: Theme.Radius.lg)
        }
    }
}
