import SwiftUI
import Charts

/// Screen 11 — the walker, their figures, and the app's settings.
///
/// Every number here is computed. The source design hardcoded all four
/// statistics and all six bar heights; this reads them off the walks and drawn
/// routes actually stored on the phone, which is why a fresh install shows
/// zeroes and an empty chart instead of somebody else's achievements.
struct ProfileScreen: View {

    @Environment(AppSettings.self) private var settings
    @Environment(RouteStore.self) private var store
    @Environment(WalkStore.self) private var walks

    @State private var isShowingOnboarding = false
    @State private var isShowingDesignSystem = false
    @State private var isShowingBuilder = false

    var body: some View {
        @Bindable var settings = settings
        let language = settings.language

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                identity(language: language)
                statistics(language: language)
                walkRange(language: language)
                settingsSection(language: language, binding: $settings.language)
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.vertical, Theme.Space.s4)
            // Clears the floating tab bar, which draws over the scroll view.
            .padding(.bottom, Theme.Space.s8 + 72)
        }
        .screenBackground()
        .navigationTitle("tab.you".localized(language))
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isShowingOnboarding) {
            OnboardingView(
                onFindRoute: { isShowingOnboarding = false },
                onShareRoute: { isShowingOnboarding = false }
            )
        }
        .sheet(isPresented: $isShowingDesignSystem) {
            NavigationStack { DesignSystemGalleryView() }
        }
        .fullScreenCover(isPresented: $isShowingBuilder) {
            NavigationStack { RouteBuilderScreen() }
        }
    }

    // MARK: - Identity

    private func identity(language: AppLanguage) -> some View {
        Group {
            if let profile = store.profile {
                HStack(spacing: Theme.Space.s3) {
                    AvatarInitial(initial: profile.initial, size: 52, emphasised: true)
                    VStack(alignment: .leading, spacing: Theme.Space.s1) {
                        Text(profile.name)
                            .font(Typography.heading)
                            .foregroundStyle(Theme.label)
                        Text(profile.joinedMonth(language))
                            .font(Typography.meta)
                            .foregroundStyle(Theme.labelTertiary)
                    }
                    Spacer(minLength: 0)
                }
                // The avatar is decorative — the name beside it says who this
                // is — so the two read as one element rather than three.
                .accessibilityElement(children: .combine)
                .padding(.bottom, Theme.Space.s6)
            }
        }
    }

    // MARK: - The four figures

    /// Walks, distance, longest walk, routes drawn. All four come from stored
    /// records, so they move the moment a walk is finished or a route is saved.
    private func statistics(language: AppLanguage) -> some View {
        FigureGrid(figures: [
            .init(value: String(walks.walkCount),
                  label: "profile.walks".localized(language),
                  identifier: "profile-walk-count"),
            .init(value: figure(walks.totalKm),
                  label: "profile.totalKm".localized(language),
                  identifier: "profile-total-km"),
            .init(value: longestText,
                  label: "profile.longest".localized(language),
                  identifier: "profile-longest"),
            .init(value: String(walks.draftRoutes.count),
                  label: "profile.routesAdded".localized(language),
                  identifier: "profile-routes-added"),
        ])
        .padding(.bottom, Theme.Space.s6)
    }

    private var longestText: String {
        // An em dash rather than 0.0: no walk yet is a different fact from a
        // walk of no distance, and the chart says the same thing beside it.
        guard let best = walks.bestDistanceMeters, best > 0 else { return "\u{2014}" }
        return figure(best / 1000)
    }

    // MARK: - Walk range

    private func walkRange(language: AppLanguage) -> some View {
        let months = WalkRange.lastMonths(walks: walks.walks)
        let hasAnyWalk = months.contains { $0.longestKm > 0 }

        return VStack(alignment: .leading, spacing: Theme.Space.s2) {
            Text("profile.range.title".localized(language))
                .sectionLabel()

            Text("profile.range.note".localized(language))
                .font(Typography.meta)
                .foregroundStyle(Theme.labelTertiary)
                .fixedSize(horizontal: false, vertical: true)

            if hasAnyWalk {
                chart(months: months, language: language)
            } else {
                EmptyStateNote(
                    text: "profile.range.empty".localized(language),
                    identifier: "profile-range-empty"
                )
                .card(radius: Theme.Radius.lg)
            }
        }
        .padding(.bottom, Theme.Space.s6)
    }

    /// The chart, styled to the tokens rather than to Swift Charts' defaults.
    ///
    /// Each bar is a flat neutral fill, and its height says "further" without
    /// a second axis, which is the whole reason this screen has a chart rather
    /// than a list. The baseline is a separator under the plot, and the whole
    /// thing sits on a card — so the rule that used to run across the page is
    /// now inside a group, like every other separator in the app.
    private func chart(months: [MonthlyBest], language: AppLanguage) -> some View {
        let top = WalkRange.scaleTop(months)

        return VStack(spacing: 0) {
            Chart {
                ForEach(months) { month in
                    BarMark(
                        x: .value("month", monthLabel(month, language: language)),
                        y: .value("km", month.longestKm),
                        width: .ratio(0.5)
                    )
                    .foregroundStyle(Theme.labelSecondary)
                    // Swift Charts' own corner rounding. A `clipShape` around
                    // the mark compiles and draws, but it costs the chart its
                    // accessibility element — the identifier below then lands on
                    // nothing and three UI tests stop being able to find the
                    // chart at all.
                    .cornerRadius(Theme.Radius.xs, style: .continuous)
                }
            }
            .chartYScale(domain: 0...top)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(Typography.meta)
                                .foregroundStyle(Theme.labelTertiary)
                        }
                    }
                }
            }
            .chartPlotStyle { plot in
                plot.padding(.bottom, 1)
            }
            .frame(height: 132)
            .accessibilityIdentifier("profile-walk-range-chart")
            // Swift Charts announces marks one by one and drops the units. One
            // sentence per month, in the walker's language, is what a screen
            // reader can actually use here.
            .accessibilityChildren {
                VStack {
                    ForEach(months) { month in
                        Text("profile.chart.month".localized(
                            language,
                            monthLabel(month, language: language),
                            figure(month.longestKm)
                        ))
                    }
                }
            }

            SeparatorRule()
        }
        .padding(.horizontal, Theme.Space.s3)
        .padding(.vertical, Theme.Space.s3)
        .card(radius: Theme.Radius.lg)
    }

    /// "Mar" in English, "3月" in Chinese — from the chosen language's locale,
    /// not the phone's, so switching the app switches the axis with it.
    private func monthLabel(_ month: MonthlyBest, language: AppLanguage) -> String {
        month.start.formatted(
            Date.FormatStyle(locale: language.locale).month(.abbreviated)
        )
    }

    // MARK: - Settings

    private func settingsSection(
        language: AppLanguage,
        binding: Binding<AppLanguage>
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("settings.title".localized(language))
                .sectionLabel()
                .padding(.bottom, Theme.Space.s2)

            // One grouped card. The rules that used to run across the page
            // have moved inside it.
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Theme.Space.s3) {
                    Text("settings.language".localized(language))
                        .font(Typography.body)
                        .foregroundStyle(Theme.label)
                    Spacer(minLength: Theme.Space.s2)
                    SegmentedRing(
                        options: AppLanguage.allCases.map { ($0, $0.endonym) },
                        selection: binding,
                        identifiers: ["language-english", "language-chinese"]
                    )
                    .frame(width: 168)
                }
                .padding(.vertical, Theme.Space.s3)

                SeparatorRule()

                // A real count rather than a static label.
                settingsRow(
                    title: "settings.routesYouAdded".localized(language),
                    detail: String(walks.draftRoutes.count),
                    identifier: "profile-draw-route-row"
                ) { isShowingBuilder = true }

                SeparatorRule()

                settingsRow(
                    title: "settings.about".localized(language),
                    detail: nil,
                    identifier: "profile-about-row"
                ) { isShowingOnboarding = true }

                SeparatorRule()

                settingsRow(
                    title: "settings.designSystem".localized(language),
                    detail: nil,
                    identifier: "profile-design-system-row"
                ) { isShowingDesignSystem = true }
            }
            .padding(.horizontal, Theme.Space.s3)
            .card(radius: Theme.Radius.lg)
        }
    }

    private func settingsRow(
        title: String,
        detail: String?,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Space.s2) {
                Text(title)
                    .font(Typography.body)
                    .foregroundStyle(Theme.label)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: Theme.Space.s2)
                if let detail {
                    Text(detail)
                        .font(Typography.meta)
                        .foregroundStyle(Theme.labelTertiary)
                        .tabularFigures()
                }
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.labelTertiary)
            }
            .padding(.vertical, Theme.Space.s3)
            // The whole row is the target, and never shorter than a fingertip.
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        // The count is the row's value, not part of its name — a screen reader
        // then reads "Offline downloads, 2" rather than running the two
        // together.
        .accessibilityLabel(title)
        .accessibilityValue(detail ?? "")
    }

    private func figure(_ value: Double) -> String { String(format: "%.1f", value) }
}
