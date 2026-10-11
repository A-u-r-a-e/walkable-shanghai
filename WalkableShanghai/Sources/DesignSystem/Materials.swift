import SwiftUI

/// Liquid Glass on iOS 26, system materials on iOS 18 — decided once, here.
///
/// The design rule is in DESIGN.md §4 and is short enough to repeat: **glass is
/// for things that float over content.** Anything sitting *on* the page is
/// opaque. Glass over an opaque background is noise — there is nothing behind it
/// to refract. Glass over the map is the entire point, because the map keeps
/// showing through the controls that sit on it.
///
/// Views never write `#available` themselves. A new floating control calls
/// `.floatingSurface(...)`; the fork stays in this file, which is also what makes
/// the iOS 18 fallback a design decision rather than eight scattered guesses.
extension View {

    /// A control that floats over live content: the map's search field, its
    /// filter row, the REC button, the back and bookmark buttons on route
    /// detail.
    ///
    /// - Parameters:
    ///   - shape: the silhouette the glass takes. Pass the same shape used to
    ///     clip the content, or the highlight will not line up with the edge.
    ///   - interactive: true for something you press. On iOS 26 this makes the
    ///     glass respond to touch; on iOS 18 it changes nothing, because the
    ///     material has no such affordance and faking one would be worse than
    ///     not having it.
    @ViewBuilder
    func floatingSurface(
        in shape: some Shape,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, *) {
            Group {
                if interactive {
                    glassEffect(.regular.interactive(), in: shape)
                } else {
                    glassEffect(.regular, in: shape)
                }
            }
            // Without this the control is only tappable where its glyph is.
            // The old opaque `.background` made the whole circle hittable as a
            // side effect; glass draws behind the content and does not, so a
            // 44pt button became a 16pt one and back/bookmark taps silently
            // missed. Hit area is stated explicitly rather than inherited.
            .contentShape(shape)
        } else {
            // The honest iOS 18 equivalent: content still shows through a
            // frosted control, without the specular edge. Clipped to the same
            // shape so the two paths are interchangeable at the call site.
            background(.ultraThinMaterial, in: shape)
                .contentShape(shape)
        }
    }

    /// A large panel that floats over content — the map's bottom sheet.
    ///
    /// Heavier than `floatingSurface` on both paths: a sheet carries reading
    /// material, and text over a thin material at that size is uncomfortable.
    @ViewBuilder
    func floatingPanel(in shape: some Shape) -> some View {
        // No `contentShape` here, unlike `floatingSurface`: the panel is a
        // container, and giving it a hit shape of its own would put one target
        // in front of the rows and the scroll view inside it.
        if #available(iOS 26.0, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.regularMaterial, in: shape)
        }
    }

    /// An opaque card sitting on the page: figure grids, list groups, anything
    /// carrying long-form text. Never glass.
    ///
    /// **Soft green, not a near-white panel.** This is the single biggest lever
    /// on how green the app reads, because almost everything on almost every
    /// screen is in a card. The research is what settles it: AllTrails and
    /// Komoot both run warm, barely-tinted *page* grounds and get their green
    /// from large soft-green surfaces sitting on them. A near-white card on a
    /// cream ground is how the first attempt ended up looking grey.
    ///
    /// A `mist` border as well as a fill, because on a tinted ground the step
    /// from ground to card is deliberately small, and dark mode draws no shadow
    /// at all.
    func card(radius: CGFloat = Theme.Radius.md) -> some View {
        background(Theme.accentSoft, in: Theme.shape(radius))
            .overlay { Theme.shape(radius).strokeBorder(Theme.mist, lineWidth: 1) }
            .elevationSm()
    }

    /// Puts this screen under the canopy: two soft leaf glows at the top of the
    /// view, over the app's ground.
    ///
    /// The signature device, and deliberately rationed — onboarding, featured,
    /// the walk summary and the profile, and nowhere else. It is a *ground*, so
    /// it takes no corner, no border and no shadow, and nothing is ever drawn in
    /// the wash colour and elevated at the same time.
    func canopyWash(height: CGFloat = 320) -> some View {
        background(alignment: .top) {
            CanopyWash(height: height)
        }
        .screenBackground()
    }

    /// Puts a screen on the app's ground.
    ///
    /// Replaced the old `paperBackground()`, which named a colour that no longer
    /// exists; that spelling is now gone from the app entirely. Kept as a
    /// modifier rather than inlined so the ground can change in one place.
    func screenBackground() -> some View {
        background(Theme.bg.ignoresSafeArea())
    }
}


// MARK: - The canopy wash

/// Light through leaves: two overlapping radial glows, no hard edge anywhere.
///
/// Radial rather than linear because a linear ramp has a direction and a canopy
/// does not — the eye reads a band as a header bar and a glow as light. The two
/// stops are offset from each other so the overlap is off-centre, which is what
/// keeps it from reading as a logo.
///
/// In light mode a wide mist glow carries a leaf glow inside it. In dark mode the
/// same geometry runs the other way: two deep-green glows *lifting* the forest
/// ground rather than washing it out, because a pale glow on a night ground
/// would read as fog rather than as leaves.
struct CanopyWash: View {
    var height: CGFloat = 320

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let isDark = colorScheme == .dark
        ZStack(alignment: .top) {
            // Colour and strength come from `Theme.Canopy`; this view owns
            // only the geometry — two offset centres and their radii — because
            // that is composition and not palette.
            RadialGradient(
                colors: [
                    Theme.Canopy.back.opacity(
                        isDark ? Theme.Canopy.backAlphaDark : Theme.Canopy.backAlphaLight
                    ),
                    .clear,
                ],
                center: UnitPoint(x: 0.18, y: 0.02),
                startRadius: 0,
                endRadius: height * 1.15
            )
            RadialGradient(
                colors: [
                    Theme.Canopy.front.opacity(
                        isDark ? Theme.Canopy.frontAlphaDark : Theme.Canopy.frontAlphaLight
                    ),
                    .clear,
                ],
                center: UnitPoint(x: 0.86, y: 0.16),
                startRadius: 0,
                endRadius: height * 0.95
            )
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
