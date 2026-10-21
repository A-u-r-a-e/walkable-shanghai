import SwiftUI

/// The app's design tokens. See `../../DESIGN.md` for the reasoning and
/// `Palette.swift` for the numbers behind every colour.
///
/// The system is neutral: grey grounds and near-neutral ink in both
/// appearances, with green kept for the few things it marks — primary buttons,
/// the route line, selected states, the filled bookmark and the Featured tag.
/// Every colour is adaptive and every text pairing clears WCAG AA, which
/// `PaletteContrastTests` checks against the same numbers.
enum Theme {

    // MARK: - Colour roles

    static let bg = adaptive(Palette.bg)
    static let surface = adaptive(Palette.surface)
    static let surfaceRaised = adaptive(Palette.surfaceRaised)
    static let fill = adaptive(Palette.fill)
    static let separator = adaptive(Palette.separator)

    static let label = adaptive(Palette.label)
    static let labelSecondary = adaptive(Palette.labelSecondary)
    static let labelTertiary = adaptive(Palette.labelTertiary)

    /// The route line, selected states, the filled bookmark and links.
    static let accent = adaptive(Palette.accent)
    /// Primary buttons only.
    static let primaryFill = adaptive(Palette.primaryFill)
    static let onPrimaryFill = adaptive(Palette.onPrimaryFill)
    /// The Featured tag only.
    static let featuredFill = adaptive(Palette.featuredFill)
    static let onFeaturedFill = adaptive(Palette.onFeaturedFill)

    static let grabHandle = adaptiveAlpha(light: (0x2B2B29, 0.24), dark: (0xFFFFFF, 0.30))

    // MARK: - The map
    //
    // Every colour and every alpha the map draws, in one place. `RouteMapView`
    // is UIKit and cannot read a SwiftUI environment for its trait, so it asks
    // the map view and picks a value from here; what it must never do is invent
    // one, or the palette would live in two files.

    enum Map {
        /// The wide, faint line under every route that lifts it off the map. It
        /// is ink in light and light in dark — a dark casing on a dark basemap
        /// is invisible.
        static let casingLight = Color(hex: 0x000000, opacity: 0.14)
        static let casingDark = Color(hex: 0xFFFFFF, opacity: 0.20)
        static let casingWidth: CGFloat = 7

        /// The route itself, and the two halves of a route being walked.
        static let lineAlpha: Double = 0.95
        static let lineWidth: CGFloat = 2.6
        static let walkedWidth: CGFloat = 4.5
        static let aheadAlpha: Double = 0.85
        static let aheadWidth: CGFloat = 2.4
        static let aheadDash: [NSNumber] = [2, 6]
        static let draftAlpha: Double = 0.85
        static let draftWidth: CGFloat = 2.2
        static let draftDash: [NSNumber] = [1, 5]

        /// The walker's pulsing halo, and the shadow under a pin.
        static let haloAlpha: Double = 0.18
        static let pinShadow = Color(hex: 0x000000)
        static let pinShadowOpacity: Float = 0.20
        static let pinRingWidth: CGFloat = 1.5
    }

    // MARK: - Space
    //
    // Unchanged. The 4.6 base is idiosyncratic, but it is used on every screen
    // and rescaling it would be a re-layout, which this redesign is not.

    enum Space {
        static let s1: CGFloat = 4.6
        static let s2: CGFloat = 9.2
        static let s3: CGFloat = 13.8
        static let s4: CGFloat = 18.4
        static let s6: CGFloat = 27.6
        static let s8: CGFloat = 36.8
        static let screen: CGFloat = 22
    }

    // MARK: - Radii
    //
    // Generous, and always used with `.continuous`. Prefer `Theme.shape(_:)`
    // over building a `RoundedRectangle` by hand so the corner style cannot be
    // forgotten.

    enum Radius {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 22
        static let xl: CGFloat = 28
    }

    /// A continuous rounded rectangle at one of the scale's radii.
    static func shape(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    // MARK: - Elevation
    //
    // Light mode only, by design. Dark mode separates surfaces by lightness, and
    // a shadow on a black ground is invisible — it costs a render pass to draw
    // nothing.

    enum Shadow {
        static let smColor = adaptiveAlpha(light: (0x000000, 0.10), dark: (0x000000, 0))
        static let smRadius: CGFloat = 6
        static let smY: CGFloat = 2

        static let mdColor = adaptiveAlpha(light: (0x000000, 0.14), dark: (0x000000, 0))
        static let mdRadius: CGFloat = 18
        static let mdY: CGFloat = 6

        static let lgColor = adaptiveAlpha(light: (0x000000, 0.18), dark: (0x000000, 0))
        static let lgRadius: CGFloat = 34
        static let lgY: CGFloat = 14
    }

    /// One device pixel. Kept for the few places a true hairline still reads
    /// better than a 1pt rule.
    static var hairline: CGFloat { 1.0 / UIScreen.main.scale }

    // MARK: - Adaptive plumbing

    /// A colour that resolves per appearance.
    ///
    /// Built on `UIColor`'s trait-aware initialiser rather than an asset
    /// catalogue entry: the values then live beside the design doc that
    /// justifies them, and the contrast test can read them straight out of
    /// `Palette`.
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light, alpha: 1)
        })
    }

    static func adaptive(_ pair: Palette.Pair) -> Color {
        adaptive(light: pair.light, dark: pair.dark)
    }

    static func adaptiveAlpha(
        light: (UInt32, Double),
        dark: (UInt32, Double)
    ) -> Color {
        Color(UIColor { traits in
            let (hex, alpha) = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(rgb: hex, alpha: alpha)
        })
    }
}

// MARK: - Hex helpers

extension UIColor {
    convenience init(rgb: UInt32, alpha: Double) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: CGFloat(alpha)
        )
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(UIColor(rgb: hex, alpha: opacity))
    }
}

// MARK: - Shadow conveniences

extension View {
    func elevationSm() -> some View {
        shadow(color: Theme.Shadow.smColor, radius: Theme.Shadow.smRadius, y: Theme.Shadow.smY)
    }

    func elevationMd() -> some View {
        shadow(color: Theme.Shadow.mdColor, radius: Theme.Shadow.mdRadius, y: Theme.Shadow.mdY)
    }
}
