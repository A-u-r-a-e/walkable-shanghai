import SwiftUI

/// Screen 4 — the monthly Featured route.
///
/// An editorial page, not a list item: a month, an argument for one walk, and a
/// way in. Which route it describes comes from the `isFeatured` flag on the
/// route itself, so this screen has no route hardcoded into it — the mockup's
/// version had Wukang Road written into the markup three times.
struct FeaturedScreen: View {

    @Environment(AppSettings.self) private var settings
    @Environment(RouteStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var openedRouteId: String?

    var body: some View {
        let language = settings.language

        Group {
            if let route = store.featuredRoute(), let edition = store.featuredEdition {
                content(route: route, edition: edition, language: language)
            } else {
                Text("featured.none".localized(language))
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.labelTertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .screenBackground()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $openedRouteId) { routeId in
            RouteDetailScreen(routeId: routeId)
        }
    }

    private func content(route: Route, edition: FeaturedEdition, language: AppLanguage) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.s3) {

                HStack(spacing: Theme.Space.s3) {
                    // On the page, not over a map, so it is an opaque fill disc
                    // rather than glass. See DESIGN.md §4.
                    CircularIconButton(system: "chevron.left", size: 38) { dismiss() }
                        .accessibilityIdentifier("featured-back-button")
                        .accessibilityLabel("action.back".localized(language))

                    // The one warm colour in the system, spent on the one
                    // thing it is reserved for: this month's chosen walk.
                    // DESIGN.md §2 — anywhere else it is noise.
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.sunlight)
                            .accessibilityHidden(true)
                        Text(edition.month(language))
                            .sectionLabel()
                    }
                }
                .padding(.bottom, Theme.Space.s1)

                Text("featured.title".localized(language))
                    .font(Typography.display)
                    .foregroundStyle(Theme.label)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("featured-title")

                photograph(language: language)

                Text(route.name(language))
                    .font(Typography.heading)
                    .foregroundStyle(Theme.label)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("featured-route-name")

                FigureStrip(figures: [
                    (String(route.km), "unit.km".localized(language), false),
                    (String(route.minutes), "unit.minutes".localized(language), false),
                    (String(route.breaks), "unit.deadEnds".localized(language), route.breaks == 0),
                ])

                Text(edition.editorial(language))
                    .font(Typography.body)
                    .foregroundStyle(Theme.labelSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: Theme.Space.s2) {
                    AvatarInitial(initial: edition.curatorInitial, size: 30, emphasised: true)
                    Text("featured.curator".localized(
                        language,
                        edition.curatorName,
                        String(edition.walkersThisMonth)
                    ))
                    .font(Typography.meta)
                    .foregroundStyle(Theme.labelTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .padding(.vertical, Theme.Space.s1)

                Button("featured.open".localized(language)) {
                    openedRouteId = route.id
                }
                .buttonStyle(.primaryClassical)
                .accessibilityIdentifier("open-featured-route")
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.top, Theme.Space.s6)
            .padding(.bottom, Theme.Space.s8)
        }
        .canopyWash()
    }

    /// The route photograph's slot, waiting for a photograph.
    ///
    /// The mockup had an empty image slot here too — there is no photography in
    /// this project yet. Rather than fake it with a stock image, the slot is
    /// drawn honestly and says what belongs in it. The print mount it used to
    /// wear — a thick surface border with a hairline outside it — is gone with
    /// the rest of the print devices; a media slot in this system is a rounded
    /// `fill` well, which is also the shape a real photograph will be clipped
    /// to when one arrives.
    private func photograph(language: AppLanguage) -> some View {
        Theme.shape(Theme.Radius.lg)
            .fill(Theme.fill)
            .frame(height: 206)
            .overlay {
                VStack(spacing: Theme.Space.s1) {
                    Image(systemName: "photo")
                        .font(.system(size: 20, weight: .light))
                    Text("featured.photograph".localized(language))
                        .font(Typography.meta)
                }
                .foregroundStyle(Theme.labelTertiary)
            }
            .accessibilityHidden(true)
    }
}
