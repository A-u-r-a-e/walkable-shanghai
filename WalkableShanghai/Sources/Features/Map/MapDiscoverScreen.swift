import SwiftUI

/// The map tab, and the app's home.
///
/// A full-bleed map with a pin per listed route, a search field and the
/// map-style button across the top, a record button, and a two-height sheet.
/// The sheet shows either the route list, ordered the way the walker chose in
/// its Routes dropdown, or one route's card. While a card is open the map
/// draws only that route, framed, without pins.
///
/// The sheet is built by hand rather than with `.presentationDetents`, for two
/// reasons a system sheet cannot satisfy: the record button has to track the
/// sheet's height as it moves, and the map has to stay live and framed against
/// the strip of it you can actually see.
struct MapDiscoverScreen: View {

    @Environment(AppSettings.self) private var settings
    @Environment(RouteStore.self) private var store
    @Environment(SavedRoutesStore.self) private var saved

    private enum Detent {
        case peek, full
    }

    @State private var query = RouteListQuery()
    @State private var origin: Coordinate?
    @State private var isShowingBuilder = false
    @State private var detent: Detent = .peek
    @State private var dragTranslation: CGFloat = 0
    @State private var selectedRouteId: String?
    /// The expanded card's height. Kept while the card is collapsed, so a drag
    /// up from the collapsed card has a height to grow towards.
    @State private var cardHeight: CGFloat = 0
    /// The route whose expanded card has reported its height. The map waits
    /// for it before drawing that route alone, so the frame clears the whole
    /// card rather than a stale or collapsed height.
    @State private var measuredRouteId: String?
    @State private var trackingRoute: Route?

