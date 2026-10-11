import SwiftUI

/// Type for the app.
///
/// The Classical sheet pairs Cormorant Garamond with Lora. Both are retired by
/// decision: the app uses the **system font only**. That means SF Pro for Latin
/// text and automatic PingFang SC substitution for Chinese, inside one stack —
/// so the two languages sit together as one family, and there is no bundled
/// font, no missing-glyph fallback, and Dynamic Type works for free.
///
/// Everything here is built on the built-in text styles rather than fixed point
/// sizes, so the whole app scales with the reader's text-size setting.
enum Typography {

    /// The screen-opening statement. One or two lines, never a paragraph.
    static let display = Font.system(.largeTitle, design: .default, weight: .medium)

    /// Screen titles.
    static let title = Font.system(.title, design: .default, weight: .medium)

    /// Section and card headings.
    static let heading = Font.system(.title3, design: .default, weight: .semibold)

    /// A route name in a list row.
    static let rowTitle = Font.system(.body, design: .default, weight: .semibold)

    /// Running prose.
    static let body = Font.system(.body)

    /// Supporting text under a heading or row.
    static let secondary = Font.system(.subheadline)

    /// Metadata: distances, areas, timestamps.
    static let meta = Font.system(.footnote)

    /// The small gold uppercase label the Classical system uses to open a
    /// section. Apply with `.sectionLabel()` — it needs tracking and casing too,
    /// which a Font alone cannot carry.
    static let label = Font.system(.caption, design: .default, weight: .semibold)

    /// A large figure — kilometres, minutes, dead ends. Always tabular, so
    /// columns of numbers line up and a ticking clock does not jitter.
    static func figure(_ style: Font.TextStyle = .title) -> Font {
        Font.system(style, design: .default, weight: .medium).monospacedDigit()
    }
}

// MARK: - Text style modifiers

extension View {

    /// A section header, in iOS's own idiom.
    ///
    /// Was a gold uppercase tracked label — a print device. Uppercasing and
    /// tracking are dropped: iOS sets section headers in sentence case at a
    /// small weight, and that is what a reader expects above a group. The
    /// accessibility string is unchanged either way, so tests that match on
    /// these labels keep working.
    func sectionLabel(color: Color = Theme.labelSecondary) -> some View {
        self.font(Typography.label)
            .foregroundStyle(color)
    }

    /// Body copy with language-appropriate leading.
    ///
    /// Chinese needs looser leading than English to stay readable at the same
    /// size — the source design used 1.95 against 1.7. These are the native
    /// equivalents, expressed as the extra points SwiftUI adds between lines.
    func prose(_ language: AppLanguage) -> some View {
        self.font(Typography.body)
            .lineSpacing(language == .chinese ? 8 : 5)
    }

    /// Tabular figures, for anything numeric.
    func tabularFigures() -> some View {
        self.monospacedDigit()
    }
}
