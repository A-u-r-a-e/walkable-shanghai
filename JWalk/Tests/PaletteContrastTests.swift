import XCTest
@testable import JWalk

/// Every text/background pairing the app uses must meet WCAG AA in both
/// appearances. The values are read from `Palette`, the same numbers `Theme`
/// draws with, so the test and the screens cannot disagree.
final class PaletteContrastTests: XCTestCase {

    private func luminance(_ hex: UInt32) -> Double {
        func channel(_ shift: UInt32) -> Double {
            let value = Double((hex >> shift) & 0xFF) / 255
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0)
    }

    private func ratio(_ a: UInt32, _ b: UInt32) -> Double {
        let (la, lb) = (luminance(a), luminance(b))
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    private func assertPair(_ text: Palette.Pair, on ground: Palette.Pair, minimum: Double = 4.5, _ name: String, line: UInt = #line) {
        XCTAssertGreaterThanOrEqual(ratio(text.light, ground.light), minimum, "\(name) (light)", line: line)
        XCTAssertGreaterThanOrEqual(ratio(text.dark, ground.dark), minimum, "\(name) (dark)", line: line)
    }

    func testBodyTextReadsOnEveryGround() {
        for (groundName, ground) in [("bg", Palette.bg), ("surface", Palette.surface), ("surfaceRaised", Palette.surfaceRaised), ("fill", Palette.fill)] {
            assertPair(Palette.label, on: ground, "label on \(groundName)")
            assertPair(Palette.labelSecondary, on: ground, "labelSecondary on \(groundName)")
            assertPair(Palette.labelTertiary, on: ground, "labelTertiary on \(groundName)")
            assertPair(Palette.accent, on: ground, "accent on \(groundName)")
        }
    }

    func testFilledControlsCarryReadableLabels() {
        assertPair(Palette.onPrimaryFill, on: Palette.primaryFill, "primary button label")
        assertPair(Palette.onFeaturedFill, on: Palette.featuredFill, "featured tag label")
    }

    func testGroundsAreNeutral() {
        // Saturation of each ground, in HSL terms. The canopy palette failed
        // because the grounds themselves were green; these must stay grey.
        for pair in [Palette.bg, Palette.surface, Palette.surfaceRaised, Palette.fill, Palette.separator] {
            for hex in [pair.light, pair.dark] {
                let r = Double((hex >> 16) & 0xFF), g = Double((hex >> 8) & 0xFF), b = Double(hex & 0xFF)
                XCTAssertLessThanOrEqual(max(r, g, b) - min(r, g, b), 16, String(format: "ground %06X is tinted", hex))
            }
        }
    }
}
