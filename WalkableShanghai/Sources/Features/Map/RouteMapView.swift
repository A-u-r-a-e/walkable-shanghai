import SwiftUI
import MapKit

/// The single map surface for the whole app.
///
/// Every screen that shows a map goes through this type. It declares all four
/// modes the design calls for up front — discover, detail, track, build — even
/// though Phase 2 only implements `discover`, so that the seam is visible and
/// the later phases extend one file rather than adding parallel map views.
///
/// It is also the swap point named in the plan: MapKit was chosen for zero
/// dependencies, no API keys, no tile bill and no China map-licensing burden of
/// our own. If offline tile packs later force a move to MapLibre, this file is
/// what gets rewritten and nothing else.
struct RouteMapView: UIViewRepresentable {

    enum Mode {
        /// Every listed route drawn at once, with a pin each.
        case discover
        /// One route, framed. Phase 3.
        case detail
        /// One route with live progress along it. Phase 4.
        case track
        /// Tap-to-drop point drawing. Phase 5.
        case build
    }

    /// Read only so that flipping light/dark re-runs `updateUIView`. MapKit
    /// caches overlay renderers, so without something to invalidate on, a
    /// casing chosen for one appearance would survive into the other.
    @Environment(\.colorScheme) private var colorScheme
    /// Read so pins carry the route's name in the app's language, and so a
    /// language switch relabels them.
    @Environment(AppSettings.self) private var settings

    let mode: Mode
    /// The routes to draw. In `discover` this is the filtered list, so the map
    /// and the sheet below it always agree.
    let routes: [Route]
    var style: MapStyleOption = .standard
    /// How much of the bottom of the map the sheet covers *at rest*, so the
    /// camera frames the routes in the part you can actually see.
    ///
    /// Deliberately the sheet's resting height rather than its live height: if
    /// the camera re-fitted every time the sheet moved, expanding the sheet
    /// would zoom the map out until all the routes collapsed into one cluster.
    /// A map should hold still while a panel slides over it.
    var bottomInset: CGFloat = 0
    var topInset: CGFloat = 0
    var onSelectRoute: ((String) -> Void)?

    /// `track` only: how much of the route has been walked, 0 to 1. The line is
    /// drawn dashed ahead of this point and solid behind it.
    var walkedFraction: Double = 0
    /// `track` only: where to draw the walker.
    var walkerCoordinate: CLLocationCoordinate2D?
    /// `track` only: keep the camera on the walker as they move.
    var followsWalker: Bool = false

