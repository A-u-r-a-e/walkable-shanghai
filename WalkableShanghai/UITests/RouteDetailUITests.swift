import XCTest

/// Phase 3's acceptance tests: route detail carries the right route in both
/// languages, the two toggles work *and survive a relaunch*, the map filter
/// reflects a bookmark immediately, and Featured opens its route.
///
/// The relaunch tests are the point of this phase. Everything else here would
/// have passed against Phase 2's in-memory set; only persistence proves
/// SwiftData is actually doing its job.
final class RouteDetailUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// - Parameter resetUserState: pass `false` to relaunch *without* wiping
    ///   saved/offline flags — that is how the persistence tests read back what
    ///   the previous launch wrote.
    private func launchApp(
        language: String = "english",
        resetUserState: Bool = true
    ) -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = [
            "-settings.language", language,
            "-settings.hasSeenOnboarding", "YES",
        ]
        if resetUserState {
            arguments.append("-uitest.resetUserState")
        }
        app.launchArguments = arguments
        app.launch()
        return app
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func waitForMap(_ app: XCUIApplication) {
        XCTAssertTrue(
            app.staticTexts["routes-in-view-count"].waitForExistence(timeout: 15),
            "the map screen never appeared"
        )
        Thread.sleep(forTimeInterval: 2.0)
    }


    /// Makes a route row reachable before tapping it.
    ///
    /// The peeking sheet shows as many rows as the screen has room for, and how
    /// many that is depends on the OS: iOS 26 draws its floating tab bar *over*
    /// the sheet, while iOS 18's opaque tab bar takes layout space, so two fewer
    /// rows fit in the peek. A row below the fold still "exists", and tapping it
    /// lands on whatever covers it — which is why this expands the sheet instead
    /// of trusting the fold.
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

    /// Opens a route from the map list and waits for its detail screen.
    @discardableResult
    private func openRoute(_ app: XCUIApplication, _ routeId: String) -> XCUIElement {
        let row = revealRouteRow(app, routeId)
        // Let the sheet finish settling before tapping: tapping the instant the
        // row becomes reachable can race the layout and fail to resolve its
        // snapshot.
        Thread.sleep(forTimeInterval: 0.6)
        row.tap()
        let name = app.staticTexts["route-detail-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10), "route detail never appeared for \(routeId)")
        // The bookmark lives in an overlay over the map, which settles a beat
        // after the title. Waiting for it here keeps every caller from having
        // to guess a sleep long enough.
        XCTAssertTrue(
            element(app, "save-toggle").waitForExistence(timeout: 10),
            "the save toggle never appeared for \(routeId)"
        )
        Thread.sleep(forTimeInterval: 1.5)
        return name
    }

    // MARK: - Detail content

    func testEveryRouteOpensItsOwnDetail() {
        let app = launchApp()
        waitForMap(app)

        let expected: [(id: String, name: String, km: String, area: String)] = [
            ("wukang", "Wukang Road & the Concession Lanes", "3.4", "Xuhui"),
            ("creek", "Suzhou Creek, East Bank", "4.8", "Hongkou"),
            ("fuxing", "Fuxing Park to Xintiandi", "2.1", "Huangpu"),
            ("bund", "The Bund to Yuyuan", "2.9", "Huangpu"),
            ("century", "Century Park Outer Loop", "5.6", "Pudong"),
        ]

        for route in expected {
            let name = openRoute(app, route.id)
            XCTAssertEqual(name.label, route.name, "wrong route opened for \(route.id)")
            // Its own figures and its own area tag, not the previous route's.
            XCTAssertTrue(app.staticTexts[route.km].exists, "\(route.id) is missing its distance")
            XCTAssertTrue(app.staticTexts[route.area].exists, "\(route.id) is missing its area tag")
            XCTAssertTrue(app.buttons["start-walking-button"].exists)
            XCTAssertTrue(app.buttons["notes-button"].exists)

            if route.id == "wukang" {
                capture(app, "20-route-detail-en")

                // Both bottom buttons must be reachable, not merely present —
                // the floating tab bar draws over this scroll view, and an
                // `exists` check would pass on a button buried underneath it.
                app.swipeUp()
                Thread.sleep(forTimeInterval: 1.0)
                XCTAssertTrue(
                    app.buttons["start-walking-button"].isHittable,
                    "Start walking cannot be tapped - it is under the tab bar"
                )
                XCTAssertTrue(
                    app.buttons["notes-button"].isHittable,
                    "Notes from walkers cannot be tapped - it is under the tab bar"
                )
                capture(app, "26-route-detail-scrolled-en")
            }
            element(app, "route-back-button").tap()
            waitForMap(app)
        }
    }

    func testRouteDetailReadsInChinese() {
        let app = launchApp(language: "chinese")
        waitForMap(app)

        let name = openRoute(app, "wukang")
        XCTAssertEqual(name.label, "武康路与法租界弄堂")
        XCTAssertTrue(app.staticTexts["徐汇"].exists, "the area tag is not in Chinese")
        XCTAssertTrue(app.buttons["开始步行"].exists, "the primary button is not in Chinese")
        // wukang is seeded offline, so its toggle reads "Offline ready".
        XCTAssertTrue(app.staticTexts["离线可用"].exists, "the offline toggle is not in Chinese")
        capture(app, "21-route-detail-zh")
    }

    // MARK: - Save and offline, and that they persist

    func testBookmarkTogglesAndSurvivesRelaunch() {
        let app = launchApp()
        waitForMap(app)

        // "bund" starts unsaved in the seed.
        openRoute(app, "bund")
        let toggle = element(app, "save-toggle")
        XCTAssertEqual(toggle.label, "Save route", "the Bund should start unsaved")

        toggle.tap()
        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertEqual(toggle.label, "Remove from saved", "the bookmark did not fill")
        capture(app, "22-route-detail-saved-en")

        // Relaunch WITHOUT resetting. This is what SwiftData buys.
        let relaunched = launchApp(resetUserState: false)
        waitForMap(relaunched)
        openRoute(relaunched, "bund")
        XCTAssertEqual(
            element(relaunched, "save-toggle").label, "Remove from saved",
            "the bookmark did not survive a relaunch"
        )

        // And unsetting it persists too, so the test leaves no residue.
        element(relaunched, "save-toggle").tap()
        Thread.sleep(forTimeInterval: 1.0)

        let third = launchApp(resetUserState: false)
        waitForMap(third)
        openRoute(third, "bund")
        XCTAssertEqual(
            element(third, "save-toggle").label, "Save route",
            "un-saving did not survive a relaunch"
        )
    }

    func testOfflineTogglesAndSurvivesRelaunch() {
        let app = launchApp()
        waitForMap(app)

        // "creek" starts saved but not offline in the seed.
        openRoute(app, "creek")
        XCTAssertTrue(app.staticTexts["Download"].exists, "the creek should start not-downloaded")

        element(app, "offline-toggle").tap()
        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertTrue(app.staticTexts["Offline ready"].exists, "the label did not flip to Offline ready")
        XCTAssertFalse(app.staticTexts["Download"].exists)

        let relaunched = launchApp(resetUserState: false)
        waitForMap(relaunched)
        openRoute(relaunched, "creek")
        XCTAssertTrue(
            relaunched.staticTexts["Offline ready"].exists,
            "the offline flag did not survive a relaunch"
        )
    }

    func testSeededOfflineStateIsPresent() {
        let app = launchApp()
        waitForMap(app)
        // "fuxing" is seeded offline but not saved — the two flags are
        // independent, and this is the route that proves it.
        openRoute(app, "fuxing")
        XCTAssertTrue(app.staticTexts["Offline ready"].exists, "fuxing should be seeded offline")
        XCTAssertEqual(element(app, "save-toggle").label, "Save route", "fuxing should not be seeded saved")
    }

    // MARK: - The map filter reflects a bookmark straight away

    func testSavedFilterReflectsANewBookmarkImmediately() {
        let app = launchApp()
        waitForMap(app)

        element(app, "map-filter-saved").tap()
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertEqual(app.staticTexts["routes-in-view-count"].label, "3")
        XCTAssertFalse(app.buttons["route-row-bund"].exists)

        // Save the Bund from its detail screen, come back, and the filter that
        // is still set to Saved should already include it.
        element(app, "map-filter-featured").tap()
        Thread.sleep(forTimeInterval: 1.0)
        openRoute(app, "bund")
        element(app, "save-toggle").tap()
        Thread.sleep(forTimeInterval: 1.0)
        element(app, "route-back-button").tap()
        waitForMap(app)

        element(app, "map-filter-saved").tap()
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertEqual(
            app.staticTexts["routes-in-view-count"].label, "4",
            "the Saved filter did not pick up the new bookmark"
        )
        XCTAssertTrue(app.buttons["route-row-bund"].exists, "the Bund should now be in Saved")
        capture(app, "23-saved-filter-after-bookmark-en")
    }

    // MARK: - Featured

    func testFeaturedShowsWukangAndOpensIt() {
        let app = launchApp()
        waitForMap(app)

        element(app, "featured-banner").tap()
        XCTAssertTrue(app.staticTexts["featured-title"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1.0)

        XCTAssertEqual(app.staticTexts["featured-title"].label, "Featured this month")
        XCTAssertEqual(
            app.staticTexts["featured-route-name"].label, "Wukang Road & the Concession Lanes",
            "Featured should be driven by the isFeatured flag, which wukang carries"
        )
        XCTAssertTrue(app.staticTexts["August 2026"].exists)
        XCTAssertTrue(app.staticTexts["Curated by 张沁 · 14 walkers this month"].exists)
        capture(app, "24-featured-en")

        app.buttons["open-featured-route"].tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 10))
        XCTAssertEqual(
            app.staticTexts["route-detail-name"].label, "Wukang Road & the Concession Lanes",
            "Open the route did not open the featured route"
        )
    }

    func testFeaturedReadsInChinese() {
        let app = launchApp(language: "chinese")
        waitForMap(app)

        element(app, "featured-banner").tap()
        XCTAssertTrue(app.staticTexts["featured-title"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1.0)

        XCTAssertEqual(app.staticTexts["featured-title"].label, "本月精选路线")
        XCTAssertEqual(app.staticTexts["featured-route-name"].label, "武康路与法租界弄堂")
        XCTAssertTrue(app.staticTexts["二〇二六年八月"].exists)
        XCTAssertTrue(app.buttons["查看路线"].exists)
        capture(app, "25-featured-zh")
    }
    /// Share was left unwired through seven phases — a control that looks like
    /// a control and does nothing. It now opens the system share sheet carrying
    /// the route's name and figures; the wording itself is checked in
    /// `ProfileTests.testTheShareMessageCarriesTheRouteAndItsFigures`.
    func testShareOpensTheSystemShareSheet() {
        let app = launchApp()
        waitForMap(app)
        openRoute(app, "wukang")
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.8)

        let share = element(app, "share-button")
        XCTAssertTrue(share.isHittable, "the share control cannot be reached")
        share.tap()

        // The share sheet is a system view, so assert on what it always offers
        // for text rather than on its internal structure.
        let copy = app.buttons["Copy"]
        let activityView = app.otherElements["ActivityListView"]
        let appeared = copy.waitForExistence(timeout: 10) || activityView.exists
        XCTAssertTrue(appeared, "tapping Share did not open a share sheet")
        capture(app, "27-share-sheet-en")
    }

}
