import SwiftUI

/// The app's design tokens. See `../../DESIGN.md` for the reasoning and
/// `../../../research/nature-design-research.md` for the evidence behind the
/// hues.
///
/// The theme is **under the canopy**: walking Shanghai's plane-tree streets with
/// the light coming through the leaves. Five rules follow from that, and the
/// first three come out of what real outdoors apps actually ship.
///
///  1. **The green is yellow-leaning foliage, not mint.** The ramp sits near
///     hue 100°. Every dedicated outdoors brand lands in 78–120° — Komoot 78°,
///     iNaturalist 80°, Pantone's "Greenery" 84°, AllTrails 105° — while the
///     teal side (150°+) belongs to focus and health products. Our old ramp sat
///     at 150° and read corporate mint; this one reads leaf.
///  2. **The ground carries the tint; the ink does not.** Grounds are warm paper
///     with a clear yellow-green cast in light, and a green-tinted near-black in
///     dark (AllTrails ships `#0E110E`; Material says never pure black). Ink
///     stays near-neutral — nobody sets paragraphs in mid-saturation green.
///  3. **Green presence comes from real estate, not from dyeing the page.**
///     Soft-green cards, sections, washes and filled controls are what make this
///     feel green; the page itself is tinted, not saturated.
///  4. **Layered leaf greens do the composition.** Mist at the back, fresh in
///     the middle, canopy at the front — the wash, the chart bars, the progress
///     fill and the route lines all move through those three rather than
///     repeating one green at different opacities.
///  5. **Every colour is adaptive**, and all fifty-two text pairings in
///     DESIGN.md §2 clear WCAG AA. Anything here that resolves to a fixed colour
///     in both modes is a bug.
enum Theme {

    // MARK: - The foliage ramp
    //
    // Seven steps, hue held near 100° — plane-tree leaf rather than emerald.
    // Both modes draw from it, and the layered elements draw from three points
    // of it at once.

    enum Foliage {
        /// Forest anchor.
        static let deep = Color(hex: 0x26430F)
        /// The filled-button green in light mode.
        static let canopy = Color(hex: 0x35661F)
        /// The interactive green the research recommends, before the tune below.
        static let accent = Color(hex: 0x3E7C2B)
        /// New leaf. Fills and highlights; never under white text.
        static let fresh = Color(hex: 0x74A343)
        /// Sunlit leaf.
        static let leaf = Color(hex: 0xA9CD7F)
        /// Haze between one layer of leaves and the next.
        static let mist = Color(hex: 0xD6E5B5)
        /// The palest wash in the ramp.
        static let pale = Color(hex: 0xEAF1D8)
    }

    // MARK: - The three working greens
    //
    // Canopy, fresh, mist. Named by what they do rather than by ramp position,
    // because the two modes take them from opposite ends: light goes dark at the
    // front, dark goes bright at the front — Apple's and Material's own
    // lighten-on-dark pattern — and a view that asked for "canopy" by name would
    // be right in one mode and invisible in the other.

    /// The front layer: route lines, icons, selected state, accent text, the
    /// rule that caps a chart bar.
    ///
    /// Light is `#397225` rather than the research's `#3E7C2B`. That value
    /// clears the ground at 4.53 but measures 4.07 on `fill` and 4.38 on
    /// `accentSoft` — and since soft green is used generously here as card and
    /// section real estate, the accent has to clear it. Two steps darker fixes
    /// both without leaving the foliage family.
    static let accent = adaptive(light: 0x397225, dark: 0x9BD97E)
    /// The middle layer: the far stop of a growing gradient, a drawn draft line.
    static let accentStrong = adaptive(light: 0x74A343, dark: 0x74A343)
    /// The back layer: the route still ahead of you, the foot of a chart bar,
    /// the start of a progress fill.
    static let accentMuted = adaptive(light: 0xA9CD7F, dark: 0x35661F)

    /// The fill behind a filled control.
    static let accentFill = adaptive(light: 0x35661F, dark: 0x74A343)
    /// Text drawn on `accentFill`.
    ///
    /// Dark is `#182C08` rather than the ramp's `#26430F`: deep-on-fresh
    /// measured 3.73 and failed. Darkening the text rather than lightening the
    /// button keeps the filled control the fresh green the research points at.
    static let onAccentFill = adaptive(light: 0xFFFFFF, dark: 0x182C08)
    /// Soft leaf. **Used generously** — cards, sections, secondary buttons,
    /// selected rows, chips. This token is where most of the app's green
    /// presence actually comes from.
    static let accentSoft = adaptive(light: 0xEAF1D8, dark: 0x223018)
    /// Text on `accentSoft`. Note the rule in DESIGN.md §2: on a tinted ground a
    /// *label* takes this or `label`, never `accent`.
    static let onAccentSoft = adaptive(light: 0x26430F, dark: 0xA9CD7F)

    /// Dappled sun through leaves. The single warm colour in the system, and it
    /// belongs to exactly one thing: the Featured moment's star. Adaptive
    /// because the warm `#E8B84B` that reads as sun on a night ground measures
    /// 1.6:1 on the light one.
    static let sunlight = adaptive(light: 0x7E5B0E, dark: 0xE8B84B)