    /// `build` only: the points dropped so far, in the order they were tapped.
    var draftPoints: [CLLocationCoordinate2D] = []
    /// `build` only: called with the coordinate under a tap.
    var onAddPoint: ((CLLocationCoordinate2D) -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator

        map.preferredConfiguration = Self.configuration(for: style)
        map.accessibilityIdentifier = "route-map"
        map.accessibilityValue = style.rawValue

        // The basemap follows the app's appearance explicitly rather than by
        // inheritance, so the casing and the tiles under it can never disagree
        // about which mode they are in.
        map.overrideUserInterfaceStyle = .unspecified

        map.showsCompass = false
        map.showsScale = false
        map.isPitchEnabled = false
        map.isRotateEnabled = false
        map.showsUserLocation = false  // Real location is Phase 4.

        map.register(
            RoutePinView.self,
            forAnnotationViewWithReuseIdentifier: RoutePinView.reuseIdentifier
        )

        if mode == .track {
            // Tracking is the one mode where the walker should not be able to
            // shove the map somewhere the camera will immediately drag back.
            map.isScrollEnabled = false
            map.isZoomEnabled = false
        }

        if mode == .build {
            let tap = UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleBuildTap(_:))
            )
            map.addGestureRecognizer(tap)
            // Somewhere central and legible to start drawing from. The walker
            // pans to where they actually mean before their first tap.
            map.setRegion(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 31.2138, longitude: 121.4360),
                    latitudinalMeters: 2200,
                    longitudinalMeters: 2200
                ),
                animated: false
            )
        }
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.parent = self

        if context.coordinator.lastStyle != style {
            context.coordinator.lastStyle = style
            map.preferredConfiguration = Self.configuration(for: style)
            map.accessibilityValue = style.rawValue
        }

        // Redraw and re-frame only when the set of routes actually changes —
        // a filter change or the first load. Panning and sheet movement leave
        // the camera alone.
        // The mode is part of the signature so that selecting a route redraws
        // (pins off, one line) even when the list already held only that route.
        // The appearance is part of it too: a light-to-dark flip has to redraw
        // for the same reason a filter change does — the overlays are styled
        // for one mode and cached. And the language, so the pins' names follow
        // a language switch.
        let signature = routes.map(\.id).joined(separator: ",") + "|\(mode)|\(colorScheme)|\(settings.language.rawValue)"
        let routesChanged = context.coordinator.lastSignature != signature

        if routesChanged {
            context.coordinator.lastSignature = signature
            redraw(map)
            frame(map, animated: context.coordinator.hasFramedOnce)
            context.coordinator.hasFramedOnce = true
        }

        if mode == .build {
            let signature = draftPoints.map { "\($0.latitude),\($0.longitude)" }.joined(separator: ";")
            if context.coordinator.lastDraftSignature != signature {
                context.coordinator.lastDraftSignature = signature
                redrawDraft(map)
            }
            return
        }

        guard mode == .track else { return }

        // Tracking is the one mode that redraws continuously: the walked line
        // grows and the walker moves on every fix. Redrawing only when the
        // progress actually changed keeps this from thrashing on every SwiftUI
        // update.
        let step = (walkedFraction * 1000).rounded()
        if routesChanged || context.coordinator.lastWalkedStep != step {
            context.coordinator.lastWalkedStep = step
            redrawWalked(map)
        }
        if followsWalker, let walkerCoordinate {
            context.coordinator.follow(map, to: walkerCoordinate)
        }
    }

    /// MapKit's configuration for each style.
    ///
    /// Standard keeps the muted emphasis so the route reads over the map, and
    /// hides Apple's points of interest, which compete with our pins. Traffic
    /// is the same map with traffic drawn. Satellite is imagery with street
    /// labels (MapKit's hybrid), because bare imagery gives a walker nothing
    /// to read.
    static func configuration(for style: MapStyleOption) -> MKMapConfiguration {
        switch style {
        case .standard, .traffic:
            let configuration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
            configuration.pointOfInterestFilter = .excludingAll
            configuration.showsTraffic = style == .traffic
            return configuration
        case .satellite:
            let configuration = MKHybridMapConfiguration(elevationStyle: .flat)
            configuration.pointOfInterestFilter = .excludingAll
            return configuration
        }
    }

    // MARK: - Drawing

    private func redraw(_ map: MKMapView) {
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations)

        for route in routes {
            let coordinates = route.points.map(\.clLocationCoordinate)
            guard coordinates.count > 1 else { continue }

            // Two lines per route, as in the source design: a wide, almost
            // invisible casing that lifts the route off the map, and a thin
            // accent line on top. One line alone disappears over pale streets.
            let casing = RoutePolyline(coordinates: coordinates, count: coordinates.count)
            casing.role = .casing
            casing.routeId = route.id

            let line = RoutePolyline(coordinates: coordinates, count: coordinates.count)
            line.role = .line
            line.routeId = route.id

            // `.aboveLabels` so the route draws over street names rather than
            // under them.
            map.addOverlay(casing, level: .aboveLabels)
            map.addOverlay(line, level: .aboveLabels)
        }

        if mode == .track {
            redrawWalked(map)
        }

        if mode == .discover {
            map.addAnnotations(routes.map {
                RoutePinAnnotation(
                    routeId: $0.id,
                    coordinate: $0.pin.clLocationCoordinate,
                    title: $0.name(settings.language)
                )
            })
        }
    }

    /// Redraws just the walked part of the line and the walker dot, leaving the
    /// route underneath alone.
    private func redrawWalked(_ map: MKMapView) {
        for overlay in map.overlays where (overlay as? RoutePolyline)?.role == .walked {
            map.removeOverlay(overlay)
        }
        for annotation in map.annotations where annotation is WalkerAnnotation {
            map.removeAnnotation(annotation)
        }

        guard let route = routes.first else { return }
        let full = route.points.map(\.clLocationCoordinate)

        let walked = RouteGeometry.prefix(full, fraction: walkedFraction)
        if walked.count > 1 {
            let line = RoutePolyline(coordinates: walked, count: walked.count)
            line.role = .walked
            line.routeId = route.id
            map.addOverlay(line, level: .aboveLabels)
        }

        if let walkerCoordinate {
            map.addAnnotation(WalkerAnnotation(coordinate: walkerCoordinate))
        }
    }

    /// Redraws the route being drawn: a dotted line through the points, the
    /// first one filled and the rest hollow, so the direction of travel is
    /// readable at a glance.
    private func redrawDraft(_ map: MKMapView) {
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations)

        if draftPoints.count > 1 {
            let line = RoutePolyline(coordinates: draftPoints, count: draftPoints.count)
            line.role = .draft
            map.addOverlay(line, level: .aboveLabels)
        }
        map.addAnnotations(draftPoints.enumerated().map { index, coordinate in
            DraftPointAnnotation(coordinate: coordinate, isFirst: index == 0, index: index)
        })
    }

    private func frame(_ map: MKMapView, animated: Bool) {
        let allPoints = routes.flatMap(\.points).map { MKMapPoint($0.clLocationCoordinate) }
        guard !allPoints.isEmpty else { return }

        let rect = allPoints.reduce(MKMapRect.null) { partial, point in
            partial.union(MKMapRect(origin: point, size: MKMapSize(width: 0, height: 0)))
        }
        guard !rect.isNull else { return }

        map.setVisibleMapRect(
            rect,
            edgePadding: UIEdgeInsets(top: topInset + 24, left: 40, bottom: bottomInset + 24, right: 40),
            animated: animated
        )
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RouteMapView
        var lastSignature: String?
        var lastStyle: MapStyleOption?
        var hasFramedOnce = false
        var lastWalkedStep: Double = -1
        var lastDraftSignature: String?

        @objc func handleBuildTap(_ gesture: UITapGestureRecognizer) {
            guard let map = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: map)
            parent.onAddPoint?(map.convert(point, toCoordinateFrom: map))
        }
        private var hasCenteredOnWalker = false

        /// Keeps the walker in view without fighting the walker's own panning:
        /// the first fix zooms in, and after that the camera only re-centres.
        func follow(_ map: MKMapView, to coordinate: CLLocationCoordinate2D) {
            if hasCenteredOnWalker {
                map.setCenter(coordinate, animated: true)
            } else {
                hasCenteredOnWalker = true
                map.setRegion(
                    MKCoordinateRegion(center: coordinate, latitudinalMeters: 700, longitudinalMeters: 700),
                    animated: true
                )
            }
        }

        init(_ parent: RouteMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? RoutePolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            switch polyline.role {
            case .casing:
                // The casing lifts the line off the map. On a dark basemap an
                // ink casing is invisible, so it flips to a light one.
                let isDark = mapView.traitCollection.userInterfaceStyle == .dark
                renderer.strokeColor = UIColor(isDark ? Theme.Map.casingDark : Theme.Map.casingLight)
                renderer.lineWidth = Theme.Map.casingWidth
            case .line:
                if parent.mode == .track {
                    // The route ahead of you: present, but plainly not yet
                    // done. Thinner, dashed and slightly faded against the
                    // solid line behind you, so the two halves read as two
                    // states.
                    renderer.strokeColor = UIColor(Theme.accent)
                        .withAlphaComponent(Theme.Map.aheadAlpha)
                    renderer.lineWidth = Theme.Map.aheadWidth
                    renderer.lineDashPattern = Theme.Map.aheadDash
                } else {
                    renderer.strokeColor = UIColor(Theme.accent)
                        .withAlphaComponent(Theme.Map.lineAlpha)
                    renderer.lineWidth = Theme.Map.lineWidth
                }
            case .draft:
                renderer.strokeColor = UIColor(Theme.accent)
                    .withAlphaComponent(Theme.Map.draftAlpha)
                renderer.lineWidth = Theme.Map.draftWidth
                renderer.lineDashPattern = Theme.Map.draftDash
            case .walked:
                // The ground you have covered: solid and heavier.
                renderer.strokeColor = UIColor(Theme.accent)
                renderer.lineWidth = Theme.Map.walkedWidth
            }
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let draft = annotation as? DraftPointAnnotation {
                let view = mapView.dequeueReusableAnnotationView(
                    withIdentifier: DraftPointView.reuseIdentifier
                ) as? DraftPointView ?? DraftPointView(
                    annotation: annotation,
                    reuseIdentifier: DraftPointView.reuseIdentifier
                )
                view.annotation = annotation
                view.configure(isFirst: draft.isFirst, index: draft.index)
                return view
            }
            if annotation is WalkerAnnotation {
                let view = mapView.dequeueReusableAnnotationView(
                    withIdentifier: WalkerView.reuseIdentifier
                ) as? WalkerView ?? WalkerView(annotation: annotation, reuseIdentifier: WalkerView.reuseIdentifier)
                view.annotation = annotation
                return view
            }
            guard let pin = annotation as? RoutePinAnnotation else { return nil }
            let view = mapView.dequeueReusableAnnotationView(
                withIdentifier: RoutePinView.reuseIdentifier,
                for: pin
            ) as? RoutePinView
            view?.configure(routeId: pin.routeId, routeName: pin.title ?? "")
            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let pin = view.annotation as? RoutePinAnnotation else { return }
            // Deselect straight away: the pin is a button, not a state. Leaving
            // it selected would show a callout we do not want and would stop a
            // second tap from working.
            mapView.deselectAnnotation(pin, animated: false)
            parent.onSelectRoute?(pin.routeId)
        }
    }
}

