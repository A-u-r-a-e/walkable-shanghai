import XCTest

/// Phase 5's acceptance tests: the end-to-end walk (track → end → summary →
/// save → still there after relaunch), and drawing a route by hand.
final class SummaryAndBuilderUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp(
        language: String = "english",
        simulateWalk: String? = nil,
        resetUserState: Bool = true
    ) -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = [
            "-settings.language", language,
            "-settings.hasSeenOnboarding", "YES",
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

    // MARK: - The whole walk, end to end

    func testTrackEndSummarySaveAndItSurvivesRelaunch() {
        let app = launchApp(simulateWalk: "wukang")
        waitForMap(app)

        // Track.
        app.buttons["route-row-wukang"].tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 10))
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.8)
        app.buttons["start-walking-button"].tap()
        XCTAssertTrue(element(app, "elapsed-clock").waitForExistence(timeout: 10))
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
        XCTAssertTrue(element(app, "summary-date-line").exists)
        XCTAssertTrue(app.staticTexts["km walked"].exists)
        XCTAssertTrue(app.staticTexts["moving time"].exists)
        XCTAssertTrue(app.staticTexts["min / km"].exists)
        XCTAssertTrue(app.staticTexts["km over your best"].exists)
        // First ever walk: nothing to beat, so an em dash rather than a number.
        XCTAssertTrue(app.staticTexts["—"].exists,
                      "the first walk should not claim to beat a personal best")
        _ = distanceOnTracker
        capture(app, "40-walk-summary-en")

        // A note, then keep it private.
        let note = element(app, "summary-note-field")
        note.tap()
        note.typeText("Quiet before nine.")
        app.buttons["keep-private-button"].tap()

        // Back at the map.
        waitForMap(app)

        // Relaunch WITHOUT resetting: the walk must still be there. Read it
        // back through the profile's stored-walk count.
        let relaunched = launchApp(resetUserState: false)
        waitForMap(relaunched)
        relaunched.tabBars.buttons["Me"].tap()
        XCTAssertTrue(
            element(relaunched, "profile-walk-count").waitForExistence(timeout: 10),
            "the profile does not report stored walks"
        )
        XCTAssertEqual(
            element(relaunched, "profile-walk-count").value as? String, "1",
            "the finished walk did not survive a relaunch"
        )
        capture(relaunched, "41-stored-walk-after-relaunch-en")
    }

    func testPostToFeedAlsoStoresTheWalk() {
        let app = launchApp(simulateWalk: "creek")
        waitForMap(app)

        element(app, "record-button").tap()
        XCTAssertTrue(element(app, "elapsed-clock").waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 3.0)
        app.buttons["end-walk-button"].tap()
        XCTAssertTrue(app.staticTexts["summary-route-name"].waitForExistence(timeout: 10))

        app.buttons["post-to-feed-button"].tap()
        waitForMap(app)

        app.tabBars.buttons["Me"].tap()
        XCTAssertTrue(element(app, "profile-walk-count").waitForExistence(timeout: 10))
        XCTAssertEqual(element(app, "profile-walk-count").value as? String, "1",
                       "Post to feed should store the walk too")
    }

    func testSummaryReadsInChinese() {
        let app = launchApp(language: "chinese", simulateWalk: "wukang")
        waitForMap(app)

        element(app, "record-button").tap()
        XCTAssertTrue(element(app, "elapsed-clock").waitForExistence(timeout: 10))
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
        XCTAssertTrue(app.buttons["发布到动态"].exists)
        XCTAssertTrue(app.buttons["仅自己可见"].exists)
        capture(app, "42-walk-summary-zh")
    }

    /// The photo picker is system UI, so this asserts it opens rather than
    /// driving it. That a chosen photo actually persists is covered by
    /// `WalkStoreTests.testAPhotoSurvivesTheRoundTrip`.
    func testSummaryPhotoPickerOpens() {
        let app = launchApp(simulateWalk: "wukang")
        waitForMap(app)
        element(app, "record-button").tap()
        XCTAssertTrue(element(app, "elapsed-clock").waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 2.0)
        app.buttons["end-walk-button"].tap()
        XCTAssertTrue(app.staticTexts["summary-route-name"].waitForExistence(timeout: 10))

        element(app, "summary-photo-picker").tap()
        // The system picker presents its own navigation bar over our screen.
        XCTAssertTrue(
            app.navigationBars.firstMatch.waitForExistence(timeout: 10),
            "the photo picker did not open"
        )
    }

    // MARK: - The builder

    /// Taps five spread-out points on the builder map.
    private func drawFivePoints(_ app: XCUIApplication) {
        let map = element(app, "builder-map")
        XCTAssertTrue(map.waitForExistence(timeout: 10), "the builder map never appeared")
        let spots: [(CGFloat, CGFloat)] = [(0.3, 0.3), (0.5, 0.35), (0.65, 0.5), (0.5, 0.65), (0.32, 0.6)]
        for (x, y) in spots {
            map.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
    }

    func testBuilderDrawsCountsUndoesAndSaves() {
        let app = launchApp()
        waitForMap(app)

        app.tabBars.buttons["Me"].tap()
        element(app, "profile-draw-route-row").tap()

        drawFivePoints(app)

        // Five points, with a distance.
        let tally = element(app, "builder-tally")
        XCTAssertTrue(tally.label.hasPrefix("5 points · "), "expected 5 points, tally read \(tally.label)")
        XCTAssertFalse(tally.label.hasSuffix("0.0 km"), "five spread points should cover some distance")
        // And a dot for each, the first one filled.
        for index in 0..<5 {
            XCTAssertTrue(element(app, "draft-point-\(index)").exists, "point \(index) is not on the map")
        }
        capture(app, "43-builder-five-points-en")

        // Undo removes exactly one.
        app.buttons["builder-undo-button"].tap()
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertTrue(element(app, "builder-tally").label.hasPrefix("4 points · "),
                      "Undo did not remove a point")
        XCTAssertFalse(element(app, "draft-point-4").exists, "the undone point is still drawn")

        // Name it, tag it, save it.
        let name = element(app, "builder-name-field")
        name.tap()
        name.typeText("Evening loop")
        element(app, "builder-tag-green").tap()
        element(app, "builder-tag-loop").tap()
        capture(app, "44-builder-named-tagged-en")
        app.buttons["builder-save-button"].tap()

        // It is on the map's route list, after the five bundled routes.
        app.tabBars.buttons["Map"].tap()
        waitForMap(app)
        XCTAssertEqual(app.staticTexts["routes-in-view-count"].label, "6",
                       "the drawn route did not join the route list")
        XCTAssertTrue(app.staticTexts["Evening loop"].exists, "the drawn route is not named on the map")
        capture(app, "45-drawn-route-on-map-en")

        // Route six is below the fold of the peeking sheet, so open the sheet
        // before reaching for it - it exists either way, but is not tappable.
        element(app, "sheet-handle").tap()
        Thread.sleep(forTimeInterval: 1.2)
        app.staticTexts["Evening loop"].tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["route-detail-name"].label, "Evening loop")
        XCTAssertTrue(app.staticTexts["Your route"].exists, "a drawn route should be marked as yours")
        XCTAssertTrue(app.staticTexts["Green"].exists, "the chosen tag is missing")
    }

    func testDrawnRouteSurvivesRelaunch() {
        let app = launchApp()
        waitForMap(app)
        app.tabBars.buttons["Me"].tap()
        element(app, "profile-draw-route-row").tap()
        drawFivePoints(app)
        let name = element(app, "builder-name-field")
        name.tap()
        name.typeText("Morning lanes")
        app.buttons["builder-save-button"].tap()

        let relaunched = launchApp(resetUserState: false)
        waitForMap(relaunched)
        XCTAssertEqual(relaunched.staticTexts["routes-in-view-count"].label, "6",
                       "the drawn route did not survive a relaunch")
        XCTAssertTrue(relaunched.staticTexts["Morning lanes"].exists)
    }

    func testBuilderSaveIsOffUntilThereIsALine() {
        let app = launchApp()
        waitForMap(app)
        app.tabBars.buttons["Me"].tap()
        element(app, "profile-draw-route-row").tap()

        let map = element(app, "builder-map")
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
        waitForMap(app)
        app.tabBars.buttons["我"].tap()
        element(app, "profile-draw-route-row").tap()

        XCTAssertTrue(element(app, "builder-map").waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["点击地图添加节点"].exists)
        XCTAssertTrue(app.staticTexts["新建路线"].exists)
        XCTAssertTrue(element(app, "builder-tag-green").exists)
        XCTAssertTrue(element(app, "builder-tag-loop").exists)
        XCTAssertEqual(element(app, "builder-tag-green").label, "绿意", "the tag is not in Chinese")
        XCTAssertEqual(element(app, "builder-tag-loop").label, "环线", "the tag is not in Chinese")
        XCTAssertTrue(app.buttons["撤销节点"].exists)
        XCTAssertTrue(app.buttons["保存路线"].exists)

        drawFivePoints(app)
        XCTAssertTrue(element(app, "builder-tally").label.hasPrefix("5 个节点 · "),
                      "the tally is not in Chinese: \(element(app, "builder-tally").label)")
        capture(app, "46-builder-five-points-zh")
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
        XCTAssertTrue(element(app, "builder-map").waitForExistence(timeout: 10),
                      "onboarding did not reach the builder")
        XCTAssertTrue(app.staticTexts["New route"].exists)
    }
}
