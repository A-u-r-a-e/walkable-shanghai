import SwiftUI

/// The list half of the map sheet: the Routes heading and its dropdown,
/// Popular's period selector, then the sections `RouteList` decided on.
struct RouteListSheet: View {

    @Environment(AppSettings.self) private var settings
    @Environment(RouteStore.self) private var store

    @Binding var query: RouteListQuery
    let sections: [RouteListSection]
    let onSelect: (String) -> Void
    let onNewRoute: () -> Void

    var body: some View {
        let language = settings.language

        VStack(spacing: 0) {
            header(language: language)

            if query.option == .popular {
                SegmentedRing(
                    options: ActivityPeriod.allCases.map { ($0, $0.localizationKey.localized(language)) },
                    selection: $query.period,
                    identifiers: ActivityPeriod.allCases.map { "period-\($0.rawValue)" }
                )
                .padding(.horizontal, Theme.Space.s4)
                .padding(.bottom, Theme.Space.s2)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                        sectionView(section, language: language)
                    }
                }
                .padding(.horizontal, Theme.Space.s4)
                // Clears the tab bar, which draws over the sheet.
                .padding(.bottom, Theme.Space.s8 + 56)
            }
        }
    }

    private func header(language: AppLanguage) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s2) {
            Text("routes.title".localized(language))
                .font(Typography.heading)
                .foregroundStyle(Theme.label)

            Menu {
                Picker(selection: $query.option) {
                    ForEach(RouteListOption.allCases, id: \.self) { option in
                        Text(option.localizationKey.localized(language)).tag(option)
                    }
                } label: {
                    EmptyView()
                }
            } label: {
                HStack(spacing: Theme.Space.s1) {
                    Text(query.option.localizationKey.localized(language))
                        .font(Typography.secondary.weight(.semibold))
                        // iOS 18 offers a menu label less than its own width
                        // and cut "Nearby" to "Near…".
                        .fixedSize()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(Theme.label)
                .padding(.horizontal, Theme.Space.s3)
                .padding(.vertical, Theme.Space.s1 + 2)
                .background(Theme.fill, in: Capsule())
            }
            .accessibilityIdentifier("routes-option-menu")

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Space.s4)
        .padding(.bottom, Theme.Space.s2)
    }

    @ViewBuilder
    private func sectionView(_ section: RouteListSection, language: AppLanguage) -> some View {
        switch section.kind {
        case .all:
            EmptyView()
        case .mine:
            Text("routes.section.mine".localized(language))
                .sectionLabel()
                .padding(.top, Theme.Space.s3)
                .accessibilityIdentifier("routes-section-mine")
        case .saved:
            Text("routes.section.saved".localized(language))
                .sectionLabel()
                .padding(.top, Theme.Space.s4)
                .accessibilityIdentifier("routes-section-saved")
        }

        if section.offersNewRoute {
            Button("routes.newRoute".localized(language), action: onNewRoute)
                .buttonStyle(.primaryClassical)
                .padding(.vertical, Theme.Space.s2)
                .accessibilityIdentifier("new-route-button")
        }

        if section.routes.isEmpty {
            EmptyStateNote(text: emptyText(section.kind, language: language), identifier: "routes-empty-\(section.kind)")
        }

        ForEach(section.routes) { route in
            Button {
                onSelect(route.id)
            } label: {
                RouteRow(
                    routeId: route.id,
                    name: route.name(language),
                    detail: route.figures(language),
                    status: status(route, language: language)
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("route-row-\(route.id)")
            SeparatorRule()
        }
    }

    private func emptyText(_ kind: RouteListSection.Kind, language: AppLanguage) -> String {
        switch kind {
        case .all: return "routes.empty".localized(language)
        case .mine: return "routes.empty.mine".localized(language)
        case .saved: return "routes.empty.saved".localized(language)
        }
    }

    private func status(_ route: Route, language: AppLanguage) -> String {
        let date = route.updatedDay(language)
        let walking = L10n.string("routes.walkingNow", language, count: store.activity.walkingNow(routeId: route.id))
        return "\("routes.updated".localized(language, date)) · \(walking)"
    }
}
