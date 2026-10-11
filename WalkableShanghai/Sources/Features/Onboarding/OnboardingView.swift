import SwiftUI

/// The first thing anyone sees: what the app is for, and the two ways in.
///
/// Designed for the phone from the Classical tokens rather than ported from the
/// HTML mockup. The differences are deliberate:
///
///  - The mockup set its three explanations as a justified label/definition
///    table, which is a print convention. Here they are an iOS feature list —
///    gold symbol, title, supporting line — which is what an iPhone reader
///    expects and what scales when the text size grows.
///  - The content scrolls and the two buttons are pinned below it, so the way
///    forward is always reachable at accessibility text sizes. The mockup's
///    fixed full-height column could not do that.
///  - The language switch is on this screen, not buried in settings. For a
///    bilingual audience the first useful choice is which language to read in,
///    and it is the honest place to put it when the app opens in whatever the
///    phone guessed.
struct OnboardingView: View {

    @Environment(AppSettings.self) private var settings

    /// Called with the destination the reader chose.
    let onFindRoute: () -> Void
    let onShareRoute: () -> Void

    var body: some View {
        @Bindable var settings = settings
        let language = settings.language

        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    HStack {
                        Spacer(minLength: 0)
                        SegmentedRing(
                            options: AppLanguage.allCases.map { ($0, $0.endonym) },
                            selection: $settings.language
                        )
                        .frame(width: 168)
                    }
                    .padding(.bottom, Theme.Space.s8)

                    Text("onboarding.eyebrow".localized(language))
                        .sectionLabel()

                    Text("onboarding.headline".localized(language))
                        .font(Typography.display)
                        .foregroundStyle(Theme.label)
                        .padding(.top, Theme.Space.s4)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("onboarding.body".localized(language))
                        .prose(language)
                        .foregroundStyle(Theme.labelSecondary)
                        .padding(.top, Theme.Space.s3)
                        .fixedSize(horizontal: false, vertical: true)

                    // One card rather than four rules across the page. The
                    // separators move inside it and inset to the text, which is
                    // how iOS groups rows.
                    VStack(spacing: 0) {
                        promise(
                            symbol: "ruler",
                            title: "onboarding.length.title".localized(language),
                            detail: "onboarding.length.detail".localized(language)
                        )
                        separator
                        promise(
                            symbol: "person",
                            title: "onboarding.walker.title".localized(language),
                            detail: "onboarding.walker.detail".localized(language)
                        )
                    }
                    .padding(.horizontal, Theme.Space.s3)
                    .card(radius: Theme.Radius.lg)
                    .padding(.top, Theme.Space.s8)
                }
                .padding(.horizontal, Theme.Space.screen)
                .padding(.top, Theme.Space.s4)
                .padding(.bottom, Theme.Space.s6)
            }

            VStack(spacing: Theme.Space.s2) {
                Button("onboarding.primary".localized(language), action: onFindRoute)
                    .buttonStyle(.primaryClassical)
                    .accessibilityIdentifier("onboarding-primary")
                Button("onboarding.secondary".localized(language), action: onShareRoute)
                    .buttonStyle(.secondaryClassical)
                    .accessibilityIdentifier("onboarding-secondary")
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.top, Theme.Space.s3)
            .padding(.bottom, Theme.Space.s2)
            .background(Theme.bg)
        }
        .screenBackground()
    }

    /// One of the things every route promises. Symbol tile, label title,
    /// muted explanation.
    private func promise(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Space.s3) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.label)
                .frame(width: 34, height: 34)
                // A neutral well, so the tile reads against the white card.
                .background(Theme.fill, in: Theme.shape(Theme.Radius.xs))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.rowTitle)
                    .foregroundStyle(Theme.label)
                Text(detail)
                    .font(Typography.secondary)
                    .foregroundStyle(Theme.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 1)
            Spacer(minLength: 0)
        }
        .padding(.vertical, Theme.Space.s3)
        .accessibilityElement(children: .combine)
    }

    /// Inset to clear the symbol tile, the way a grouped iOS list separates
    /// rows that carry an icon.
    private var separator: some View {
        SeparatorRule(inset: 34 + Theme.Space.s3)
    }
}

#Preview("English") {
    OnboardingView(onFindRoute: {}, onShareRoute: {})
        .environment(AppSettings(defaults: .previewDefaults(language: .english)))
}

#Preview("中文") {
    OnboardingView(onFindRoute: {}, onShareRoute: {})
        .environment(AppSettings(defaults: .previewDefaults(language: .chinese)))
}

extension UserDefaults {
    /// A throwaway defaults store so previews and tests do not read or write the
    /// real one.
    static func previewDefaults(language: AppLanguage) -> UserDefaults {
        let suite = UserDefaults(suiteName: "preview-\(UUID().uuidString)")!
        suite.set(language.rawValue, forKey: "settings.language")
        return suite
    }
}
