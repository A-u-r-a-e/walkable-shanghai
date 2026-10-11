import SwiftUI

/// Screen 2 — map and discovery. The app's home.
///
/// Composed natively from the Classical tokens rather than ported from the
/// mockup's layout. The functional brief is the mockup's: a full-bleed map with
/// a numbered pin per route, a filter across the top, a record button, and a
/// two-height sheet listing the routes currently in view.
///
/// The sheet is built by hand rather than with `.presentationDetents`, for two
/// reasons a system sheet cannot satisfy: the record button has to track the
/// sheet's height as it moves, and the map has to stay live and framed against
/// the strip of it you can actually see.
struct MapDiscoverScreen: View {

    @Environment(AppSettings.self) private var settings
    @Environment(RouteStore.self) private var store
    @Environment(SavedRoutesStore.self) private var saved

    enum Filter: Hashable { case featured, nearby, saved }

    private enum Detent {
        case peek, full
        /// Heights from the source design, clamped so they still work on a
        /// small phone and at large text sizes.
        func height(in available: CGFloat) -> CGFloat {
            switch self {
            case .peek: return min(300, available * 0.42)
            case .full: return min(540, available * 0.74)
            }
        }
    }

    @State private var filter: Filter = .featured
    @State private var detent: Detent = .peek
    @State private var dragTranslation: CGFloat = 0
    @State private var selectedRouteId: String?
    @State private var trackingRoute: Route?

    var body: some View {
        let language = settings.language

        GeometryReader { geometry in
            let available = geometry.size.height
            let sheetHeight = resolvedSheetHeight(in: available)

            ZStack(alignment: .top) {
                RouteMapView(
                    mode: .discover,
                    routes: listedRoutes,
                    bottomInset: Detent.peek.height(in: available),
                    topInset: 132,
                    onSelectRoute: { selectedRouteId = $0 }
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

                sheet(language: language, height: sheetHeight, available: available)
            }
        }
        .screenBackground()
        .navigationDestination(item: $selectedRouteId) { routeId in
            RouteDetailScreen(routeId: routeId)
        }
        .navigationDestination(item: $trackingRoute) { route in
            TrackingScreen(route: route) { trackingRoute = nil }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Filtering

    /// What the map and the sheet both draw. One source, so they can never
    /// disagree about what is in view.
    private var listedRoutes: [Route] {
        switch filter {
        case .featured, .nearby:
            // Nearby returns everything for now — real distance sorting needs
            // real location, which is Phase 4. Marked excluded in PLAN.md.
            return store.routes
        case .saved:
            return store.routes.filter { saved.isSaved($0.id) }
        }
    }

    // MARK: - Top controls

    private func controls(language: AppLanguage) -> some View {
        VStack(spacing: Theme.Space.s2) {
            // Presented but inert, matching the mockup. Search behaviour is
            // excluded from this phase, and a field that looks live but does
            // nothing is worse than one that plainly waits its turn.
            HStack(spacing: Theme.Space.s2) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Text("map.search".localized(language))
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.labelSecondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Space.s4)
            .frame(minHeight: 46)
            // Floats over the map, so it takes glass. See Materials.swift.
            .floatingSurface(in: Capsule())
            .accessibilityIdentifier("map-search-field")

            SegmentedRing(
                options: [
                    (Filter.featured, "map.filter.featured".localized(language)),
                    (Filter.nearby, "map.filter.nearby".localized(language)),
                    (Filter.saved, "map.filter.saved".localized(language)),
                ],
                selection: $filter,
                identifiers: ["map-filter-featured", "map-filter-nearby", "map-filter-saved"]
            )
            .floatingSurface(in: Capsule())
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
                    .foregroundStyle(Theme.accent)
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

    private func sheet(language: AppLanguage, height: CGFloat, available: CGFloat) -> some View {
        VStack {
            Spacer(minLength: 0)

            VStack(spacing: 0) {
                grabHandle(available: available)

                HStack(alignment: .firstTextBaseline) {
                    Text("map.routesInView".localized(language))
                        .font(Typography.heading)
                        .foregroundStyle(Theme.label)
                    Spacer()
                    Text("\(listedRoutes.count)")
                        .font(Typography.figure(.subheadline))
                        .foregroundStyle(Theme.accent)
                        .accessibilityIdentifier("routes-in-view-count")
                }
                .padding(.horizontal, Theme.Space.s4)
                .padding(.bottom, Theme.Space.s2)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        if listedRoutes.isEmpty {
                            EmptyStateNote(
                                text: "map.empty".localized(language),
                                identifier: "map-empty"
                            )
                            SeparatorRule()
                        }
                        ForEach(listedRoutes) { route in
                            Button {
                                selectedRouteId = route.id
                            } label: {
                                RouteRow(
                                    number: route.number,
                                    name: route.name(language),
                                    detail: detailLine(for: route, language: language)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("route-row-\(route.id)")
                            SeparatorRule()
                        }
                    }
                    .padding(.horizontal, Theme.Space.s4)
                    // Clears the tab bar, which draws over the sheet rather
                    // than inset from it. Without this the last route in the
                    // list can sit under the bar with no way to scroll it out.
                    .padding(.bottom, Theme.Space.s8 + 56)
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
        .ignoresSafeArea(edges: .bottom)
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
                    let projected = detent.height(in: available) - value.predictedEndTranslation.height
                    let midpoint = (Detent.peek.height(in: available) + Detent.full.height(in: available)) / 2
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                        detent = projected > midpoint ? .full : .peek
                        dragTranslation = 0
                    }
                }
        )
    }

    private func resolvedSheetHeight(in available: CGFloat) -> CGFloat {
        let base = detent.height(in: available)
        let minimum = Detent.peek.height(in: available)
        let maximum = Detent.full.height(in: available)
        // Dragging up is a negative translation, which should grow the sheet.
        return min(maximum, max(minimum, base - dragTranslation))
    }

    private func detailLine(for route: Route, language: AppLanguage) -> String {
        let km = "unit.km".localized(language)
        let minutes = "unit.min".localized(language)
        return "\(route.km) \(km) · \(route.minutes) \(minutes) · \(route.area(language))"
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
