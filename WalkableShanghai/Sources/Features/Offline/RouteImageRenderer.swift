import UIKit
import SwiftUI
import CoreLocation

/// Draws a route's line onto the app's neutral well, as a picture.
///
/// This is what makes offline honest without solving tile hosting. The line is
/// the part of the map this app actually cares about, and it is already in our
/// own data — so it can be drawn from geometry alone. No tiles are requested,
/// nothing is cached from Apple or AutoNavi, and the result works in airplane
/// mode because it never needed a network in the first place.
///
/// What it cannot show is streets and labels. That is the honest cost of option
/// (a), and it is why the Saved screen says what offline keeps rather than
/// implying a full map.
enum RouteImageRenderer {

    /// Every colour in `Theme` is now adaptive, and this renderer runs outside
    /// any view, so a plain `UIColor(...)` here would resolve against whatever
    /// trait happened to be current when the download ran. A route downloaded
    /// at night would then store a dark picture and show it in daylight. The
    /// stored bytes must not depend on the time of day, so the palette is
    /// resolved against a fixed light trait.
    private static let lightTrait = UITraitCollection(userInterfaceStyle: .light)

    private static func fixed(_ color: Color) -> UIColor {
        UIColor(color).resolvedColor(with: lightTrait)
    }

    /// Renders the route and returns PNG bytes.
    static func pngData(for route: Route, size: CGSize) -> Data? {
        let coordinates = route.points.map(\.clLocationCoordinate)
        guard coordinates.count > 1 else { return nil }

        let format = UIGraphicsImageRendererFormat()
        // Fixed scale rather than the device's: the stored size should not
        // depend on which phone downloaded it.
        format.scale = 2
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let cg = context.cgContext
            let bounds = CGRect(origin: .zero, size: size)

            // The stored picture stands in for the map, so it takes the
            // neutral well rather than the page: a plain field under the line.
            // The ruled paper grid this used to carry was a print device and
            // went with the rest of them.
            cg.setFillColor(fixed(Theme.fill).cgColor)
            cg.fill(bounds)

            let points = project(coordinates, into: bounds.insetBy(dx: size.width * 0.12,
                                                                  dy: size.height * 0.14))
            guard points.count > 1 else { return }

            let path = CGMutablePath()
            path.addLines(between: points)

            // The same two-line treatment as the live map: a wide, faint
            // casing under a thin accent line.
            cg.setLineCap(.round)
            cg.setLineJoin(.round)

            cg.addPath(path)
            cg.setStrokeColor(fixed(Theme.Map.casingLight).cgColor)
            cg.setLineWidth(14)
            cg.strokePath()

            cg.addPath(path)
            cg.setStrokeColor(fixed(Theme.accent).cgColor)
            cg.setLineWidth(5)
            cg.strokePath()

            // Start and end, so the direction of the walk is readable.
            marker(cg, at: points[0], filled: true)
            marker(cg, at: points[points.count - 1], filled: false)
        }
        return image.pngData()
    }

    // MARK: - Drawing pieces

    private static func marker(_ cg: CGContext, at point: CGPoint, filled: Bool) {
        let radius: CGFloat = 9
        let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)

        cg.setFillColor(fixed(filled ? Theme.accent : Theme.surface).cgColor)
        cg.fillEllipse(in: rect)
        cg.setStrokeColor(fixed(Theme.accent).cgColor)
        cg.setLineWidth(3)
        cg.strokeEllipse(in: rect)
    }

    /// Maps latitude and longitude onto the image, preserving the route's shape.
    ///
    /// Longitude is scaled by cos(latitude) so the line is not stretched
    /// sideways — at Shanghai's latitude a degree of longitude is about 85% of
    /// a degree of latitude, and without this correction every route comes out
    /// noticeably wider than it really is.
    static func project(_ coordinates: [CLLocationCoordinate2D], into rect: CGRect) -> [CGPoint] {
        guard !coordinates.isEmpty else { return [] }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let midLatitude = (latitudes.min()! + latitudes.max()!) / 2
        let lonScale = cos(midLatitude * .pi / 180)

        let xs = longitudes.map { $0 * lonScale }
        let minX = xs.min()!, maxX = xs.max()!
        let minY = latitudes.min()!, maxY = latitudes.max()!

        let spanX = max(maxX - minX, 1e-9)
        let spanY = max(maxY - minY, 1e-9)
        // One scale for both axes, so the shape is not distorted to fill the box.
        let scale = min(rect.width / spanX, rect.height / spanY)

        let drawnWidth = spanX * scale
        let drawnHeight = spanY * scale
        let offsetX = rect.minX + (rect.width - drawnWidth) / 2
        let offsetY = rect.minY + (rect.height - drawnHeight) / 2

        return coordinates.map { coordinate in
            let x = offsetX + (coordinate.longitude * lonScale - minX) * scale
            // Flipped: latitude increases north, image y increases downward.
            let y = offsetY + (maxY - coordinate.latitude) * scale
            return CGPoint(x: x, y: y)
        }
    }
}
