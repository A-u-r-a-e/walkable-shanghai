import XCTest

/// Phase 8's acceptance tests: the profile's figures are computed, the chart is
/// real, the profile opens from the Me list, the language switch reaches
/// everything including the month labels, and the polish holds up — icon-only
/// controls are announced and the screen survives the largest text size.
@MainActor
final class ProfileUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// - Parameter setLanguage: when false, no language argument is passed at
    ///   all. The argument writes the stored default, so a test that claims the
    ///   walker's own choice survives a relaunch has to leave it out — otherwise
    ///   it only proves the launch argument works.
    private func launchApp(
        language: String = "english",
        simulateWalk: String? = nil,
        resetUserState: Bool = true,
        contentSizeCategory: String? = nil,
        setLanguage: Bool = true
    ) -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = ["-settings.hasSeenOnboarding", "YES"]
        if setLanguage { arguments += ["-settings.language", language] }
        if resetUserState { arguments.append("-uitest.resetUserState") }
        if let simulateWalk { arguments += ["-uitest.simulateWalk", simulateWalk] }
        if let contentSizeCategory {
            arguments += ["-UIPreferredContentSizeCategoryName", contentSizeCategory]
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
        XCTAssertTrue(element(app, "routes-option-menu").waitForExistence(timeout: 15),
                      "the map screen never appeared")
        Thread.sleep(forTimeInterval: 1.5)
    }

    private func openProfile(_ app: XCUIApplication, tabLabel: String = "Me") {
        app.tabBars.buttons[tabLabel].tap()
        // The Me tab keeps its navigation stack, so the profile may already be
        // open from an earlier visit.
        if !element(app, "profile-walk-count").exists {
            XCTAssertTrue(element(app, "me-profile-row").waitForExistence(timeout: 10),
                          "the Me list never appeared")
            element(app, "me-profile-row").tap()
        }
        XCTAssertTrue(element(app, "profile-walk-count").waitForExistence(timeout: 10),
                      "the profile never appeared")
        Thread.sleep(forTimeInterval: 1.0)
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

    /// Records one walk on the Wukang route and keeps it private, leaving the
    /// app back on the map with a stored walk behind it.
    private func recordAWalk(_ app: XCUIApplication) {
        revealRouteRow(app, "wukang").tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 10))
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.8)
        app.buttons["start-walking-button"].tap()
        XCTAssertTrue(element(app, "elapsed-clock").waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 5.0)
        app.buttons["end-walk-button"].tap()
        XCTAssertTrue(app.staticTexts["summary-route-name"].waitForExistence(timeout: 10))
        app.buttons["keep-private-button"].tap()
        waitForMap(app)
    }

    private func drawARoute(_ app: XCUIApplication, named name: String) {
        app.tabBars.buttons["Map"].tap()
        waitForMap(app)
        chooseRoutesOption(app, "Mine")
        element(app, "new-route-button").tap()
        let map = element(app, "builder-map")
        XCTAssertTrue(map.waitForExistence(timeout: 10))
        for offset in [(0.30, 0.35), (0.45, 0.45), (0.60, 0.40), (0.70, 0.55)] {
            map.coordinate(withNormalizedOffset: CGVector(dx: offset.0, dy: offset.1)).tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        let field = element(app, "builder-name-field")
        field.tap()
        field.typeText(name)
        app.buttons["builder-save-button"].tap()
        waitForMap(app)
    }

    // MARK: - The figures are computed, not hardcoded

    func testAFreshProfileReportsNothingRatherThanSomebodyElsesFigures() {
        let app = launchApp()
        waitForMap(app)
        openProfile(app)

        XCTAssertEqual(element(app, "profile-walk-count").value as? String, "0")
        XCTAssertEqual(element(app, "profile-total-km").value as? String, "0.0")
        XCTAssertEqual(element(app, "profile-routes-added").value as? String, "0")
        // No walk yet is a different fact from a walk of no distance.
        XCTAssertEqual(element(app, "profile-longest").value as? String, "\u{2014}")

        // And the chart says so rather than drawing a decorative default.
        XCTAssertTrue(element(app, "profile-range-empty").exists,
                      "an empty chart should explain itself")
        XCTAssertFalse(element(app, "profile-walk-range-chart").exists,
                       "a chart was drawn with nothing to plot")
        capture(app, "70-profile-empty-en")
    }

    func testTheFiguresMoveAfterAWalkAndAfterDrawingARoute() {
        let app = launchApp(simulateWalk: "wukang")
        waitForMap(app)
        recordAWalk(app)

        openProfile(app)
        XCTAssertEqual(element(app, "profile-walk-count").value as? String, "1",
                       "the walk did not reach the profile")
        let distance = element(app, "profile-total-km").value as? String ?? ""
        XCTAssertNotEqual(distance, "0.0", "a walk was recorded but no distance with it")
        XCTAssertEqual(element(app, "profile-longest").value as? String, distance,
                       "with one walk, the longest walk is that walk")

        // The chart replaces its empty state as soon as there is something in it.
        XCTAssertTrue(element(app, "profile-walk-range-chart").exists,
                      "the chart did not appear after a walk")
        XCTAssertFalse(element(app, "profile-range-empty").exists)

        // Drawing a route moves a different figure, and only that one.
        drawARoute(app, named: "Evening loop")
        openProfile(app)
        XCTAssertEqual(element(app, "profile-routes-added").value as? String, "1",
                       "the drawn route did not reach the profile")
        XCTAssertEqual(element(app, "profile-walk-count").value as? String, "1",
                       "drawing a route should not change the walk count")
        capture(app, "71-profile-with-stats-en")
    }

    func testTheChartCoversSixMonthsAndTheStatsSurviveRelaunch() {
        let app = launchApp(simulateWalk: "wukang")
        waitForMap(app)
        recordAWalk(app)
        openProfile(app)

        let walked = element(app, "profile-total-km").value as? String ?? ""

        // The chart announces one line per month — six of them, the last
        // carrying the walk just finished.
        let chart = element(app, "profile-walk-range-chart")
        XCTAssertTrue(chart.exists)
        let months = chart.descendants(matching: .staticText).allElementsBoundByIndex.map { $0.label }
        XCTAssertEqual(months.count, 6, "the chart should cover six months, got \(months)")
        XCTAssertTrue(months.last?.contains(walked) == true,
                      "this month's column does not carry the walk: \(months)")
        XCTAssertTrue(months.dropLast().allSatisfy { $0.hasSuffix("0.0 km") },
                      "a month with no walks should read zero: \(months)")

        // Relaunch without the reset: the figures are stored, not in memory.
        let relaunched = launchApp(resetUserState: false)
        waitForMap(relaunched)
        openProfile(relaunched)
        XCTAssertEqual(element(relaunched, "profile-walk-count").value as? String, "1",
                       "the stored walk did not survive a relaunch")
        XCTAssertEqual(element(relaunched, "profile-total-km").value as? String, walked)
    }

    // MARK: - Language

    func testChineseReachesTheFiguresTheChartAndTheMonthLabels() {
        let app = launchApp(language: "chinese", simulateWalk: "wukang")
        waitForMap(app)
        recordAWalk(app)
        openProfile(app, tabLabel: "我")

        XCTAssertTrue(app.staticTexts["次步行"].exists, "the figure labels are not in Chinese")
        XCTAssertTrue(app.staticTexts["累计公里"].exists)
        XCTAssertTrue(app.staticTexts["添加的路线"].exists)
        XCTAssertTrue(app.staticTexts["步行跨度"].exists, "the chart heading is not in Chinese")

        // The month labels follow the app's language, not the phone's.
        let months = element(app, "profile-walk-range-chart")
            .descendants(matching: .staticText).allElementsBoundByIndex.map { $0.label }
        XCTAssertEqual(months.count, 6)
        XCTAssertTrue(months.allSatisfy { $0.contains("月") },
                      "the month labels are not in Chinese: \(months)")
        XCTAssertTrue(months.allSatisfy { $0.contains("公里") },
                      "the chart's units are not in Chinese: \(months)")
        capture(app, "72-profile-with-stats-zh")
    }

    func testTheLanguageChoiceSurvivesRelaunch() {
        let app = launchApp()
        waitForMap(app)
        app.tabBars.buttons["Me"].tap()

        element(app, "me-language-picker").tap()
        app.buttons["中文"].tap()
        XCTAssertTrue(app.tabBars.buttons["我"].waitForExistence(timeout: 3),
                      "the switch did not change the screen")

        // Relaunch without the reset. The language is a stored choice, so it
        // has to come back on its own.
        let relaunched = launchApp(resetUserState: false, setLanguage: false)
        waitForMap(relaunched)
        XCTAssertTrue(relaunched.tabBars.buttons["我"].exists,
                      "the language choice did not survive a relaunch")

        // Put it back, so the next launch of the shared simulator starts clean.
        relaunched.tabBars.buttons["我"].tap()
        element(relaunched, "me-language-picker").tap()
        relaunched.buttons["English"].tap()
        XCTAssertTrue(relaunched.tabBars.buttons["Me"].waitForExistence(timeout: 3))
    }

    // MARK: - Polish

    /// Every control that is only an icon has to say what it does. A screen
    /// reader gets nothing from "chevron.left".
    func testIconOnlyControlsAreAnnounced() {
        let app = launchApp()
        waitForMap(app)

        // The map's record button.
        XCTAssertEqual(element(app, "record-button").label, "Start recording a walk")
        XCTAssertEqual(element(app, "sheet-handle").label, "Expand or collapse the route list")

        // Route detail's floating back and bookmark, whose label states what
        // tapping will do rather than naming the icon.
        revealRouteRow(app, "bund").tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 10))
        XCTAssertEqual(element(app, "route-back-button").label, "Back")
        XCTAssertEqual(element(app, "save-toggle").label, "Save route")
        element(app, "save-toggle").tap()
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertEqual(element(app, "save-toggle").label, "Remove from saved",
                       "the bookmark's label does not follow its state")
        element(app, "route-back-button").tap()

        // The feed's like button.
        app.tabBars.buttons["Community"].tap()
        Thread.sleep(forTimeInterval: 1.5)
        let like = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'feed-like-'"))
            .firstMatch
        XCTAssertTrue(like.waitForExistence(timeout: 10))
        XCTAssertEqual(like.label, "Like")
    }

    /// A list with nothing in it must say so. A route you drew this morning has
    /// no notes from anyone, which is the one empty state a walker reaches
    /// without having to empty something first.
    func testAnEmptyListExplainsItselfRatherThanShowingABlankPage() {
        let app = launchApp()
        waitForMap(app)
        drawARoute(app, named: "Evening loop")

        element(app, "sheet-handle").tap()
        Thread.sleep(forTimeInterval: 1.2)
        // The drawn route is the sixth, so it sits at the bottom of the list
        // even with the sheet open. Scroll it into reach rather than assuming
        // the fold — see `revealRouteRow` for why that assumption is fragile.
        let drawn = app.staticTexts["Evening loop"]
        // Swipe the sheet's own list. `app.swipeUp()` starts from the middle of
        // the screen, which is the map — it pans Shanghai and leaves the list
        // exactly where it was.
        for _ in 0..<4 where !drawn.isHittable {
            app.scrollViews.firstMatch.swipeUp()
            Thread.sleep(forTimeInterval: 0.6)
        }
        XCTAssertTrue(drawn.isHittable, "the drawn route is not reachable in the list")
        drawn.tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 10))

        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertTrue(app.buttons["Notes from walkers (0)"].exists,
                      "a route nobody has written about should say zero")
        app.buttons["notes-button"].tap()

        XCTAssertTrue(element(app, "comments-empty").waitForExistence(timeout: 10),
                      "an empty thread showed a blank page instead of explaining itself")
        capture(app, "75-empty-notes-en")
    }

    /// The largest accessibility text size is the one that breaks layouts. The
    /// figures must still be readable.
    func testTheProfileHoldsUpAtTheLargestTextSize() {
        let app = launchApp(
            simulateWalk: "wukang",
            contentSizeCategory: "UICTContentSizeCategoryAccessibilityXXXL"
        )
        waitForMap(app)
        recordAWalk(app)
        openProfile(app)

        // The figures are still there and still say the right thing — nothing
        // has been truncated into a different number.
        XCTAssertEqual(element(app, "profile-walk-count").value as? String, "1")
        XCTAssertEqual(element(app, "profile-routes-added").value as? String, "0")
        capture(app, "73-profile-largest-text-en")
    }
}
