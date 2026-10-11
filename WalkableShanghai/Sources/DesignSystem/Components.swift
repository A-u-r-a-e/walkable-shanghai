import SwiftUI

// MARK: - Separators

/// A rule between two rows *inside* a card.
///
/// The old system ruled the page itself; this one does not. A separator only
/// ever appears within a grouped surface, inset to the content it divides, the
/// way iOS separates rows in a grouped list. `Divider` is still avoided because
/// it draws a system-coloured 1pt line rather than the token.
struct SeparatorRule: View {
    var inset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(Theme.separator)
            .frame(height: Theme.hairline)
            .padding(.leading, inset)
            .accessibilityHidden(true)
    }
}

/// Vertical counterpart, for dividing figures inside one card.
struct SeparatorColumn: View {
    var body: some View {
        Rectangle()
            .fill(Theme.separator)
            .frame(width: Theme.hairline)
            .accessibilityHidden(true)
    }
}

// MARK: - Figures

/// One number and its label. The atom of the app's honesty: distance and
/// duration.
struct Figure: View {
    let value: String
    let label: String
    var textStyle: Font.TextStyle = .title
    /// Optional identifier for tests that need to read a figure back.
    var identifier: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s1) {
            Text(value)
                .font(Typography.figure(textStyle))
                .foregroundStyle(Theme.label)
            Text(label)
                .sectionLabel(color: Theme.labelTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        // The figure itself goes in the value, not the label: a combined
        // element's label reads "1 walks", so a test asserting the number had
        // to match prose. Value carries the number alone.
        .accessibilityValue(value)
        .accessibilityIdentifier(identifier ?? "")
    }
}

/// A row of figures on one card: the tracking screen's distance, pace and
/// distance remaining, and the design-system gallery's sample.
///
/// A card, not a ruled band. The figures sit on `surface` with separators
/// between the cells rather than hairlines drawn across the page.
struct FigureStrip: View {
    let figures: [(value: String, label: String)]
    /// Optional per-figure identifiers, in the same order as `figures`.
    var identifiers: [String] = []

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(figures.enumerated()), id: \.offset) { index, figure in
                Figure(
                    value: figure.value,
                    label: figure.label,
                    identifier: index < identifiers.count ? identifiers[index] : nil
                )
                if index < figures.count - 1 {
                    SeparatorColumn().padding(.vertical, 4)
                }
            }
        }
        .padding(.vertical, Theme.Space.s3)
        .padding(.horizontal, Theme.Space.s3)
        .card()
    }
}

/// Four figures in two rows, on one card.
///
/// The profile's statistics do not fit the strip: four figures across a phone
/// leaves each one too narrow to read, and the labels ("routes added", "km on
/// foot") are longer than a route's units. Two by two gives each figure half the
/// width, with separators inside the card rather than rules on the page.
struct FigureGrid: View {

    /// One cell. A struct rather than a tuple so the profile can name its
    /// figures for the tests while the walk summary leaves the identifier out.
    struct Item {
        let value: String
        let label: String
        var identifier: String?
    }

    let figures: [Item]
    /// The size of the numbers. Two across a phone can carry `.title2`; the
    /// walk summary sets `.title` because its four figures are the point of
    /// that screen.
    var textStyle: Font.TextStyle = .title2

    var body: some View {
        let rows = stride(from: 0, to: figures.count, by: 2).map { start in
            Array(figures[start..<min(start + 2, figures.count)])
        }

        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { column, figure in
                        Figure(
                            value: figure.value,
                            label: figure.label,
                            textStyle: textStyle,
                            identifier: figure.identifier
                        )
                        if column < row.count - 1 {
                            SeparatorColumn().padding(.vertical, 4)
                        }
                    }
                    // Keeps a half-filled last row aligned with the one above
                    // instead of stretching its single figure across the width.
                    if row.count == 1 {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, Theme.Space.s3)
                .padding(.horizontal, Theme.Space.s3)
                if index < rows.count - 1 {
                    SeparatorRule().padding(.horizontal, Theme.Space.s3)
                }
            }
        }
        .card()
    }
}

// MARK: - Empty states

