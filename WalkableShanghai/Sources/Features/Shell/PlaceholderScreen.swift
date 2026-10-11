import SwiftUI

/// Stands in for a screen that is scaffolded but not yet built.
///
/// Says which phase of the plan fills it in, rather than showing a blank. It
/// also reports how many routes decoded out of the bundled catalogue, which is
/// the cheapest possible proof that the data layer reached the view layer.
struct PlaceholderScreen: View {

    @Environment(AppSettings.self) private var settings
    @Environment(RouteStore.self) private var store

    let titleKey: String
    let symbol: String
    let phase: Int

    var body: some View {
        let language = settings.language

        VStack(spacing: Theme.Space.s4) {
            Spacer()

            Image(systemName: symbol)
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Theme.accent)
                .frame(width: 68, height: 68)
                .background(Theme.accentSoft, in: Circle())

            VStack(spacing: Theme.Space.s2) {
                Text(titleKey.localized(language))
                    .font(Typography.heading)
                    .foregroundStyle(Theme.label)

                Text("placeholder.phase".localized(language, String(phase)))
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.labelTertiary)
            }

            Group {
                if store.loadFailure != nil {
                    Text("placeholder.dataError".localized(language))
                        .foregroundStyle(Theme.accent)
                } else {
                    Text("placeholder.routeCount".localized(language, String(store.routes.count)))
                        .foregroundStyle(Theme.labelTertiary)
                }
            }
            .font(Typography.meta)
            .multilineTextAlignment(.center)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Theme.Space.screen)
        .frame(maxWidth: .infinity)
        .screenBackground()
        .navigationTitle(titleKey.localized(language))
        .navigationBarTitleDisplayMode(.inline)
    }
}
