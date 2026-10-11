import SwiftUI

/// Screen 10 — what the walker has kept.
///
/// Two sections over one list, fed by the SwiftData flags from Phase 3. Offline
/// comes first because it is the one that survives losing signal, which is the
/// only reason either section exists.
struct SavedScreen: View {

    @Environment(AppSettings.self) private var settings
    @Environment(RouteStore.self) private var store
    @Environment(SavedRoutesStore.self) private var saved
    @Environment(OfflineStore.self) private var offline

    @State private var openRouteId: String?

    var body: some View {
        let language = settings.language

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header(language: language)

                // Each section is one card with its rows inside it, rather than
                // rows ruled across the page. Order, contents and identifiers
                // are exactly what they were.
                if !offlineRoutes.isEmpty {
                    sectionLabel("saved.offline".localized(language))
                    VStack(spacing: 0) {
                        ForEach(Array(offlineRoutes.enumerated()), id: \.element.id) { index, route in
                            offlineRow(route, language: language)
                            if index < offlineRoutes.count - 1 {
                                SeparatorRule(inset: 16 + Theme.Space.s3)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Space.s3)
                    .card(radius: Theme.Radius.lg)
                }

                if !savedRoutes.isEmpty {
                    sectionLabel("saved.savedRoutes".localized(language))
                        .padding(.top, Theme.Space.s4)
                    VStack(spacing: 0) {
                        ForEach(Array(savedRoutes.enumerated()), id: \.element.id) { index, route in
                            savedRow(route, language: language)
                            if index < savedRoutes.count - 1 {
                                SeparatorRule(inset: 20 + Theme.Space.s3)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Space.s3)
                    .card(radius: Theme.Radius.lg)
                }

                if offlineRoutes.isEmpty && savedRoutes.isEmpty {
                    EmptyStateNote(
                        text: "saved.empty".localized(language),
                        identifier: "saved-empty"
                    )
                }

                footer(language: language)
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, Theme.Space.s8 + 72)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $openRouteId) { RouteDetailScreen(routeId: $0) }
    }

    // MARK: - Contents

    /// Both lists come from the same store the route-detail toggles write to,
    /// so the counts here cannot drift from what those toggles were set to.
    private var offlineRoutes: [Route] {
        store.routes.filter { saved.isOffline($0.id) }
    }

    private var savedRoutes: [Route] {
        store.routes.filter { saved.isSaved($0.id) }
    }

    private func header(language: AppLanguage) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("tab.saved".localized(language))
                .font(Typography.title)
                .foregroundStyle(Theme.label)
            Spacer()
            Text("saved.count".localized(language, count: savedRoutes.count))
                .font(Typography.meta)
                .foregroundStyle(Theme.labelTertiary)
                .accessibilityIdentifier("saved-count")
        }
        .padding(.top, Theme.Space.s4)
        .padding(.bottom, Theme.Space.s3)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .sectionLabel()
            .padding(.bottom, Theme.Space.s2)
    }

    private func offlineRow(_ route: Route, language: AppLanguage) -> some View {
        Button { openRouteId = route.id } label: {
            HStack(spacing: Theme.Space.s3) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(route.name(language))
                        .font(Typography.rowTitle)
                        .foregroundStyle(Theme.label)
                        .multilineTextAlignment(.leading)
                    // The size is the real byte count of what is stored, not a
                    // number from the catalogue.
                    Text("\(figure(route.km)) \("unit.km".localized(language)) · \(route.minutes) \("unit.min".localized(language)) · \(offline.sizeText(route.id, language: language))")
                        .font(Typography.meta)
                        .foregroundStyle(Theme.labelTertiary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.labelTertiary)
            }
            .padding(.vertical, Theme.Space.s3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("offline-row-\(route.id)")
    }

    private func savedRow(_ route: Route, language: AppLanguage) -> some View {
        Button { openRouteId = route.id } label: {
            HStack(spacing: Theme.Space.s3) {
                Text("\(route.number)")
                    .font(Typography.figure(.subheadline))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 20, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(route.name(language))
                        .font(Typography.rowTitle)
                        .foregroundStyle(Theme.label)
                        .multilineTextAlignment(.leading)
                    Text("\(figure(route.km)) \("unit.km".localized(language)) · \(route.minutes) \("unit.min".localized(language)) · \(route.area(language))")
                        .font(Typography.meta)
                        .foregroundStyle(Theme.labelTertiary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.labelTertiary)
            }
            .padding(.vertical, Theme.Space.s3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("saved-row-\(route.id)")
    }

    /// Says what offline actually keeps.
    ///
    /// The mockup promised "Saved routes sync when you are back on data". There
    /// is no backend, so that sentence would be a promise the app cannot keep —
    /// and this footer is exactly where a walker decides whether to trust the
    /// download. It describes what is really stored instead, including what is
    /// missing.
    private func footer(language: AppLanguage) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s2) {
            Text("saved.footer".localized(language))
                .font(Typography.meta)
                .foregroundStyle(Theme.labelTertiary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("saved-footer")

            if offline.totalBytes > 0 {
                Text("saved.totalStored".localized(
                    language,
                    OfflineStore.sizeText(bytes: offline.totalBytes, language: language)
                ))
                .font(Typography.meta)
                .foregroundStyle(Theme.labelTertiary)
                .accessibilityIdentifier("saved-total-stored")
            }
        }
        .padding(.top, Theme.Space.s6)
    }

    private func figure(_ value: Double) -> String { String(format: "%.1f", value) }
}