/// What a list says when it has nothing in it.
///
/// One component rather than a sentence per screen, because an empty list is
/// the one state most likely to be left as a blank page — and a blank page
/// reads as a bug. Quiet and centred: it explains the absence, it does not
/// decorate it.
///
/// The single leaf above the sentence is the one concession, and it is the
/// theme's mark rather than an illustration — hidden from VoiceOver, which gets
/// the sentence and nothing else, so the copy and the announcement are exactly
/// what they were.
struct EmptyStateNote: View {
    let text: String
    var identifier: String?

    var body: some View {
        VStack(spacing: Theme.Space.s2) {
            Image(systemName: "leaf")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Theme.labelTertiary)
                .accessibilityHidden(true)
            Text(text)
                .font(Typography.secondary)
                .foregroundStyle(Theme.labelTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Theme.Space.s4)
        .padding(.vertical, Theme.Space.s8)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier ?? "")
    }
}

// MARK: - Segmented control

/// The app's one selection idiom: a capsule track with the selected segment
/// filled green.
///
/// Replaces the old gold inset ring. This is the standard iOS segmented shape,
/// tinted — which is the point of the redesign: a reader should recognise the
/// control before they read it. Used by Popular's period selector and the
/// language switch.
struct SegmentedRing<Value: Hashable>: View {
    let options: [(value: Value, title: String)]
    @Binding var selection: Value
    /// Optional stable identifiers for tests. Without them a segment can only
    /// be found by its visible title, which collides when the same word appears
    /// elsewhere on screen.
    var identifiers: [String] = []

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                let isSelected = option.value == selection

                Button {
                    selection = option.value
                } label: {
                    Text(option.title)
                        .font(Typography.secondary.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Theme.onPrimaryFill : Theme.labelSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Space.s2 + 1)
                        .background {
                            if isSelected {
                                Capsule().fill(Theme.primaryFill)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                .accessibilityIdentifier(index < identifiers.count ? identifiers[index] : "")
            }
        }
        // The segments have no intrinsic height of their own, so the row would
        // otherwise stretch to fill whatever it is placed in.
        .fixedSize(horizontal: false, vertical: true)
        .padding(3)
        // A neutral well; the selected segment carries the only colour.
        .background(Theme.fill, in: Capsule())
    }
}

// MARK: - Tags

/// A tag on a route, from the fixed `RouteTag` list. Featured is green; every
/// other tag is neutral.
struct TagChip: View {
    enum Style { case featured, neutral }

    let text: String
    var style: Style = .neutral

    var body: some View {
        Text(text)
            .font(Typography.meta)
            .padding(.horizontal, Theme.Space.s2 + 1)
            .padding(.vertical, Theme.Space.s1 + 1)
            .foregroundStyle(foreground)
            .background(background, in: Theme.shape(Theme.Radius.xs))
    }

    private var foreground: Color {
        switch style {
        case .featured: return Theme.onFeaturedFill
        case .neutral: return Theme.label
        }
    }

    private var background: Color {
        switch style {
        case .featured: return Theme.featuredFill
        case .neutral: return Theme.fill
        }
    }
}

// MARK: - Flow layout

/// Wraps its children onto the next line when they run out of room.
///
/// A route's tags come from the fixed `RouteTag` list, but their names run to
/// different lengths in English and Chinese and grow with the text size, so
/// their combined width is not predictable — an `HStack` would either clip
/// them or force them to shrink. This is the smallest thing that lets them
/// wrap honestly.
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Avatar

/// A walker, shown as the single character the design uses in place of a photo.
/// A well disc for everyone, with a hairline ring and full-strength ink for
/// the signed-in walker.
struct AvatarInitial: View {
    let initial: String
    var size: CGFloat = 32
    var emphasised: Bool = false

