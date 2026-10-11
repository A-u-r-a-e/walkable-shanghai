import SwiftUI
import CoreLocation

/// Screen 8 — drawing a route by hand.
///
/// The map is the input, not a picture: every tap drops a point, the dotted
/// line follows, and the count and distance update as you go. Everything else
/// on the screen is there to name what you drew and put it away.
struct RouteBuilderScreen: View {

    @Environment(AppSettings.self) private var settings
    @Environment(RouteStore.self) private var store
    @Environment(WalkStore.self) private var walks
    @Environment(\.dismiss) private var dismiss

    @State private var points: [CLLocationCoordinate2D] = []
    @State private var name = ""
    @State private var chosenTags: Set<BuilderTag> = []

    var body: some View {
        let language = settings.language

        VStack(spacing: 0) {
            header(language: language)

            RouteMapView(
                mode: .build,
                routes: [],
                draftPoints: points,
                onAddPoint: { points.append($0) }
            )
            .frame(maxHeight: .infinity)
            .accessibilityIdentifier("builder-map")

            panel(language: language)
        }
        .screenBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Header

    private func header(language: AppLanguage) -> some View {
        HStack(spacing: Theme.Space.s3) {
            CircularIconButton(system: "chevron.left") { dismiss() }
                .accessibilityIdentifier("builder-back-button")
                .accessibilityLabel("action.back".localized(language))

            Text("builder.instruction".localized(language))
                .font(Typography.meta)
                .foregroundStyle(Theme.labelSecondary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Space.screen)
        .padding(.vertical, Theme.Space.s2)
        .background(Theme.bg)
    }

    // MARK: - Panel

    private func panel(language: AppLanguage) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s3) {

            HStack(alignment: .firstTextBaseline) {
                Text("builder.newRoute".localized(language))
                    .font(Typography.heading)
                    .foregroundStyle(Theme.label)
                Spacer()
                // The running tally: what you have drawn so far, in the two
                // units that matter while drawing it.
                Text("builder.tally".localized(language,
                              "builder.points".localized(language, count: points.count),
                              distanceText))
                    .font(Typography.meta)
                    .foregroundStyle(Theme.labelTertiary)
                    .accessibilityIdentifier("builder-tally")
            }

            TextField("builder.namePlaceholder".localized(language), text: $name)
                .font(Typography.body)
                .foregroundStyle(Theme.label)
                .padding(Theme.Space.s3)
                .background(Theme.fill, in: Theme.shape(Theme.Radius.sm))
                .accessibilityIdentifier("builder-name-field")

            FlowRow(spacing: Theme.Space.s2) {
                ForEach(BuilderTag.allCases) { tag in
                    Button {
                        if chosenTags.contains(tag) {
                            chosenTags.remove(tag)
                        } else {
                            chosenTags.insert(tag)
                        }
                    } label: {
                        // Chosen tags take the tinted fill rather than an
                        // outline: a filled chip is what "on" looks like in this
                        // system, and the outline is reserved for a route's own
                        // character tag on the detail screen.
                        TagChip(
                            text: tag.localizationKey.localized(language),
                            style: chosenTags.contains(tag) ? .accent : .neutral,
                            // The one tag whose meaning the theme can carry.
                            // Hidden from VoiceOver, so the chip still announces
                            // exactly the word it always did.
                            symbol: tag == .green ? "leaf" : nil
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("builder-tag-\(tag.rawValue)")
                    .accessibilityAddTraits(chosenTags.contains(tag) ? [.isSelected] : [])
                }
            }

            HStack(spacing: Theme.Space.s2) {
                Button("builder.undo".localized(language)) {
                    if !points.isEmpty { points.removeLast() }
                }
                .buttonStyle(.secondaryClassical)
                .disabled(points.isEmpty)
                .accessibilityIdentifier("builder-undo-button")

                Button("builder.save".localized(language)) { save() }
                    .buttonStyle(.primaryClassical)
                    // A route needs a line. Two points is the least that makes
                    // one, so the button stays off until there are two.
                    .disabled(points.count < 2)
                    .accessibilityIdentifier("builder-save-button")
            }
        }
        .padding(.horizontal, Theme.Space.screen)
        .padding(.top, Theme.Space.s4)
        .padding(.bottom, Theme.Space.s4)
        .background(Theme.bg)
        // The seam between the live map and the opaque panel under it — see the
        // same treatment on the tracking screen.
        .overlay(alignment: .top) { SeparatorRule() }
    }

    private var distanceText: String {
        String(format: "%.1f", RouteGeometry.totalMeters(points) / 1000)
    }

    // MARK: - Saving

    private func save() {
        guard points.count >= 2 else { return }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty
            ? "builder.untitled".localized(settings.language)
            : trimmed

        walks.saveDraftRoute(
            name: finalName,
            coordinates: points,
            tagKeys: chosenTags.map(\.rawValue).sorted()
        )
        // Fold it straight into the route list so it is on the map by the time
        // the builder closes.
        store.setDrawnRoutes(
            walks.draftRoutes,
            authorName: store.profile?.name ?? "",
            authorInitial: store.profile?.initial ?? ""
        )
        dismiss()
    }
}
