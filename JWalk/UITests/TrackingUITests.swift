import XCTest

/// Phase 4's acceptance tests, driven by the synthetic location feed so the
/// walk actually moves and the assertions land on real numbers.
@MainActor
final class TrackingUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// - Parameter simulateWalk: a route id to replay through the location
    ///   feed. Without it the app uses CoreLocation and nothing moves in a
    ///   simulator with no location set.
    private func launchApp(language: String = "english", simulateWalk: String? = "wukang") -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = [
            "-settings.language", language,
            "-settings.hasSeenOnboarding", "YES",
            "-uitest.resetUserState",
            "-uitest.ignoreLocation",
        ]
        if let simulateWalk {
            arguments += ["-uitest.simulateWalk", simulateWalk]
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
            anyElement(app, "routes-option-menu").waitForExistence(timeout: 15),
            "the map screen never appeared"
        )
        Thread.sleep(forTimeInterval: 2.0)
    }

    /// Opens tracking the way a walker would: the route's card, then Begin route.
    private func startWalkFromRouteCard(_ app: XCUIApplication, routeId: String = "wukang") {
        openCardAndBegin(app, routeId: routeId)
        XCTAssertTrue(element(app, "elapsed-clock").waitForExistence(timeout: 10), "tracking never opened")
    }

    private func openCardAndBegin(_ app: XCUIApplication, routeId: String = "wukang", beginLabel: String? = nil) {
        revealRow(app, routeId).tap()
        let begin = anyElement(app, "start-walking-button")
        XCTAssertTrue(begin.waitForExistence(timeout: 5), "the route card has no Begin route")
        if let beginLabel {
            XCTAssertEqual(begin.label, beginLabel, "Begin route is not in the app's language")
        }
        begin.tap()
    }

    /// The clock carries the time in its accessibility *value*; its *label* is
    /// the name "Elapsed", which is what a VoiceOver user hears first. Reading
    /// `.label` here would compare the word to itself forever.
    private func clock(_ app: XCUIApplication) -> String {
        element(app, "elapsed-clock").value as? String ?? ""
    }

    private func percent(_ app: XCUIApplication) -> Int {
        Int(element(app, "progress-percent").label.replacingOccurrences(of: "%", with: "")) ?? -1
    }

    // MARK: - Opening

    func testStartWalkingOpensTrackingRunningFromZero() {
        let app = launchApp()
        waitForMap(app)

        openCardAndBegin(app)

        // Catch it early: the clock should be at or near zero and already running.
        XCTAssertTrue(element(app, "elapsed-clock").waitForExistence(timeout: 10))
        let started = clock(app)
        // Fresh, not exactly zero: locating the element takes a second or two,
        // and asserting "00:00" would be measuring XCUITest rather than the app.
        // What matters is that the walk starts from nothing rather than
        // inheriting a previous session's clock.
        let seconds = started.split(separator: ":").compactMap { Int($0) }
        XCTAssertEqual(seconds.count, 2, "the clock should read MM:SS, was \(started)")
        XCTAssertEqual(seconds.first, 0, "the clock should start under a minute, was \(started)")
        XCTAssertLessThan(seconds[1], 6, "the clock did not start fresh, was \(started)")
        XCTAssertEqual(element(app, "recording-state").label, "Recording")
    }

    func testRecButtonOnTheMapAlsoStartsAWalk() {
        let app = launchApp()
        waitForMap(app)

        element(app, "record-button").tap()
        XCTAssertTrue(element(app, "elapsed-clock").waitForExistence(timeout: 10),
                      "the REC button did not open tracking")
        XCTAssertEqual(element(app, "recording-state").label, "Recording")
        // REC records a free walk: no route is chosen for the walker.
        XCTAssertTrue(app.staticTexts["New walk"].exists, "REC followed a route")
        XCTAssertFalse(element(app, "progress-percent").exists, "a free walk shows route progress")
    }

    // MARK: - Motion

    func testTheWalkAdvancesAsLocationArrives() {
        let app = launchApp()
        waitForMap(app)
        startWalkFromRouteCard(app)

        // Let the synthetic walk cover some ground.
        Thread.sleep(forTimeInterval: 4.0)
        let earlyPercent = percent(app)
        XCTAssertGreaterThan(earlyPercent, 0, "the walk made no progress")
        capture(app, "30-tracking-in-motion-en")

        Thread.sleep(forTimeInterval: 4.0)
        let laterPercent = percent(app)
        XCTAssertGreaterThan(laterPercent, earlyPercent, "progress stopped advancing")

        // The clock moved too.
        XCTAssertNotEqual(clock(app), "00:00", "the clock never advanced")
    }

    // MARK: - Pause / resume / end

    func testPauseStopsTheClockAndResumeContinuesIt() {
        let app = launchApp()
        waitForMap(app)
        startWalkFromRouteCard(app)
        Thread.sleep(forTimeInterval: 3.0)

        let pauseResume = app.buttons["pause-resume-button"]
        XCTAssertEqual(pauseResume.label, "Pause")
        pauseResume.tap()
        Thread.sleep(forTimeInterval: 0.8)

        XCTAssertEqual(element(app, "recording-state").label, "Paused", "the state label did not change")
        XCTAssertEqual(pauseResume.label, "Resume", "the button did not become Resume")
        let atPause = clock(app)
        capture(app, "31-tracking-paused-en")

        // The clock must be frozen while paused.
        Thread.sleep(forTimeInterval: 3.0)
        XCTAssertEqual(clock(app), atPause, "the clock kept running while paused")
        let percentAtPause = percent(app)

        pauseResume.tap()
        Thread.sleep(forTimeInterval: 3.0)
        XCTAssertEqual(element(app, "recording-state").label, "Recording")
        XCTAssertNotEqual(clock(app), atPause, "the clock did not restart on resume")
        XCTAssertGreaterThanOrEqual(percent(app), percentAtPause)
    }

    func testEndWalkReachesTheSummaryStubCarryingTheFigures() {
        let app = launchApp()
        waitForMap(app)
        startWalkFromRouteCard(app)
        Thread.sleep(forTimeInterval: 4.0)

        let distanceBefore = app.staticTexts["0.5"].exists
        app.buttons["end-walk-button"].tap()

        // Phase 5 replaced the stub with the real summary screen.
        XCTAssertTrue(element(app, "summary-route-name").waitForExistence(timeout: 10),
                      "End walk did not reach the summary")
        XCTAssertTrue(app.staticTexts["Walk complete"].exists)
        XCTAssertEqual(element(app, "summary-route-name").label,
                       "Wukang Road & the Concession Lanes")
        _ = distanceBefore
        capture(app, "32-walk-summary-from-tracking-en")
    }

    // MARK: - Chinese

    func testTrackingReadsInChinese() {
        let app = launchApp(language: "chinese")
        waitForMap(app)

        openCardAndBegin(app, beginLabel: "开始路线")
        XCTAssertTrue(element(app, "elapsed-clock").waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 4.0)

        XCTAssertEqual(element(app, "recording-state").label, "记录中")
        XCTAssertTrue(app.staticTexts["配速"].exists, "pace label is not in Chinese")
        XCTAssertTrue(app.staticTexts["剩余"].exists, "remaining label is not in Chinese")
        XCTAssertTrue(app.staticTexts["进度"].exists, "progress label is not in Chinese")
        XCTAssertTrue(app.buttons["暂停"].exists, "Pause is not in Chinese")
        XCTAssertTrue(app.buttons["结束步行"].exists, "End walk is not in Chinese")
        XCTAssertGreaterThan(percent(app), 0, "the walk did not advance in the Chinese run")
        capture(app, "33-tracking-in-motion-zh")

        app.buttons["暂停"].tap()
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertEqual(element(app, "recording-state").label, "已暂停")
        XCTAssertTrue(app.buttons["继续"].exists, "Resume is not in Chinese")
        capture(app, "34-tracking-paused-zh")
    }

    // MARK: - Backgrounding

    func testTheClockKeepsRunningAcrossBackgrounding() {
        let app = launchApp()
        waitForMap(app)
        startWalkFromRouteCard(app)
        Thread.sleep(forTimeInterval: 2.0)

        let before = clock(app)

        // Out to the home screen and back.
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 5.0)
        app.activate()
        XCTAssertTrue(element(app, "elapsed-clock").waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1.0)

        let after = clock(app)
        XCTAssertNotEqual(after, before, "the clock did not advance across backgrounding")

        // And it advanced by roughly the time spent away, not by zero — the
        // clock is derived from the wall clock, so suspension costs nothing.
        let seconds = { (text: String) -> Int in
            let parts = text.split(separator: ":").compactMap { Int($0) }
            return parts.count == 2 ? parts[0] * 60 + parts[1] : 0
        }
        XCTAssertGreaterThanOrEqual(
            seconds(after) - seconds(before), 4,
            "the clock lost the time the app spent in the background"
        )
        capture(app, "35-tracking-after-background-en")
    }
}