    // MARK: - Grounds and surfaces
    //
    // Light is warm paper with a clear yellow-green cast — deliberately greener
    // than Komoot's `#FAF9F4` or AllTrails' birch, because this app is asked to
    // be heavily nature-themed. Dark is a green-tinted near-black, the value the
    // research recommends and the one AllTrails ships alongside.

    /// The page ground.
    static let bg = adaptive(light: 0xF1F3E3, dark: 0x101410)
    /// A card, a sheet, a row group — anything sitting on the ground.
    static let surface = adaptive(light: 0xF8FAF0, dark: 0x1A1F19)
    /// A surface sitting on another surface.
    static let surfaceRaised = adaptive(light: 0xFFFFFF, dark: 0x242A22)
    /// An inset well: a track, a field, a media slot.
    static let fill = adaptive(light: 0xE2E9CC, dark: 0x2B3323)
    /// Card borders and the separators between rows inside them.
    static let mist = adaptive(light: 0xC9D5AB, dark: 0x2F3A26)
    /// Between rows inside a card. Screens no longer divide themselves with
    /// rules — cards do that now.
    static let separator = mist
    /// The map pin's disc: mist green in light so the pin belongs to the
    /// landscape, raised forest in dark so it reads *against* one.
    static let pinDisc = adaptive(light: 0xD6E5B5, dark: 0x242A22)

    // MARK: - Labels
    //
    // Near-neutral, per the research: AllTrails sets body text in onyx
    // `#161F13`, Gaia in a plain granite gray, Komoot in a warm black. The
    // grounds carry the tint and the accents carry the saturation; the ink does
    // neither. `label` is AllTrails' onyx exactly; the two supporting weights
    // are neutral greys re-measured on these grounds.

    static let label = adaptive(light: 0x161F13, dark: 0xF2F4EF)
    static let labelSecondary = adaptive(light: 0x4A544A, dark: 0xAAB4A6)
    static let labelTertiary = adaptive(light: 0x5C625A, dark: 0x9EA99A)

    // MARK: - The canopy wash
    //
    // The signature: two overlapping soft radial glows at the top of a screen —
    // light coming through leaves, with no hard edge anywhere in it. It appears
    // on four screens only (onboarding, featured, walk summary, profile).
    //
    // Light is a wide `fresh` glow with a `pale` glow inside it. Dark inverts,
    // as the research says a dark theme must: two deep glows *lifting* the
    // forest ground, because a pale glow on a night ground reads as fog rather
    // than as leaves.
    //
    // The colours and strengths live here rather than in the view that draws
    // them. `CanopyWash` in `Materials.swift` owns only the geometry.

    enum Canopy {
        /// The wider, further-back glow.
        static let back = adaptive(light: 0x74A343, dark: 0x26430F)
        static let backAlphaLight: Double = 0.28
        static let backAlphaDark: Double = 0.40

        /// The tighter glow inside it.
        static let front = adaptive(light: 0xEAF1D8, dark: 0x35661F)
        static let frontAlphaLight: Double = 0.85
        static let frontAlphaDark: Double = 0.42
    }

    // MARK: - Gradients
    //
    // Growth, in three layers. Anything describing an amount moves mist → fresh
    // → canopy rather than sitting at one green.

    /// A horizontal progress fill: mist where it started, canopy where it has
    /// reached.
    static var progressFill: LinearGradient {
        LinearGradient(
            colors: [accentMuted, accent],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// A chart bar: mist at the baseline, fresh at the top, capped by a canopy
    /// rule the chart draws itself.
    static var barFill: LinearGradient {
        LinearGradient(
            colors: [accentMuted.opacity(0.55), accentStrong],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    /// The bottom-sheet grab handle.
    static let grabHandle = adaptiveAlpha(light: (0x161F13, 0.28), dark: (0xFFFFFF, 0.32))

    // MARK: - The map
    //
    // Every colour and every alpha the map draws, in one place. `RouteMapView`
    // is UIKit and cannot read a SwiftUI environment for its trait, so it asks
    // the map view and picks a value from here; what it must never do is invent
    // one, or the palette would live in two files.

    enum Map {
        /// The sheet drawn across the basemap beneath the routes and pins.
        /// MapKit exposes no tile filter, so this is how the map is graded.
        /// Light pulls Apple's greys towards leaf; dark goes *darker*, because
        /// the night basemap is already dim and lightening it would flatten the
        /// green instead of lifting it.
        static let gradeLight = Color(hex: 0xEAF1D8)
        static let gradeLightAlpha: Double = 0.40
        static let gradeDark = Color(hex: 0x0A0F09)
        static let gradeDarkAlpha: Double = 0.46

        /// The wide, faint line under every route that lifts it off the map. It
        /// is ink in light and light in dark — a dark casing on a dark basemap
        /// is invisible — and both are stronger than they were on a grey map,
        /// because a green line on a green map needs more separation.
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
        static let smColor = adaptiveAlpha(light: (0x161F13, 0.10), dark: (0x000000, 0))
        static let smRadius: CGFloat = 6
        static let smY: CGFloat = 2

        static let mdColor = adaptiveAlpha(light: (0x161F13, 0.14), dark: (0x000000, 0))
        static let mdRadius: CGFloat = 18
        static let mdY: CGFloat = 6

        static let lgColor = adaptiveAlpha(light: (0x161F13, 0.18), dark: (0x000000, 0))
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
    /// justifies them, and a contrast check can read them straight out of this
    /// file.
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light, alpha: 1)
        })
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