    var body: some View {
        Text(initial)
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(emphasised ? Theme.label : Theme.labelSecondary)
            .frame(width: size, height: size)
            .background(Theme.fill, in: Circle())
            .overlay {
                if emphasised { Circle().strokeBorder(Theme.separator, lineWidth: 1) }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Buttons

/// A filled green button. The clearest possible "this is the action".
///
/// The biggest departure from the old system, which forbade filled buttons
/// outright. Apple's language does not, and a tinted filled button is what an
/// iPhone reader expects the primary action to look like. `onPrimaryFill`
/// clears AA on `primaryFill` in light *and* dark; `PaletteContrastTests`
/// checks it.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        StyledButton(configuration: configuration)
    }

    /// `isEnabled` reaches a view, not the style, so the drawing lives here.
    /// Disabled drops the green: a green button that does nothing reads as
    /// broken.
    private struct StyledButton: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(Typography.rowTitle)
                .foregroundStyle(isEnabled ? Theme.onPrimaryFill : Theme.labelTertiary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .background(isEnabled ? Theme.primaryFill : Theme.fill, in: Theme.shape(Theme.Radius.md))
                .opacity(configuration.isPressed ? 0.82 : 1)
                .contentShape(Rectangle())
        }
    }
}

/// A quiet button on the neutral well. No border — Apple's secondary buttons
/// separate by fill, not by stroke.
///
/// Neutral rather than a pale green: green is kept for the primary action, so
/// the second action of a pair reads as the lesser one.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        StyledButton(configuration: configuration)
    }

    /// Reads `isEnabled` for the same reason as `PrimaryButtonStyle.StyledButton`.
    private struct StyledButton: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(Typography.rowTitle)
                .foregroundStyle(isEnabled ? Theme.label : Theme.labelTertiary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .background(Theme.fill, in: Theme.shape(Theme.Radius.md))
                .opacity(configuration.isPressed ? 0.75 : 1)
                .contentShape(Rectangle())
        }
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primaryClassical: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondaryClassical: SecondaryButtonStyle { SecondaryButtonStyle() }
}

// MARK: - Circular icon control on a page

/// A back or dismiss button that sits *on* an opaque page rather than floating
/// over a map.
///
/// It is therefore opaque too: a neutral well disc, no stroke. The stroked
/// outline it replaces was the print system's — Apple's own circular bar buttons
/// separate by fill. Anything floating over live content calls
/// `.floatingSurface` instead; the two are deliberately different, and
/// DESIGN.md §6 says which is which.
struct CircularIconButton: View {
    let system: String
    var size: CGFloat = 36
    var glyphSize: CGFloat = 15
    var tint: Color = Theme.label
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: glyphSize, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(Theme.fill, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Route row

/// One route in a list: name, figures, and when it last changed and who is on it.
struct RouteRow: View {
    let routeId: String
    let name: String
    let detail: String
    let status: String

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Space.s3) {
            VStack(alignment: .leading, spacing: Theme.Space.s1) {
                Text(name)
                    .font(Typography.rowTitle)
                    .foregroundStyle(Theme.label)
                    .multilineTextAlignment(.leading)
                Text(detail)
                    .font(Typography.meta)
                    .foregroundStyle(Theme.labelSecondary)
                    .tabularFigures()
                Text(status)
                    .font(Typography.meta)
                    .foregroundStyle(Theme.labelTertiary)
                    .accessibilityIdentifier("route-row-status-\(routeId)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.labelTertiary)
        }
        .padding(.vertical, Theme.Space.s3)
        .contentShape(Rectangle())
    }
}

// MARK: - Pictures that fill a box

extension View {

    /// Draws this view to fill a full-width box of the given height, without
    /// letting it decide how wide the box is.
    ///
    /// This exists because of a real bug. A picture with `.scaledToFill()`
    /// reports the *scaled* size, which is wider than the box whenever the
    /// picture is proportionally wider than it — a 900×560 route drawing in a
    /// 393×290 slot measures 466 points across. `.frame(maxWidth: .infinity)`
    /// does not rein that in: clamping a width to infinity clamps nothing, so
    /// the frame reports the child's 466 and the oversized width travels up the
    /// layout, centring the whole column of text 36 points off screen.
    ///
    /// Painting the picture as an overlay on an empty box fixes the layout size
    /// to the box. The overflow is then drawn and clipped rather than measured,
    /// which is what "fill" was supposed to mean in the first place.
    /// `nonisolated` because one caller is the label closure of a
    /// `PhotosPicker`, which SwiftUI does not run on the main actor. Composing
    /// views touches no state, so there is nothing here that needs the actor.
    nonisolated func fillingBox(height: CGFloat) -> some View {
        Color.clear
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .overlay { self }
            .clipped()
            .contentShape(Rectangle())
    }
}
