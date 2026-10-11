import XCTest

/// Phase 5's acceptance tests: the end-to-end walk (track → end → summary →
/// save → still there after relaunch), and drawing a route by hand.
@MainActor
final class SummaryAndBuilderUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// The seeded map, with a simulated walk along `simulateWalk` if given.
    private func launchApp(
        language: String = "english",
        simulateWalk: String? = nil,
        resetUserState: Bool = true
    ) -> XCUIApplication {
        let app = launchWalkable(
            language: language,
            resetState: resetUserState,
            arguments: simulateWalk.map { ["-uitest.simulateWalk", $0] } ?? []
        )
        // Let the map settle before the first tap.
        Thread.sleep(forTimeInterval: 1.0)
        return app
    }

    /// Me tab, then the profile row.
    private func openProfile(_ app: XCUIApplication) {
        app.tabBars.buttons["Me"].tap()
        anyElement(app, "me-profile-row").tap()
    }

    /// Map → Routes dropdown → Mine → New route.
    private func openBuilder(_ app: XCUIApplication, mine: String = "Mine") {
        chooseRoutesOption(app, mine)
        let newRoute = anyElement(app, "new-route-button")
        XCTAssertTrue(newRoute.waitForExistence(timeout: 5), "Mine offers no New route")
        newRoute.tap()
    }

    /// The row of the one drawn route, whatever id it was given.
    private func drawnRouteRow(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'route-row-draft-'")).firstMatch
    }

    // MARK: - The whole walk, end to end

    func testTrackEndSummarySaveAndItSurvivesRelaunch() {
        let app = launchApp(simulateWalk: "wukang")

        // Track.
        revealRow(app, "wukang").tap()
        let begin = anyElement(app, "start-walking-button")
        XCTAssertTrue(begin.waitForExistence(timeout: 5), "the route card has no Begin route")
        begin.tap()
        XCTAssertTrue(anyElement(app, "elapsed-clock").waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 5.0)

        let distanceOnTracker = app.staticTexts["progress-percent"].label

        // End.
        app.buttons["end-walk-button"].tap()
        XCTAssertTrue(app.staticTexts["summary-route-name"].waitForExistence(timeout: 10),
                      "End walk did not reach the summary")
        Thread.sleep(forTimeInterval: 1.0)

        // The summary carries this walk's own figures, not placeholders.
        XCTAssertEqual(app.staticTexts["summary-route-name"].label, "Wukang Road & the Concession Lanes")
        XCTAssertTrue(app.staticTexts["Walk complete"].exists)
        XCTAssertTrue(anyElement(app, "summary-date-line").exists)
        XCTAssertTrue(app.staticTexts["km walked"].exists)
        XCTAssertTrue(app.staticTexts["moving time"].exists)
        XCTAssertTrue(app.staticTexts["min / km"].exists)
        XCTAssertTrue(app.staticTexts["km over your best"].exists)
        // First ever walk: nothing to beat, so an em dash rather than a number.
        XCTAssertTrue(app.staticTexts["—"].exists,
                      "the first walk should not claim to beat a personal best")
        _ = distanceOnTracker
        attachScreenshot(app, "40-walk-summary-en")

        // A note, then Done.
        let note = anyElement(app, "summary-note-field")
        note.tap()
        note.typeText("Quiet before nine.")
        app.buttons["summary-done-button"].tap()

        // Back at the map's route list, not the walked route's card.
        XCTAssertTrue(anyElement(app, "routes-option-menu").waitForExistence(timeout: 10),
                      "Done did not return to the route list")
        XCTAssertFalse(anyElement(app, "route-card").exists, "the walked route's card is still open")
        XCTAssertFalse(app.staticTexts["summary-route-name"].exists, "the summary is still on screen")

        // Relaunch WITHOUT resetting: the walk must still be there. Read it
        // back through the profile's stored-walk count.
        let relaunched = launchApp(resetUserState: false)
        openProfile(relaunched)
        XCTAssertTrue(
            anyElement(relaunched, "profile-walk-count").waitForExistence(timeout: 10),
            "the profile does not report stored walks"
        )
        XCTAssertEqual(
            anyElement(relaunched, "profile-walk-count").value as? String, "1",
            "the finished walk did not survive a relaunch"
        )
        attachScreenshot(relaunched, "41-stored-walk-after-relaunch-en")
    }

    func testSummaryReadsInChinese() {
        let app = launchApp(language: "chinese", simulateWalk: "wukang")
        anyElement(app, "record-button").tap()
        XCTAssertTrue(anyElement(app, "elapsed-clock").waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 4.0)
        app.buttons["结束步行"].tap()
        XCTAssertTrue(app.staticTexts["summary-route-name"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1.0)

        XCTAssertEqual(app.staticTexts["summary-route-name"].label, "武康路与法租界弄堂")
        XCTAssertTrue(app.staticTexts["步行完成"].exists)
        XCTAssertTrue(app.staticTexts["步行距离"].exists)
        XCTAssertTrue(app.staticTexts["用时"].exists)
        XCTAssertTrue(app.staticTexts["分 / 公里"].exists)
        XCTAssertTrue(app.staticTexts["超过个人最佳"].exists)
        XCTAssertEqual(app.buttons["summary-done-button"].label, "完成")
        attachScreenshot(app, "42-walk-summary-zh")

        // A walk started from REC has no route card to return to: Done lands
        // on the Routes list.
        app.buttons["summary-done-button"].tap()
        XCTAssertTrue(anyElement(app, "routes-option-menu").waitForExistence(timeout: 10),
                      "Done did not return to the route list")
        XCTAssertFalse(anyElement(app, "route-card").exists, "a route card opened after a REC walk")
    }

    /// The photo picker is system UI, so this asserts it opens rather than
    /// driving it. That a chosen photo actually persists is covered by
    /// `WalkStoreTests.testAPhotoSurvivesTheRoundTrip`.
    func testSummaryPhotoPickerOpens() {
        let app = launchApp(simulateWalk: "wukang")
        anyElement(app, "record-button").tap()
        XCTAssertTrue(anyElement(app, "elapsed-clock").waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 2.0)
        app.buttons["end-walk-button"].tap()
        XCTAssertTrue(app.staticTexts["summary-route-name"].waitForExistence(timeout: 10))

        anyElement(app, "summary-photo-picker").tap()
        // The system picker presents its own navigation bar over our screen.
        XCTAssertTrue(
            app.navigationBars.firstMatch.waitForExistence(timeout: 10),
            "the photo picker did not open"
        )
    }

    // MARK: - The builder

    /// Taps five spread-out points on the builder map.
    private func drawFivePoints(_ app: XCUIApplication) {
        let map = anyElement(app, "builder-map")
        XCTAssertTrue(map.waitForExistence(timeout: 10), "the builder map never appeared")
        let spots: [(CGFloat, CGFloat)] = [(0.3, 0.3), (0.5, 0.35), (0.65, 0.5), (0.5, 0.65), (0.32, 0.6)]
        for (x, y) in spots {
            map.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
    }

    func testBuilderDrawsCountsUndoesAndSaves() {
        let app = launchApp()
        openBuilder(app)

        drawFivePoints(app)

        // Five points, with a distance.
        let tally = anyElement(app, "builder-tally")
        XCTAssertTrue(tally.label.hasPrefix("5 points · "), "expected 5 points, tally read \(tally.label)")
        XCTAssertFalse(tally.label.hasSuffix("0.0 km"), "five spread points should cover some distance")
        // And a dot for each, the first one filled.
        for index in 0..<5 {
            XCTAssertTrue(anyElement(app, "draft-point-\(index)").exists, "point \(index) is not on the map")
        }
        attachScreenshot(app, "43-builder-five-points-en")

        // Undo removes exactly one.
        app.buttons["builder-undo-button"].tap()
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertTrue(anyElement(app, "builder-tally").label.hasPrefix("4 points · "),
                      "Undo did not remove a point")
        XCTAssertFalse(anyElement(app, "draft-point-4").exists, "the undone point is still drawn")

        // Name it and save it. There are no tags to choose: tags are the
        // developers' fixed list.
        let name = anyElement(app, "builder-name-field")
        name.tap()
        name.typeText("Evening loop")
        attachScreenshot(app, "44-builder-named-en")
        app.buttons["builder-save-button"].tap()

        // It is in Mine, named as typed.
        let row = drawnRouteRow(app)
        XCTAssertTrue(row.waitForExistence(timeout: 10), "the drawn route did not join Mine")
        XCTAssertTrue(app.staticTexts["Evening loop"].exists, "the drawn route is not named in the list")
        attachScreenshot(app, "45-drawn-route-in-mine-en")
        let rowId = String(row.identifier.dropFirst("route-row-".count))

        // It joins the main map too: Nearby draws a pin for it.
        chooseRoutesOption(app, "Nearby")
        XCTAssertTrue(anyElement(app, "route-pin-\(rowId)").waitForExistence(timeout: 5),
                      "the drawn route has no pin on the map")

        // Its card carries the name and no tags.
        chooseRoutesOption(app, "Mine")
        revealRow(app, rowId).tap()
        XCTAssertTrue(anyElement(app, "route-card").waitForExistence(timeout: 5))
        XCTAssertEqual(anyElement(app, "route-card-title").label, "Evening loop")
        XCTAssertFalse(anyElement(app, "route-card-tags").exists, "a walker's route should carry no tags")
    }

    func testDrawnRouteSurvivesRelaunch() {
        let app = launchApp()
        openBuilder(app)
        drawFivePoints(app)
        let name = anyElement(app, "builder-name-field")
        name.tap()
        name.typeText("Morning lanes")
        app.buttons["builder-save-button"].tap()
        XCTAssertTrue(drawnRouteRow(app).waitForExistence(timeout: 10))

        let relaunched = launchApp(resetUserState: false)
        chooseRoutesOption(relaunched, "Mine")
        XCTAssertTrue(drawnRouteRow(relaunched).waitForExistence(timeout: 5),
                      "the drawn route did not survive a relaunch")
        XCTAssertTrue(relaunched.staticTexts["Morning lanes"].exists)
    }

    func testBuilderSaveIsOffUntilThereIsALine() {
        let app = launchApp()
        openBuilder(app)

        let map = anyElement(app, "builder-map")
        XCTAssertTrue(map.waitForExistence(timeout: 10))
        // Nothing drawn: neither button should do anything.
        XCTAssertFalse(app.buttons["builder-save-button"].isEnabled, "Save was on with no points")
        XCTAssertFalse(app.buttons["builder-undo-button"].isEnabled, "Undo was on with no points")

        map.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.4)).tap()
        Thread.sleep(forTimeInterval: 0.6)
        // One point is not a line.
        XCTAssertFalse(app.buttons["builder-save-button"].isEnabled, "Save was on with a single point")
        XCTAssertTrue(app.buttons["builder-undo-button"].isEnabled)

        map.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.55)).tap()
        Thread.sleep(forTimeInterval: 0.6)
        XCTAssertTrue(app.buttons["builder-save-button"].isEnabled, "Save should be on with two points")
    }

    func testBuilderReadsInChinese() {
        let app = launchApp(language: "chinese")
        openBuilder(app, mine: "我的")

        XCTAssertTrue(anyElement(app, "builder-map").waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["点击地图添加节点"].exists)
        XCTAssertTrue(app.staticTexts["新建路线"].exists)
        XCTAssertTrue(app.buttons["撤销节点"].exists)
        XCTAssertTrue(app.buttons["保存路线"].exists)

        drawFivePoints(app)
        XCTAssertTrue(anyElement(app, "builder-tally").label.hasPrefix("5 个节点 · "),
                      "the tally is not in Chinese: \(anyElement(app, "builder-tally").label)")
        attachScreenshot(app, "46-builder-five-points-zh")
    }

    func testBuilderOpensFromOnboarding() {
        let app = XCUIApplication()
        // Explicitly NO: a previous test in this run will have left
        // hasSeenOnboarding set, and then onboarding never appears.
        app.launchArguments = [
            "-settings.language", "english",
            "-settings.hasSeenOnboarding", "NO",
            "-uitest.resetUserState",
        ]
        app.launch()

        // "I have a route to share" is onboarding's second button.
        XCTAssertTrue(app.buttons["I have a route to share"].waitForExistence(timeout: 15))
        app.buttons["I have a route to share"].tap()
        XCTAssertTrue(anyElement(app, "builder-map").waitForExistence(timeout: 10),
                      "onboarding did not reach the builder")
        XCTAssertTrue(app.staticTexts["New route"].exists)
    }
}