// MARK: - Overlay model

/// A route line tagged with what it is drawing, so one renderer can style the
/// casing and the line differently without comparing object identity.
final class RoutePolyline: MKPolyline {
    enum Role { case casing, line, walked, draft }
    var role: Role = .line
    var routeId: String = ""
}

// MARK: - Annotation model

final class RoutePinAnnotation: NSObject, MKAnnotation {
    let routeId: String
    let coordinate: CLLocationCoordinate2D
    var title: String?

    init(routeId: String, coordinate: CLLocationCoordinate2D, title: String? = nil) {
        self.routeId = routeId
        self.coordinate = coordinate
        self.title = title
    }
}

/// The disc that marks a route on the discover map: a plain accent dot on the
/// card surface.
///
/// Built by hand rather than with `MKMarkerAnnotationView` because the system
/// marker is a filled teardrop in Apple's red, which would be the only thing on
/// the screen that is not part of this palette.
final class RoutePinView: MKAnnotationView {

    static let reuseIdentifier = "RoutePin"

    private let dot = UIView()
    private let disc = UIView()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        centerOffset = .zero
        canShowCallout = false
        backgroundColor = .clear

        disc.frame = bounds
        // The card surface, ringed in accent, so the pin reads against the
        // basemap in both appearances.
        disc.backgroundColor = UIColor(Theme.surface)
        disc.layer.cornerRadius = 17
        disc.layer.borderWidth = Theme.Map.pinRingWidth
        disc.layer.borderColor = UIColor(Theme.accent).cgColor
        disc.layer.shadowColor = UIColor(Theme.Map.pinShadow).cgColor
        disc.layer.shadowOpacity = Theme.Map.pinShadowOpacity
        disc.layer.shadowRadius = 4
        disc.layer.shadowOffset = CGSize(width: 0, height: 2)
        disc.isUserInteractionEnabled = false
        addSubview(disc)

