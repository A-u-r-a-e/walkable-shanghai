import SwiftUI

/// Every shared component on one screen, in the current language.
///
/// This is a working surface, not a shipping screen — the plan asks that Phase
/// 1's components be "built and exercised", and this is where they get
/// exercised. It is also the fastest way to check a token change, and the
/// fastest way to see what Chinese does to a layout.
struct DesignSystemGalleryView: View {

    @Environment(AppSettings.self) private var settings
    @Environment(RouteStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var filter: Filter = .featured

    enum Filter: Hashable { case featured, nearby, saved }

    var body: some View {
        let language = settings.language

        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.s8) {

                section("gallery.tokens".localized(language)) {
                    // The neutral grounds, then the few roles that carry green.
                    VStack(spacing: Theme.Space.s2) {
                        HStack(spacing: Theme.Space.s2) {
                            swatch(Theme.bg, "bg")
                            swatch(Theme.surface, "surface")
                            swatch(Theme.fill, "fill")
                            swatch(Theme.separator, "separator")
                        }
                        HStack(spacing: Theme.Space.s2) {
                            swatch(Theme.label, "label")
                            swatch(Theme.accent, "accent")
                            swatch(Theme.primaryFill, "primaryFill")
                            swatch(Theme.featuredFill, "featuredFill")
                        }
                    }
                }

                section("gallery.figures".localized(language)) {
                    FigureStrip(figures: [
                        ("3.4", "unit.km".localized(language)),
                        ("52", "unit.min".localized(language)),
                    ])
                }

                section("gallery.selection".localized(language)) {
                    SegmentedRing(
                        options: [
                            (Filter.featured, "Featured"),
                            (Filter.nearby, "Nearby"),
                            (Filter.saved, "Saved"),
                        ],
                        selection: $filter
                    )
                }

                section("gallery.tags".localized(language)) {
                    VStack(alignment: .leading, spacing: Theme.Space.s3) {
                        HStack(spacing: Theme.Space.s2) {
                            TagChip(text: "Plane trees", style: .neutral)
                            TagChip(text: "Featured", style: .featured)
                            TagChip(text: "Xuhui", style: .neutral)
                            TagChip(text: "Green", style: .neutral, symbol: "leaf")
                        }
                        HStack(spacing: Theme.Space.s3) {
                            AvatarInitial(initial: "沁", size: 34)
                            AvatarInitial(initial: "邱", size: 34, emphasised: true)
                            AvatarInitial(initial: "M", size: 34)
                        }
                    }
                }

                section("gallery.rows".localized(language)) {
                    VStack(spacing: 0) {
                        let rows = Array(store.routes.prefix(3))
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, route in
                            RouteRow(
                                routeId: route.id,
                                name: route.name(language),
                                detail: detail(for: route, language: language),
                                status: status(for: route, language: language)
                            )
                            if index < rows.count - 1 {
                                SeparatorRule()
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Space.s3)
                    .card(radius: Theme.Radius.lg)
                }

                section("gallery.buttons".localized(language)) {
                    VStack(spacing: Theme.Space.s2) {
                        Button("onboarding.primary".localized(language)) {}
                            .buttonStyle(.primaryClassical)
                        Button("onboarding.secondary".localized(language)) {}
                            .buttonStyle(.secondaryClassical)
                    }
                }
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.vertical, Theme.Space.s4)
        }
        .screenBackground()
        .navigationTitle("settings.designSystem".localized(language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    private func detail(for route: Route, language: AppLanguage) -> String {
        let km = "unit.km".localized(language)
        let min = "unit.min".localized(language)
        return "\(String(format: "%.1f", route.km)) \(km) · \(route.minutes) \(min)"
    }

    private func status(for route: Route, language: AppLanguage) -> String {
        let date = route.updatedAt.formatted(.dateTime.day().month(.abbreviated).locale(language.locale))
        return "\("routes.updated".localized(language, date)) · \(L10n.string("routes.walkingNow", language, count: 0))"
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s3) {
            Text(title).sectionLabel()
            content()
        }
    }

    private func swatch(_ color: Color, _ name: String) -> some View {
        VStack(spacing: Theme.Space.s1) {
            Theme.shape(Theme.Radius.sm)
                .fill(color)
                .frame(height: 44)
                .overlay {
                    Theme.shape(Theme.Radius.sm).strokeBorder(Theme.separator, lineWidth: 1)
                }
            Text(name)
                .font(.system(size: 9))
                .foregroundStyle(Theme.labelTertiary)
        }
    }
}
