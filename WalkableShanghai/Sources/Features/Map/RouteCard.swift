import SwiftUI

/// One route, shown in the map sheet in place of the list.
///
/// Expanded, it carries everything in the order the walker reads it: title
/// (with bookmark, share and close at the right), distance and time, the
/// description, tags, the creator with how many people are on the route now,
/// and Begin route. Collapsed, only the title row and the figures remain.
struct RouteCard: View {

    @Environment(AppSettings.self) private var settings

    let route: Route
    let isExpanded: Bool
    let isSaved: Bool
    let walkingNow: Int
    let onToggleSaved: () -> Void
    let onClose: () -> Void
    let onBegin: () -> Void

    var body: some View {
        let language = settings.language

        VStack(alignment: .leading, spacing: Theme.Space.s3) {
            HStack(alignment: .top, spacing: Theme.Space.s2) {
                Text(route.name(language))
                    .font(Typography.title)
                    .foregroundStyle(Theme.label)
                    .lineLimit(isExpanded ? nil : 1)
                    .fixedSize(horizontal: false, vertical: isExpanded)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("route-card-title")

                iconButton(isSaved ? "bookmark.fill" : "bookmark", tint: isSaved ? Theme.accent : Theme.label, action: onToggleSaved)
                    .accessibilityIdentifier("save-toggle")
                    .accessibilityLabel((isSaved ? "route.save.remove" : "route.save.add").localized(language))

                ShareLink(item: shareText(language)) {
                    iconFace("square.and.arrow.up", tint: Theme.label)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("share-button")
                .accessibilityLabel("route.share".localized(language))

                iconButton("xmark", tint: Theme.labelSecondary, action: onClose)
                    .accessibilityIdentifier("route-card-close")
                    .accessibilityLabel("action.close".localized(language))
            }

            Text(route.figures(language))
                .font(Typography.secondary)
                .foregroundStyle(Theme.labelSecondary)
                .tabularFigures()
                .accessibilityIdentifier("route-card-figures")

            if isExpanded {
                if !route.note(language).isEmpty {
                    Text(route.note(language))
                        .font(Typography.body)
                        .foregroundStyle(Theme.labelSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("route-card-description")
                }

                if !route.tags.isEmpty {
                    FlowRow(spacing: Theme.Space.s2) {
                        ForEach(route.tags, id: \.self) { tag in
                            TagChip(text: tag.localizationKey.localized(language), style: tag == .featured ? .featured : .neutral)
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("route-card-tags")
                }

                HStack(spacing: Theme.Space.s2) {
                    AvatarInitial(initial: route.authorInitial, size: 28)
                    Text(route.authorName)
                        .font(Typography.meta)
                        .foregroundStyle(Theme.label)
                    Spacer(minLength: Theme.Space.s2)
                    Text(L10n.string("routes.walkingNow", language, count: walkingNow))
                        .font(Typography.meta)
                        .foregroundStyle(Theme.labelSecondary)
                        .accessibilityIdentifier("route-card-walking-now")
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("route-card-creator")

                Button("route.begin".localized(language), action: onBegin)
                    .buttonStyle(.primaryClassical)
                    .accessibilityIdentifier("start-walking-button")
            }
        }
        .padding(.horizontal, Theme.Space.s4)
        .padding(.bottom, Theme.Space.s4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("route-card")
    }

    private func shareText(_ language: AppLanguage) -> String {
        "route.share.message".localized(language, route.name(language), String(format: "%.1f", route.km), String(route.minutes))
    }

    private func iconButton(_ system: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            iconFace(system, tint: tint)
        }
        .buttonStyle(.plain)
    }

    /// Small, quiet controls; 44pt targets around a 15pt glyph.
    private func iconFace(_ system: String, tint: Color) -> some View {
        Image(systemName: system)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 32, height: 32)
            .background(Theme.fill, in: Circle())
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }
}
