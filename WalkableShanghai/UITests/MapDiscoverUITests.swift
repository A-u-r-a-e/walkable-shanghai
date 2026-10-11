import XCTest

/// Phase 2's acceptance tests: the map screen shows the routes, the sheet
/// opens and closes, the filters narrow what is listed, and both ways of
/// picking a route reach the same place with the same identity.
final class MapDiscoverUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches straight into the tab shell, past onboarding, in the language
    /// asked for. Launch arguments land in UserDefaults' argument domain, which
    /// outranks anything a previous run persisted.
    private func launchApp(language: String = "english") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-settings.language", language,
            "-settings.hasSeenOnboarding", "YES",
        ]
        app.launch()
        return app
    }

    /// Finds an element by identifier regardless of what element type it
    /// surfaces as. A custom `MKAnnotationView` does not reliably report as
    /// `.other` or `.button`, so pinning the query to one type is brittle.
    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// Waits for the map to actually draw tiles and overlays before a
    /// screenshot. MapKit loads asynchronously and a shot taken too early is a
    /// grey rectangle.
    private func settleMap(_ app: XCUIApplication) {
        XCTAssertTrue(
            app.otherElements["routes-in-view-count"].waitForExistence(timeout: 10)
                || app.staticTexts["routes-in-view-count"].waitForExistence(timeout: 10),
            "the route sheet never appeared"
        )
        Thread.sleep(forTimeInterval: 3.5)
    }

    // MARK: - Map, pins and the sheet

    func testMapShowsEveryRouteWithPinsAndList() {
        let app = launchApp()
        settleMap(app)

        // All five routes are listed...
        XCTAssertEqual(app.staticTexts["routes-in-view-count"].label, "5")

        // ...and each has a pin on the map.
        for number in 1...5 {
            XCTAssertTrue(
                element(app, "route-pin-\(number)").exists,
                "route pin \(number) is missing from the map"
            )
        }

        XCTAssertTrue(app.buttons["route-row-wukang"].exists)
        XCTAssertTrue(app.staticTexts["Routes in view"].exists)
        XCTAssertTrue(app.buttons["record-button"].exists)
        XCTAssertTrue(element(app, "map-search-field").exists)

        capture(app, "10-map-discover-peek-en")
    }

    func testSheetExpandsAndCollapses() {
        let app = launchApp()
        settleMap(app)

        let handle = element(app, "sheet-handle")
        XCTAssertTrue(handle.exists, "the sheet handle is missing")

        let lastRow = app.buttons["route-row-century"]
        let peekFrame = app.buttons["route-row-wukang"].frame

        // Drag the handle up to the full detent.
        handle.press(forDuration: 0.05, thenDragTo: element(app, "map-search-field"))
        Thread.sleep(forTimeInterval: 1.2)

        let expandedFrame = app.buttons["route-row-wukang"].frame
        XCTAssertLessThan(
            expandedFrame.minY, peekFrame.minY - 40,
            "dragging the handle up did not expand the sheet"
        )
        XCTAssertTrue(lastRow.exists, "the last route should be reachable once expanded")
        capture(app, "11-map-sheet-full-en")

        // Tapping the handle collapses it again.
        handle.tap()
        Thread.sleep(forTimeInterval: 1.2)
        let collapsedFrame = app.buttons["route-row-wukang"].frame
        XCTAssertGreaterThan(
            collapsedFrame.minY, expandedFrame.minY + 40,
            "tapping the handle did not collapse the sheet"
        )
    }

    // MARK: - Filters

    func testSavedFilterNarrowsListAndPins() {
        let app = launchApp()
        settleMap(app)

        XCTAssertEqual(app.staticTexts["routes-in-view-count"].label, "5")
        XCTAssertTrue(element(app, "route-pin-4").exists, "the Bund pin should be on the unfiltered map")

        element(app, "map-filter-saved").tap()
        Thread.sleep(forTimeInterval: 2.5)

        // Seeded saved set is wukang, creek, century — three routes.
        XCTAssertEqual(app.staticTexts["routes-in-view-count"].label, "3", "Saved did not narrow the count")
        XCTAssertTrue(app.buttons["route-row-wukang"].exists)
        XCTAssertTrue(app.buttons["route-row-creek"].exists)
        XCTAssertTrue(app.buttons["route-row-century"].exists)
        XCTAssertFalse(app.buttons["route-row-bund"].exists, "the Bund is not saved and should be gone")
        XCTAssertFalse(app.buttons["route-row-fuxing"].exists, "Fuxing Park is not saved and should be gone")

        // The pins narrow with the list — the map and the sheet agree.
        XCTAssertFalse(element(app, "route-pin-4").exists, "the Bund pin should be gone from the map")
        XCTAssertFalse(element(app, "route-pin-3").exists, "the Fuxing pin should be gone from the map")
        XCTAssertTrue(element(app, "route-pin-1").exists)

        capture(app, "12-map-filter-saved-en")

        // Featured restores everything.
        element(app, "map-filter-featured").tap()
        Thread.sleep(forTimeInterval: 2.0)
        XCTAssertEqual(app.staticTexts["routes-in-view-count"].label, "5", "Featured did not restore the full list")
    }

    func testNearbyFilterSelectsAndKeepsEveryRoute() {
        let app = launchApp()
        settleMap(app)

        element(app, "map-filter-nearby").tap()
        Thread.sleep(forTimeInterval: 1.5)

        // Nearby has no distance logic yet — PLAN.md excludes it from this
        // phase — so it selects but does not narrow. Asserted so the day it
        // starts filtering, this test is what says so.
        XCTAssertEqual(app.staticTexts["routes-in-view-count"].label, "5")
    }

    // MARK: - Both routes into detail

    func testRowAndPinReachTheSameRoute() {
        let app = launchApp()
        settleMap(app)

        // Via the list row. (Phase 3 replaced the stub this used to assert
        // with the real route detail screen.)
        app.buttons["route-row-creek"].tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["route-detail-name"].label, "Suzhou Creek, East Bank")
        capture(app, "13-route-detail-from-row-en")

        element(app, "route-back-button").tap()
        settleMap(app)

        // Via the map pin. Route 2 is the same creek route.
        element(app, "route-pin-2").tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 10))
        XCTAssertEqual(
            app.staticTexts["route-detail-name"].label, "Suzhou Creek, East Bank",
            "the pin and the row must reach the same route"
        )
    }

    // MARK: - Chinese

    func testMapScreenReadsInChinese() {
        let app = launchApp(language: "chinese")
        settleMap(app)

        XCTAssertTrue(app.staticTexts["视野内路线"].exists, "the sheet heading is not in Chinese")
        XCTAssertTrue(element(app, "map-filter-featured").exists)
        XCTAssertTrue(element(app, "map-filter-nearby").exists)
        XCTAssertTrue(element(app, "map-filter-saved").exists)
        XCTAssertTrue(app.staticTexts["搜索路线或街道"].exists)
        XCTAssertEqual(app.staticTexts["routes-in-view-count"].label, "5")
        capture(app, "14-map-discover-peek-zh")

        // Filtering works the same in Chinese, and the route names switch too.
        element(app, "map-filter-saved").tap()
        Thread.sleep(forTimeInterval: 2.5)
        XCTAssertEqual(app.staticTexts["routes-in-view-count"].label, "3")
        XCTAssertTrue(app.staticTexts["苏州河东段"].exists, "route names should be in Chinese")
        capture(app, "15-map-filter-saved-zh")
    }
}