    var body: some View {
        let language = settings.language

        GeometryReader { geometry in
            let available = geometry.size.height
            let sheetHeight = resolvedSheetHeight(in: available)
            let framedRoute = selectedRouteId == measuredRouteId ? selectedRouteId.flatMap(store.route(id:)) : nil

            ZStack(alignment: .top) {
                RouteMapView(
                    mode: framedRoute == nil ? .discover : .detail,
                    routes: framedRoute.map { [$0] } ?? listedRoutes,
                    style: settings.mapStyle,
                    bottomInset: sheetHeight,
                    topInset: 76,
                    onSelectRoute: { showCard($0) }
                )
                .ignoresSafeArea(edges: .bottom)

                // Pinned to its natural height. Without the spacer the ZStack
                // hands these controls the full screen height, and their opaque
                // paper backgrounds cover the map completely.
                VStack(spacing: 0) {
                    controls(language: language)
                    Spacer(minLength: 0)
                }

                recordButton(language: language, sheetHeight: sheetHeight)

                sheet(height: sheetHeight, available: available)
            }
        }
        .screenBackground()
        .onAppear { origin = NearbyOrigin.current() }
        .fullScreenCover(isPresented: $isShowingBuilder) {
            NavigationStack { RouteBuilderScreen() }
        }
        .navigationDestination(item: $trackingRoute) { route in
            TrackingScreen(route: route) {
                // A finished walk returns to the route list, whether it began
                // on a card or from REC, not to the card of the walk just done.
                trackingRoute = nil
                selectedRouteId = nil
                detent = .peek
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Listing

    private var sections: [RouteListSection] {
        RouteList.sections(
            routes: store.routes,
            query: query,
            mineIds: store.mineRouteIds,
            savedIds: saved.savedRouteIds,
            origin: origin,
            activity: store.activity
        )
    }

    /// What the map draws: every route listed, once, in list order.
    private var listedRoutes: [Route] {
        var seen = Set<String>()
        return sections.flatMap(\.routes).filter { seen.insert($0.id).inserted }
    }

    // MARK: - Top controls

    private func controls(language: AppLanguage) -> some View {
        HStack(spacing: Theme.Space.s2) {
            HStack(spacing: Theme.Space.s2) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.labelSecondary)
                TextField("map.search".localized(language), text: $query.searchText)
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.label)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("map-search-field")
            }
            .padding(.horizontal, Theme.Space.s4)
            .frame(minHeight: 46)
            // Floats over the map, so it takes glass. See Materials.swift.
            .floatingSurface(in: Capsule())

            Menu {
                Picker(selection: Bindable(settings).mapStyle) {
                    ForEach(MapStyleOption.allCases, id: \.self) { style in
                        Label(style.localizationKey.localized(language), systemImage: style.systemImage).tag(style)
                    }
                } label: {
                    EmptyView()
                }
            } label: {
                Image(systemName: settings.mapStyle.systemImage)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.label)
                    .frame(width: 46, height: 46)
                    .floatingSurface(in: Circle(), interactive: true)
            }
            .accessibilityIdentifier("map-style-button")
            .accessibilityLabel("map.style.button".localized(language))
        }
        .padding(.horizontal, Theme.Space.s3)
    }

    // MARK: - Record button

    private func recordButton(language: AppLanguage, sheetHeight: CGFloat) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    // With no route chosen, REC records against the featured
                    // walk — the one the app is already recommending.
                    trackingRoute = store.featuredRoute() ?? store.routes.first
                } label: {
                    VStack(spacing: 1) {
                        Image(systemName: "record.circle")
                            .font(.system(size: 18, weight: .regular))
                        Text("map.record".localized(language))
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(0.6)
                    }
                    .foregroundStyle(Theme.label)
                    .frame(width: 58, height: 58)
                    .floatingSurface(in: Circle(), interactive: true)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("record-button")
                .accessibilityLabel("map.record.action".localized(language))
            }
            .padding(.trailing, Theme.Space.s4)
            // Sits just above the sheet and rides with it.
            .padding(.bottom, sheetHeight + Theme.Space.s3)
        }
    }

    // MARK: - Sheet

    private func sheet(height: CGFloat, available: CGFloat) -> some View {
        VStack {
            Spacer(minLength: 0)

            VStack(spacing: 0) {
                grabHandle(available: available)

                if let route = selectedRouteId.flatMap(store.route(id:)) {
                    // At the largest text sizes the card outgrows the sheet's
                    // cap, and then it scrolls. Measured inside the scroll view,
                    // so the height reported is the card's own, not the sheet's.
                    ScrollView {
                        RouteCard(
                            route: route,
                            isExpanded: detent == .full,
                            isSaved: saved.isSaved(route.id),
                            walkingNow: store.activity.walkingNow(routeId: route.id),
                            onToggleSaved: { saved.toggleSaved(route) },
                            onClose: {
                                withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                                    selectedRouteId = nil
                                    detent = .peek
                                }
                            },
                            onBegin: { trackingRoute = route }
                        )
                        // The tab bar draws over the sheet, as it does over the
                        // list; the same clearance keeps Begin route out from under it.
                        .padding(.bottom, Self.tabBarClearance)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                            guard detent == .full else { return }
                            cardHeight = height
                            measuredRouteId = route.id
                        }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                } else {
                    RouteListSheet(
                        query: $query,
                        sections: sections,
                        onSelect: { showCard($0) },
                        onNewRoute: { isShowingBuilder = true }
                    )
                }
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
            // A panel carrying reading material, so it takes the heavier of the
            // two floating treatments. The bottom corners run off screen; only
            // the top two are rounded.
            .floatingPanel(in: SheetShape(radius: Theme.Radius.xl))
            .shadow(color: Theme.Shadow.mdColor, radius: 18, y: -4)
        }
        // Runs under the home indicator but not under the keyboard, so search
        // results stay visible while the walker types.
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private func grabHandle(available: CGFloat) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Theme.grabHandle)
                .frame(width: 38, height: 5)
                .padding(.top, Theme.Space.s2)
                .padding(.bottom, Theme.Space.s2)
        }
        .frame(maxWidth: .infinity)
        // A wide, short target: the whole strip drags, not just the 38pt bar.
        .contentShape(Rectangle())
        // Made an element in its own right. A bare identifier on a decorative
        // Capsule is not exposed, so the control would be invisible to
        // VoiceOver and to the tests.
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("sheet-handle")
        .accessibilityLabel("map.sheet.handle".localized(settings.language))
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                detent = (detent == .peek) ? .full : .peek
            }
        }
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    dragTranslation = value.translation.height
                }
                .onEnded { value in
                    // Decide on where the drag was heading, not just where it
                    // stopped — a fast flick should complete.
                    let projected = height(of: detent, in: available) - value.predictedEndTranslation.height
                    let midpoint = (height(of: .peek, in: available) + height(of: .full, in: available)) / 2
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                        detent = projected > midpoint ? .full : .peek
                        dragTranslation = 0
                    }
                }
        )
    }

    /// Space the floating tab bar takes at the foot of the sheet. Matches the
    /// list's bottom padding.
    private static let tabBarClearance = Theme.Space.s8 + 56

    /// The list keeps its two heights. The card's collapsed height fits the
    /// title row and figures above the tab bar; expanded, it fits the card's
    /// measured content, capped at the list's full height.
    private func height(of detent: Detent, in available: CGFloat) -> CGFloat {
        let fullCap = min(560, available * 0.78)
        let collapsedCard = 136 + Self.tabBarClearance
        switch (detent, selectedRouteId != nil) {
        case (.peek, false): return min(300, available * 0.42)
        case (.full, false): return min(540, available * 0.74)
        case (.peek, true): return collapsedCard
        case (.full, true): return min(fullCap, max(collapsedCard, cardHeight + 28))
        }
    }

    private func resolvedSheetHeight(in available: CGFloat) -> CGFloat {
        let base = height(of: detent, in: available)
        let minimum = height(of: .peek, in: available)
        let maximum = height(of: .full, in: available)
        // Dragging up is a negative translation, which should grow the sheet.
        return min(maximum, max(minimum, base - dragTranslation))
    }

    /// Opens a route's card from its row or its pin, with the sheet raised so
    /// the whole card shows.
    private func showCard(_ routeId: String) {
        // Forget the last measurement, so the map waits for this card's.
        measuredRouteId = nil
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            selectedRouteId = routeId
            detent = .full
        }
    }
}


// MARK: - Sheet silhouette

/// A rectangle rounded on its top two corners only.
///
/// The sheet's bottom edge runs off the screen, so rounding it would show a
/// sliver of map under the corner as the sheet moves. `UnevenRoundedRectangle`
/// with a continuous style gives the same corner curve the rest of the system
/// uses.
struct SheetShape: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        UnevenRoundedRectangle(
            topLeadingRadius: radius,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: radius,
            style: .continuous
        ).path(in: rect)
    }
}
