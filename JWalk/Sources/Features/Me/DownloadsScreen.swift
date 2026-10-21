import SwiftUI

/// Every saved route kept on the phone, with what each occupies.
///
/// Saved and downloaded are one state, so removing all downloads also clears
/// the bookmarks — the confirmation says so.
struct DownloadsScreen: View {

    @Environment(AppSettings.self) private var settings
    @Environment(RouteStore.self) private var store
    @Environment(OfflineStore.self) private var offline
    @Environment(SavedRoutesStore.self) private var saved

    @State private var isConfirmingRemoval = false

    var body: some View {
        let language = settings.language
        let bundles = offline.bundles.sorted { $0.downloadedAt > $1.downloadedAt }

        List {
            if bundles.isEmpty {
                EmptyStateNote(text: "me.downloads.empty".localized(language), identifier: "downloads-empty")
                    .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(bundles, id: \.routeId) { bundle in
                        row(bundle, language: language)
                    }
                } footer: {
                    Text("me.downloads.total".localized(language, OfflineStore.sizeText(bytes: offline.totalBytes, language: language)))
                        .accessibilityIdentifier("downloads-total")
                }

                Section {
                    Button("me.downloads.removeAll".localized(language), role: .destructive) {
                        isConfirmingRemoval = true
                    }
                    .accessibilityIdentifier("remove-all-downloads")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("me.downloads".localized(language))
        .confirmationDialog(
            "me.downloads.removeAll".localized(language),
            isPresented: $isConfirmingRemoval,
            titleVisibility: .visible
        ) {
            Button("me.downloads.removeAll".localized(language), role: .destructive) {
                saved.removeAllDownloads()
            }
            .accessibilityIdentifier("remove-all-downloads-confirm")
            Button("action.cancel".localized(language), role: .cancel) {}
                .accessibilityIdentifier("remove-all-downloads-cancel")
        } message: {
            Text("me.downloads.confirm".localized(language))
        }
    }

    private func row(_ bundle: OfflineBundle, language: AppLanguage) -> some View {
        let route = store.route(id: bundle.routeId) ?? offline.storedRoute(bundle.routeId)
        return HStack(spacing: Theme.Space.s3) {
            // Drawn from the route each time so it follows light and dark. The
            // stored picture is fixed to light, so it is only the fallback.
            if let route {
                RouteThumbnail(route: route)
                    .frame(width: 64, height: 44)
                    .clipShape(Theme.shape(Theme.Radius.xs))
                    .accessibilityHidden(true)
            } else if let image = UIImage(data: bundle.mapImage) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 44)
                    .clipShape(Theme.shape(Theme.Radius.xs))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(route?.name(language) ?? bundle.routeId)
                    .font(Typography.rowTitle)
                    .foregroundStyle(Theme.label)
                Text(OfflineStore.sizeText(bytes: bundle.byteCount, language: language))
                    .font(Typography.meta)
                    .foregroundStyle(Theme.labelSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("download-row-\(bundle.routeId)")
    }
}

/// A downloaded route's line on the neutral well, at row size.
///
/// The same drawing as `RouteImageRenderer`, scaled down, but with the
/// adaptive palette: a Canvas resolves `Theme` colours against the current
/// appearance, which a stored PNG cannot.
private struct RouteThumbnail: View {

    let route: Route

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas { context, size in
            let bounds = CGRect(origin: .zero, size: size)
            context.fill(Path(bounds), with: .color(Theme.fill))

            let points = RouteImageRenderer.project(
                route.points.map(\.clLocationCoordinate),
                into: bounds.insetBy(dx: size.width * 0.12, dy: size.height * 0.14)
            )
            guard points.count > 1 else { return }

            var line = Path()
            line.addLines(points)
            let casing = colorScheme == .dark ? Theme.Map.casingDark : Theme.Map.casingLight
            context.stroke(line, with: .color(casing),
                           style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            context.stroke(line, with: .color(Theme.accent),
                           style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))

            // Start filled, end hollow, as on the stored picture.
            for (point, filled) in [(points[0], true), (points[points.count - 1], false)] {
                let dot = Path(ellipseIn: CGRect(x: point.x - 2.5, y: point.y - 2.5, width: 5, height: 5))
                context.fill(dot, with: .color(filled ? Theme.accent : Theme.surface))
                context.stroke(dot, with: .color(Theme.accent), lineWidth: 1)
            }
        }
    }
}