        dot.frame = CGRect(x: 11, y: 11, width: 12, height: 12)
        dot.backgroundColor = UIColor(Theme.accent)
        dot.layer.cornerRadius = 6
        dot.isUserInteractionEnabled = false
        addSubview(dot)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(routeId: String, routeName: String) {
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = routeName.isEmpty ? routeId : routeName
        accessibilityIdentifier = "route-pin-\(routeId)"
    }
}

// MARK: - Walker

/// The walker's own position during a recorded walk.
final class WalkerAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

/// An accent disc with a soft halo, pulsing slowly.
///
/// Not `MKUserLocationView`: this dot marks progress along a *route*, which
/// during a simulated or replayed walk is not the same place as the device. It
/// also has to match the design, and the system dot is Apple blue.
final class WalkerView: MKAnnotationView {

    static let reuseIdentifier = "Walker"

    private let halo = UIView()
    private let core = UIView()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        backgroundColor = .clear
        canShowCallout = false
        isAccessibilityElement = false

        halo.frame = bounds
        halo.backgroundColor = UIColor(Theme.accent).withAlphaComponent(Theme.Map.haloAlpha)
        halo.layer.cornerRadius = 15
        halo.isUserInteractionEnabled = false
        addSubview(halo)

        core.frame = CGRect(x: 9, y: 9, width: 12, height: 12)
        core.backgroundColor = UIColor(Theme.accent)
        core.layer.cornerRadius = 6
        core.layer.borderWidth = 2
        core.layer.borderColor = UIColor(Theme.surface).cgColor
        core.isUserInteractionEnabled = false
        addSubview(core)

        pulse()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// A slow breath, not a blink — it should read as "live" at a glance without
    /// pulling the eye away from the line.
    private func pulse() {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 0.75
        animation.toValue = 1.25
        animation.duration = 1.4
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        halo.layer.add(animation, forKey: "pulse")
    }
}

// MARK: - Draft points

/// One point the walker dropped while drawing a route.
final class DraftPointAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let isFirst: Bool
    let index: Int

    init(coordinate: CLLocationCoordinate2D, isFirst: Bool, index: Int) {
        self.coordinate = coordinate
        self.isFirst = isFirst
        self.index = index
    }
}

/// A small accent ring; filled for the first point, hollow for the rest.
///
/// The fill is the only thing distinguishing the start, which is all the
/// distinction it needs — a route you are drawing has a beginning and a
/// direction, and nothing else about the points differs.
final class DraftPointView: MKAnnotationView {

    static let reuseIdentifier = "DraftPoint"

    private let dot = UIView()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 16, height: 16)
        backgroundColor = .clear
        canShowCallout = false

        dot.frame = bounds
        dot.layer.cornerRadius = 8
        dot.layer.borderWidth = 2
        dot.layer.borderColor = UIColor(Theme.accent).cgColor
        dot.isUserInteractionEnabled = false
        addSubview(dot)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(isFirst: Bool, index: Int) {
        dot.backgroundColor = isFirst ? UIColor(Theme.accent) : UIColor(Theme.surface)
        isAccessibilityElement = true
        accessibilityIdentifier = "draft-point-\(index)"
    }
}
