import Foundation

/// The raw numbers behind every colour in the app, one light/dark pair per role.
///
/// Kept apart from `Theme` so the contrast test can read plain integers rather
/// than resolving SwiftUI colours. The direction comes from
/// `research/ecosia-design-research.md`: neutral grounds in both appearances,
/// near-neutral text, and green only where it marks something — primary
/// buttons, the route line, selection, the bookmark, the Featured tag.
enum Palette {
    struct Pair: Sendable {
        let light: UInt32
        let dark: UInt32
    }

    static let bg = Pair(light: 0xF8F8F6, dark: 0x1A1A1A)
    static let surface = Pair(light: 0xFFFFFF, dark: 0x242424)
    static let surfaceRaised = Pair(light: 0xFFFFFF, dark: 0x2F2F2E)
    static let fill = Pair(light: 0xF0F0EB, dark: 0x333333)
    static let separator = Pair(light: 0xDEDED9, dark: 0x42423F)

    static let label = Pair(light: 0x2B2B29, dark: 0xF4F4F1)
    static let labelSecondary = Pair(light: 0x63635D, dark: 0xB5B5AE)
    static let labelTertiary = Pair(light: 0x6B6B65, dark: 0xA3A39C)

    static let accent = Pair(light: 0x3F6B23, dark: 0xA9D27E)
    static let primaryFill = Pair(light: 0x3F6B23, dark: 0xA9D27E)
    static let onPrimaryFill = Pair(light: 0xFFFFFF, dark: 0x1A1A1A)
    static let featuredFill = Pair(light: 0xD6E89A, dark: 0xD6E89A)
    static let onFeaturedFill = Pair(light: 0x2B2B29, dark: 0x1A1A1A)
}
