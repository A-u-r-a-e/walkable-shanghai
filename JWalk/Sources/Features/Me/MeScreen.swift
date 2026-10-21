import SwiftUI

/// The Me tab: an inset grouped list, in the manner of iOS Settings.
///
/// The profile is one row that opens its own page; everything else is a
/// setting. Rows that need an account (sign in, sync, delete account) wait for
/// a backend. There is no appearance setting: the app follows the phone.
struct MeScreen: View {

    @Environment(AppSettings.self) private var settings
    @Environment(RouteStore.self) private var store
    @Environment(WalkStore.self) private var walks
    @Environment(OfflineStore.self) private var offline
    @Environment(\.openURL) private var openURL

    @State private var isShowingOnboarding = false
    @State private var isShowingDesignSystem = false

    var body: some View {
        @Bindable var settings = settings
        let language = settings.language

        List {
            Section {
                NavigationLink {
                    ProfileScreen()
                } label: {
                    profileRow(language: language)
                }
                .accessibilityIdentifier("me-profile-row")
            }

            Section("me.section.preferences".localized(language)) {
                Picker("settings.language".localized(language), selection: $settings.language) {
                    ForEach(AppLanguage.allCases, id: \.self) { option in
                        Text(option.endonym).tag(option)
                    }
                }
                .pickerStyle(.menu)
                // A menu picker draws its value in the tint, and green belongs
                // to selected states and primary actions, not to a setting's value.
                .tint(Theme.labelSecondary)
                .accessibilityIdentifier("me-language-picker")
            }

            Section("me.section.storage".localized(language)) {
                NavigationLink {
                    DownloadsScreen()
                } label: {
                    LabeledContent("me.downloads".localized(language), value: OfflineStore.sizeText(bytes: offline.totalBytes, language: language))
                }
                .accessibilityIdentifier("me-downloads-row")
            }

            Section("me.section.privacy".localized(language)) {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                } label: {
                    LabeledContent("me.location".localized(language)) {
                        Image(systemName: "arrow.up.forward.app")
                            .foregroundStyle(Theme.labelTertiary)
                    }
                }
                .foregroundStyle(Theme.label)
                .accessibilityIdentifier("me-location-row")
            }

            Section("me.section.about".localized(language)) {
                Button { isShowingOnboarding = true } label: {
                    chevronRow("me.howItWorks".localized(language))
                }
                .foregroundStyle(Theme.label)
                .accessibilityIdentifier("me-how-it-works-row")
                LabeledContent("me.version".localized(language), value: Self.version)
                    .accessibilityIdentifier("me-version-row")
                #if DEBUG
                Button { isShowingDesignSystem = true } label: {
                    chevronRow("settings.designSystem".localized(language))
                }
                .foregroundStyle(Theme.label)
                .accessibilityIdentifier("me-design-system-row")
                #endif
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("tab.me".localized(language))
        .fullScreenCover(isPresented: $isShowingOnboarding) {
            OnboardingView(
                onFindRoute: { isShowingOnboarding = false },
                onShareRoute: { isShowingOnboarding = false }
            )
        }
        .sheet(isPresented: $isShowingDesignSystem) {
            NavigationStack { DesignSystemGalleryView() }
        }
        // A shared route switches to the map; nothing here may cover it.
        .onChange(of: store.receivedCount) {
            isShowingOnboarding = false
            isShowingDesignSystem = false
        }
    }

    private func profileRow(language: AppLanguage) -> some View {
        HStack(spacing: Theme.Space.s3) {
            AvatarInitial(initial: store.profile?.initial ?? "", size: 48, emphasised: true)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.profile?.name ?? "")
                    .font(Typography.rowTitle)
                    .foregroundStyle(Theme.label)
                Text("\(L10n.string("me.walks", language, count: walks.walkCount)) · \(String(format: "%.1f", walks.totalKm)) \("unit.km".localized(language))")
                    .font(Typography.meta)
                    .foregroundStyle(Theme.labelSecondary)
            }
        }
        .padding(.vertical, Theme.Space.s1)
    }

    /// A row that presents rather than pushes, drawn like a NavigationLink row
    /// so every row that opens something reads the same. The chevron is
    /// decoration: VoiceOver already announces the row as a button.
    private func chevronRow(_ title: String) -> some View {
        HStack {
            Text(title)
            Spacer(minLength: Theme.Space.s2)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.labelTertiary)
                .accessibilityHidden(true)
        }
    }

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? "–"
        return "\(short) (\(build))"
    }
}
