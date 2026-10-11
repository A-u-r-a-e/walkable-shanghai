import SwiftUI

/// Screen 3 — one route, in full.
///
/// The map is fixed at the top rather than scrolling with the content: the line
/// is the thing being described, and it should stay visible while you read
/// about it. Back and bookmark float over it, because the map is full-bleed and
/// has no bar of its own.
struct RouteDetailScreen: View {

    @Environment(AppSettings.self) private var settings
    @Environment(RouteStore.self) private var store
    @Environment(SavedRoutesStore.self) private var saved
    @Environment(OfflineStore.self) private var offline
    @Environment(Reachability.self) private var reachability
    @Environment(\.dismiss) private var dismiss

    let routeId: String

    @State private var trackingRoute: Route?

    var body: some View {
        let language = settings.language

        Group {
            if let route = resolvedRoute {
                content(route: route, language: language)
            } else {
                // Only reachable if a route id outlives its route, which would
                // be a catalogue bug. Say so rather than showing a blank page.
                Text("route.missing".localized(language, routeId))
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.labelTertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .screenBackground()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $trackingRoute) { route in
            // Finishing a walk unwinds the whole way out, not just back to this
            // screen. You have walked the route; being returned to its
            // description would be a step backwards.
            TrackingScreen(route: route) {
                // Two pops, one after the other rather than both in the same
                // runloop turn: clearing the destination pops tracking, and
                // dismissing this screen has to wait for that to land or the
                // navigation stack drops one of them and nothing moves.
                trackingRoute = nil
                DispatchQueue.main.async { dismiss() }
            }
        }
    }

    /// True when this screen should read the download rather than the catalogue:
    /// no network, and this route was actually downloaded.
    private var isReadingOffline: Bool {
        reachability.shouldUseStoredMap(hasBundle: offline.hasBundle(routeId))
    }

    /// The route as this screen should read it.
    ///
    /// With no network and a download in hand, that is the snapshot taken when
    /// the route was downloaded, not the catalogue. Today the two agree, because
    /// the catalogue ships inside the app — but the catalogue is meant to come
    /// from a server, and a route you downloaded has to keep working after the
    /// server's copy moves on. Reading the snapshot is what makes the stored
    /// bytes mean something instead of being weight the size figure counts.
    private var resolvedRoute: Route? {
        if isReadingOffline, let stored = offline.storedRoute(routeId) { return stored }
        return store.route(id: routeId)
    }

    private var isOffline: Bool { saved.isOffline(routeId) }

    /// One call site for both halves of "downloaded", so the flag and the
    /// stored bundle cannot drift apart.
    private func setOffline(_ on: Bool, route: Route) {
        if on {
            offline.download(route: route)
        } else {
            offline.remove(routeId: route.id)
        }
        saved.toggleOffline(route.id)
    }

    private func content(route: Route, language: AppLanguage) -> some View {
        VStack(spacing: 0) {
            map(route: route, language: language)

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.s3) {
                    Text(route.name(language))
                        .font(Typography.title)
                        .foregroundStyle(Theme.label)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("route-detail-name")

                    FigureStrip(figures: [
                        (String(route.km), "unit.km".localized(language), false),
                        (String(route.minutes), "unit.min".localized(language), false),
                    ])

                    if !route.note(language).isEmpty {
                        Text(route.note(language))
                            .font(Typography.body)
                            .foregroundStyle(Theme.labelSecondary)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    credit(route: route, language: language)

                    secondaryActions(route: route, language: language)

                    Button("route.startWalking".localized(language)) {
                        trackingRoute = route
                    }
                    .buttonStyle(.primaryClassical)
                    .accessibilityIdentifier("start-walking-button")
                }
                .padding(.horizontal, Theme.Space.screen)
                .padding(.top, Theme.Space.s4)
                // Clears the floating tab bar, which draws over the scroll view
                // rather than inset from it. Without this the last two buttons
                // can never be scrolled out from under it.
                .padding(.bottom, Theme.Space.s8 + 72)
            }
        }
        .screenBackground()
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Map

    private func map(route: Route, language: AppLanguage) -> some View {
        Group {
            if reachability.shouldUseStoredMap(hasBundle: offline.hasBundle(route.id)),
               let stored = offline.storedMapImage(route.id),
               let image = UIImage(data: stored) {
                // No network, but this route was downloaded: draw the picture
                // we stored. Nothing here touches MapKit or the catalogue.
                //
                // `fillingBox` rather than a plain frame: the stored drawing is
                // proportionally wider than this slot, and a frame would let it
                // set the width of the screen. See `fillingBox` for why.
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .accessibilityIdentifier("offline-map-image")
                    .accessibilityLabel("saved.offlineMap".localized(language))
                    .fillingBox(height: 290)
            } else {
                RouteMapView(mode: .detail, routes: [route], bottomInset: 20, topInset: 70)
                    .accessibilityIdentifier("live-map")
            }
        }
            .frame(maxWidth: .infinity, minHeight: 290, maxHeight: 290)
            .clipped()
            .overlay(alignment: .topLeading) {
                circularButton(system: "chevron.left", tinted: false) { dismiss() }
                    .accessibilityIdentifier("route-back-button")
                    .accessibilityLabel("action.back".localized(language))
                    .padding(.leading, Theme.Space.s3)
                    .padding(.top, 60)
            }
            .overlay(alignment: .topTrailing) {
                let isSaved = saved.isSaved(route.id)
                circularButton(
                    system: isSaved ? "bookmark.fill" : "bookmark",
                    tinted: true,
                    ringed: isSaved
                ) {
                    saved.toggleSaved(route.id)
                }
                .accessibilityIdentifier("save-toggle")
                // The label states what tapping will do, not what the icon is —
                // that is what a VoiceOver user needs from a toggle.
                .accessibilityLabel(
                    (isSaved ? "route.save.remove" : "route.save.add").localized(language)
                )
                .padding(.trailing, Theme.Space.s3)
                .padding(.top, 60)
            }
    }

    /// The two controls that float over the map. Glass on iOS 26, a frosted
    /// material on iOS 18 — the fork lives in `Materials.swift`, not here.
    private func circularButton(
        system: String,
        tinted: Bool,
        ringed: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tinted ? Theme.accent : Theme.label)
                .frame(width: 44, height: 44)
                .floatingSurface(in: Circle(), interactive: true)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Credit and secondary actions

    private func credit(route: Route, language: AppLanguage) -> some View {
        HStack(spacing: Theme.Space.s2) {
            AvatarInitial(initial: route.authorInitial, size: 30)
            Text(route.authorName)
                .font(Typography.meta)
                .foregroundStyle(Theme.labelTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func secondaryActions(route: Route, language: AppLanguage) -> some View {
        HStack(spacing: Theme.Space.s2) {
            // The label carries the state: "Download" is an invitation,
            // "Offline ready" is a report. No separate checkmark needed.
            Button {
                setOffline(!isOffline, route: route)
            } label: {
                actionFace(
                    system: isOffline ? "checkmark.circle" : "arrow.down.circle",
                    title: (isOffline ? "route.offlineReady" : "route.download").localized(language)
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("offline-toggle")

            // The plan left this one "trivial with ShareLink" and unwired
            // through seven phases. A control that does nothing is the kind of
            // thing a polish pass exists to find, so it is wired here.
            ShareLink(item: shareText(route: route, language: language)) {
                actionFace(system: "square.and.arrow.up", title: "route.share".localized(language))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("share-button")
            .accessibilityLabel("route.share".localized(language))
        }
    }

    /// What gets shared: the route's name, its distance and its time. Sent in
    /// the language the walker is reading, because the person they are
    /// sending it to is probably reading the same one.
    ///
    /// No link, because there is nowhere to link to yet. Saying so by leaving
    /// it out is better than inventing a URL that will not resolve.
    private func shareText(route: Route, language: AppLanguage) -> String {
        "route.share.message".localized(
            language,
            route.name(language),
            figureText(route.km),
            String(route.minutes)
        )
    }

    private func figureText(_ value: Double) -> String { String(format: "%.1f", value) }

    /// A quiet filled control on the neutral well. The label carries the
    /// downloaded state.
    private func actionFace(system: String, title: String) -> some View {
        HStack(spacing: Theme.Space.s1 + 2) {
            Image(systemName: system)
                .font(.system(size: 15, weight: .medium))
            Text(title)
                .font(Typography.meta.weight(.medium))
        }
        .foregroundStyle(Theme.label)
        .frame(maxWidth: .infinity, minHeight: 46)
        .background(Theme.fill, in: Theme.shape(Theme.Radius.md))
    }
}

// MARK: - Flow layout

/// Wraps its children onto the next line when they run out of room.
///
/// The three route tags are free text in two languages, so their combined width
/// is not predictable — an `HStack` would either clip them or force them to
/// shrink. This is the smallest thing that lets them wrap honestly.
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
