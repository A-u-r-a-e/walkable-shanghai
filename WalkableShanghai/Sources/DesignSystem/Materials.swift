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
    /// `surface` with a hairline `separator` border, because the step from
    /// ground to card is small in both appearances and dark mode draws no
    /// shadow at all.
    func card(radius: CGFloat = Theme.Radius.md) -> some View {
        background(Theme.surface, in: Theme.shape(radius))
            .overlay { Theme.shape(radius).strokeBorder(Theme.separator, lineWidth: Theme.hairline) }
            .elevationSm()
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

