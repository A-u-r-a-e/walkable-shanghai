import XCTest

/// Captures one screenshot of every screen in the app, for reviewing the
/// redesign.
///
/// It exists because the design review needs the *same* eleven screens in both
/// appearances, and the feature suites capture whatever their own tests happen
/// to pass through. Appearance is not set from in here — `simctl ui <udid>
/// appearance` decides it, and the app follows the system — so the identical
/// test produces the light set and the dark set.
///
/// Every assertion here is a *navigation* assertion: it fails if a screen cannot
/// be reached, never because of how a screen looks. Nothing in this file asserts
/// a colour.
final class RedesignScreenshotUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp(
        onboarding: Bool = false,
        simulateWalk: String? = nil,
        resetUserState: Bool = true
    ) -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = [
            "-settings.language", "english",
            "-settings.hasSeenOnboarding", onboarding ? "NO" : "YES",
        ]
        if resetUserState { arguments.append("-uitest.resetUserState") }
        if let simulateWalk { arguments += ["-uitest.simulateWalk", simulateWalk] }
        app.launchArguments = arguments
        app.launch()
        return app
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        // A beat before the shutter: the canopy wash and the map's grade are
        // both drawn asynchronously, and a shot taken too early is a review of
        // nothing.
        Thread.sleep(forTimeInterval: 1.2)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func waitForMap(_ app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["routes-in-view-count"].waitForExistence(timeout: 20),
                      "the map screen never appeared")
        Thread.sleep(forTimeInterval: 2.0)
    }

    /// The peeking sheet fits a different number of rows on each OS, so a row
    /// below the fold is expanded into reach rather than assumed hittable. See
    /// the README's note on `revealRouteRow`.
    @discardableResult
    private func revealRouteRow(_ app: XCUIApplication, _ routeId: String) -> XCUIElement {
        let row = app.buttons["route-row-\(routeId)"]
        XCTAssertTrue(row.waitForExistence(timeout: 10), "no row for \(routeId)")
        if !row.isHittable {
            element(app, "sheet-handle").tap()
            Thread.sleep(forTimeInterval: 1.2)
        }
        for _ in 0..<3 where !row.isHittable {
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.6)
        }
        XCTAssertTrue(row.isHittable, "\(routeId) is not reachable even with the sheet open")
        return row
    }

    // MARK: - The set

    /// Onboarding, which is also the first look at the canopy wash.
    func testCaptureOnboarding() {
        let app = launchApp(onboarding: true)
        XCTAssertTrue(app.buttons["Find a route near me"].waitForExistence(timeout: 20),
                      "onboarding never appeared")
        capture(app, "onboarding")
    }

    /// Map discovery, route detail and the featured page — the three screens
    /// step one converted, re-shot on the new palette.
    func testCaptureMapDetailAndFeatured() {
        let app = launchApp()
        waitForMap(app)
        capture(app, "map")

        element(app, "featured-banner").tap()
        XCTAssertTrue(app.staticTexts["featured-title"].waitForExistence(timeout: 15),
                      "the featured page never appeared")
        capture(app, "featured")
        element(app, "featured-back-button").tap()
        Thread.sleep(forTimeInterval: 1.0)

        revealRouteRow(app, "wukang").tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 15),
                      "route detail never appeared")
        capture(app, "route-detail")

        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.8)
        app.buttons["notes-button"].tap()
        XCTAssertTrue(app.staticTexts["Notes from walkers"].waitForExistence(timeout: 15),
                      "the notes thread never appeared")
        capture(app, "comments")
    }

    /// Tracking and the walk summary, driven by the synthetic walk so the
    /// figures and the progress bar have something real in them.
    func testCaptureTrackingAndSummary() {
        let app = launchApp(simulateWalk: "wukang")
        waitForMap(app)

        element(app, "record-button").tap()
        XCTAssertTrue(element(app, "elapsed-clock").waitForExistence(timeout: 15),
                      "tracking never opened")
        // Long enough for the walked line and the progress fill to have grown
        // into something worth photographing.
        Thread.sleep(forTimeInterval: 6.0)
        capture(app, "tracking")

        app.buttons["end-walk-button"].tap()
        XCTAssertTrue(app.staticTexts["summary-route-name"].waitForExistence(timeout: 15),
                      "the summary never appeared")
        capture(app, "walk-summary")
        app.buttons["keep-private-button"].tap()
        waitForMap(app)
    }

    /// The builder, with a line drawn on it.
    func testCaptureBuilder() {
        let app = launchApp()
        waitForMap(app)
        app.tabBars.buttons["You"].tap()
        XCTAssertTrue(element(app, "profile-draw-route-row").waitForExistence(timeout: 15))
        element(app, "profile-draw-route-row").tap()

        let map = element(app, "builder-map")
        XCTAssertTrue(map.waitForExistence(timeout: 15), "the builder map never appeared")
        for (x, y) in [(0.30, 0.32), (0.48, 0.40), (0.64, 0.34), (0.70, 0.52), (0.46, 0.58)] {
            map.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        element(app, "builder-tag-green").tap()
        Thread.sleep(forTimeInterval: 0.5)
        capture(app, "builder")
    }

    /// Both feed tabs, then Saved, then the profile with figures in it.
    func testCaptureFeedSavedAndProfile() {
        let app = launchApp(simulateWalk: "wukang")
        waitForMap(app)

        // A walk first, so the profile's figures and chart are not the empty
        // state — the empty state is already covered by ProfileUITests.
        element(app, "record-button").tap()
        XCTAssertTrue(element(app, "elapsed-clock").waitForExistence(timeout: 15))
        Thread.sleep(forTimeInterval: 5.0)
        app.buttons["end-walk-button"].tap()
        XCTAssertTrue(app.staticTexts["summary-route-name"].waitForExistence(timeout: 15))
        app.buttons["post-to-feed-button"].tap()
        waitForMap(app)

        app.tabBars.buttons["Community"].tap()
        XCTAssertTrue(element(app, "feed-tab-friends").waitForExistence(timeout: 15),
                      "the feed never appeared")
        capture(app, "feed-friends")

        element(app, "feed-tab-creators").tap()
        Thread.sleep(forTimeInterval: 1.2)
        capture(app, "feed-creators")

        app.tabBars.buttons["Saved"].tap()
        XCTAssertTrue(element(app, "saved-count").waitForExistence(timeout: 15),
                      "the Saved screen never appeared")
        capture(app, "saved")

        app.tabBars.buttons["You"].tap()
        XCTAssertTrue(element(app, "profile-walk-count").waitForExistence(timeout: 15),
                      "the profile never appeared")
        capture(app, "profile")
    }
}
