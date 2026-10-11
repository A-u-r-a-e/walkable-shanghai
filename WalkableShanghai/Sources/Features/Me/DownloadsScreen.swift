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
            Button("action.cancel".localized(language), role: .cancel) {}
        } message: {
            Text("me.downloads.confirm".localized(language))
        }
    }

    private func row(_ bundle: OfflineBundle, language: AppLanguage) -> some View {
        let route = store.route(id: bundle.routeId) ?? offline.storedRoute(bundle.routeId)
        return HStack(spacing: Theme.Space.s3) {
            if let image = UIImage(data: bundle.mapImage) {
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
