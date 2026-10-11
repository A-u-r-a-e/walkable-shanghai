import XCTest

/// Walks every screen and attaches a screenshot of each. Run once per
/// appearance (see README, "Screenshots").
@MainActor
final class ScreenshotUITests: XCTestCase {

    func testCaptureEveryScreen() {
        let app = launchWalkable()
        attachScreenshot(app, "01-map-list")
        anyElement(app, "sheet-handle").tap()
        attachScreenshot(app, "02-map-list-expanded")
        chooseRoutesOption(app, "Popular")
        attachScreenshot(app, "03-map-popular")
        chooseRoutesOption(app, "Saved")
        attachScreenshot(app, "04-map-saved")
        chooseRoutesOption(app, "Nearby")
        revealRow(app, "wukang").tap()
        // The list cross-fades into the card and the map flies to the route;
        // on iOS 18 a capture straight after the tap catches both halfway.
        XCTAssertTrue(anyElement(app, "route-card").waitForExistence(timeout: 5))
        sleep(2)
        attachScreenshot(app, "05-route-card-expanded")
        anyElement(app, "sheet-handle").tap()
        sleep(2)
        attachScreenshot(app, "06-route-card-collapsed")
        anyElement(app, "route-card-close").tap()

        app.tabBars.buttons["Me"].tap()
        attachScreenshot(app, "07-me")
        anyElement(app, "me-profile-row").tap()
        attachScreenshot(app, "08-profile")
        app.navigationBars.buttons.firstMatch.tap()
        anyElement(app, "me-downloads-row").tap()
        attachScreenshot(app, "09-downloads")
    }

    func testCaptureTrackingSummaryAndBuilder() {
        let app = launchWalkable(arguments: ["-uitest.simulateWalk", "wukang"])
        revealRow(app, "wukang").tap()
        anyElement(app, "start-walking-button").tap()
        sleep(4)
        attachScreenshot(app, "10-tracking")
        anyElement(app, "end-walk-button").tap()
        XCTAssertTrue(anyElement(app, "summary-done-button").waitForExistence(timeout: 5))
        attachScreenshot(app, "11-walk-summary")
        anyElement(app, "summary-done-button").tap()

        chooseRoutesOption(app, "Mine")
        anyElement(app, "new-route-button").tap()
        XCTAssertTrue(anyElement(app, "builder-map").waitForExistence(timeout: 5))
        attachScreenshot(app, "12-builder")
    }
}
