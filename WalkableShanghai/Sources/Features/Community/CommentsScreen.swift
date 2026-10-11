import SwiftUI

/// Screen 5 — notes from walkers on one route.
///
/// A flat thread, not a tree. The mockup shows a reply *count* on each feed
/// card but never nests anything under a note, and PLAN.md keeps it that way:
/// pretending to support threading with no data model behind it would be worse
/// than a list that is honestly flat.
struct CommentsScreen: View {

    @Environment(AppSettings.self) private var settings
    @Environment(RouteStore.self) private var store
    @Environment(CommunityStore.self) private var community
    @Environment(OfflineStore.self) private var offline
    @Environment(Reachability.self) private var reachability
    @Environment(\.dismiss) private var dismiss

    let routeId: String

    @State private var draft = ""
    @FocusState private var isComposing: Bool

    /// True when the notes should be read out of the download rather than the
    /// catalogue: no network, and this route was actually downloaded.
    private var isReadingOffline: Bool {
        reachability.shouldUseStoredMap(hasBundle: offline.hasBundle(routeId))
    }

    var body: some View {
        let language = settings.language
        let route = isReadingOffline ? offline.storedRoute(routeId) : store.route(id: routeId)

        VStack(spacing: 0) {
            header(routeName: route?.name(language) ?? routeId, language: language)

            ScrollView {
                // One card holding the whole thread, with the separators moved
                // inside it and inset past the avatar. The page no longer rules
                // itself — see DESIGN.md §6.
                LazyVStack(alignment: .leading, spacing: 0) {
                    let comments = thread(language: language)
                    if comments.isEmpty {
                        EmptyStateNote(
                            text: "comments.empty".localized(language),
                            identifier: "comments-empty"
                        )
                    }
                    ForEach(Array(comments.enumerated()), id: \.element.id) { index, comment in
                        row(comment)
                        if index < comments.count - 1 {
                            SeparatorRule(inset: 32 + Theme.Space.s2)
                        }
                    }
                }
                .padding(.horizontal, Theme.Space.s3)
                .card(radius: Theme.Radius.lg)
                .padding(.horizontal, Theme.Space.screen)
                .padding(.top, Theme.Space.s3)
                .padding(.bottom, Theme.Space.s4)
            }

            compose(language: language)
        }
        .screenBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Thread

    /// The walker's own notes, newest first, then the seeded ones.
    ///
    /// Seeded notes carry frozen relative strings rather than timestamps, so
    /// they cannot be sorted against real dates — they keep their published
    /// order underneath.
    private func thread(language: AppLanguage) -> [ThreadComment] {
        let profile = store.profile

        let mine = community.comments(forRoute: routeId).map { comment in
            ThreadComment(
                id: "mine-\(comment.id.uuidString)",
                authorName: profile?.name ?? "",
                authorInitial: profile?.initial ?? "",
                timeText: RelativeTime.text(since: comment.createdAt, language: language),
                body: comment.body,
                // Attaching a place to your own note is excluded this phase.
                pinnedPlace: "",
                isMine: true,
                sortDate: comment.createdAt
            )
        }

        // Offline, the published notes come out of the download. They were
        // stored precisely so that a route you took with you still has its
        // notes when the catalogue is a server you cannot reach.
        let published = isReadingOffline
            ? offline.storedNotes(routeId)
            : store.comments(forRoute: routeId)

        let seeded = published.map { comment in
            ThreadComment(
                id: "seed-\(comment.id)",
                authorName: comment.authorName,
                authorInitial: comment.authorInitial,
                timeText: comment.relativeTime(language),
                body: comment.body(language),
                pinnedPlace: comment.pinnedPlace(language),
                isMine: false,
                sortDate: .distantPast
            )
        }
        return mine + seeded
    }

    private func row(_ comment: ThreadComment) -> some View {
        HStack(alignment: .top, spacing: Theme.Space.s2) {
            AvatarInitial(initial: comment.authorInitial, size: 32, emphasised: comment.isMine)

            VStack(alignment: .leading, spacing: Theme.Space.s1) {
                HStack(spacing: Theme.Space.s2) {
                    Text(comment.authorName)
                        .font(Typography.rowTitle)
                        .foregroundStyle(Theme.label)
                    Text(comment.timeText)
                        .font(Typography.meta)
                        .foregroundStyle(Theme.labelTertiary)
                    Spacer(minLength: 0)
                }

                Text(comment.body)
                    .font(Typography.body)
                    .foregroundStyle(Theme.labelSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                // Only when the note is actually pinned to a corner of the
                // route. An empty row would be a dangling icon.
                if !comment.pinnedPlace.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 11))
                        Text(comment.pinnedPlace)
                            .font(Typography.meta)
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
        }
        .padding(.vertical, Theme.Space.s3)
        .accessibilityIdentifier("comment-\(comment.id)")
    }

    // MARK: - Header and compose

    private func header(routeName: String, language: AppLanguage) -> some View {
        HStack(spacing: Theme.Space.s3) {
            CircularIconButton(system: "chevron.left") { dismiss() }
                .accessibilityIdentifier("comments-back-button")
                .accessibilityLabel("action.back".localized(language))

            VStack(alignment: .leading, spacing: 1) {
                Text("comments.title".localized(language))
                    .font(Typography.heading)
                    .foregroundStyle(Theme.label)
                Text(routeName)
                    .font(Typography.meta)
                    .foregroundStyle(Theme.labelTertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Space.screen)
        .padding(.vertical, Theme.Space.s2)
        // No rule under the bar. The thread below it is a card on the ground,
        // and the gap between the two is what separates them now.
        .background(Theme.bg)
    }

    private func compose(language: AppLanguage) -> some View {
        HStack(spacing: Theme.Space.s2) {
            // A field is a well, not a ruled box: `fill` behind it, radius
            // `sm`, no border.
            TextField("comments.placeholder".localized(language), text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .font(Typography.body)
                .foregroundStyle(Theme.label)
                .focused($isComposing)
                .padding(Theme.Space.s2 + 2)
                .background(Theme.fill, in: Theme.shape(Theme.Radius.sm))
                .accessibilityIdentifier("comment-field")

            Button("comments.post".localized(language)) {
                community.addComment(routeId: routeId, body: draft)
                draft = ""
                isComposing = false
            }
            .buttonStyle(.primaryClassical)
            .fixedSize(horizontal: true, vertical: false)
            // Blank input is refused at the button as well as in the store, so
            // the control tells you it will do nothing before you press it.
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityIdentifier("comment-post-button")
        }
        .padding(.horizontal, Theme.Space.screen)
        .padding(.top, Theme.Space.s2)
        .padding(.bottom, Theme.Space.s3)
        .background(Theme.bg)
    }
}
