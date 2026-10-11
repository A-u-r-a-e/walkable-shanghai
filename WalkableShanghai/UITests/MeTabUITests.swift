import XCTest

/// The Me tab: a settings list whose first row opens the profile.
@MainActor
final class MeTabUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func openMe(_ app: XCUIApplication, title: String = "Me") {
        app.tabBars.buttons[title].tap()
        XCTAssertTrue(anyElement(app, "me-profile-row").waitForExistence(timeout: 5))
    }

    func testTheListHasItsRowsInOrderAndNoAppearanceSetting() {
        let app = launchWalkable()
        openMe(app)
        let order = ["me-profile-row", "me-language-picker", "me-downloads-row", "me-location-row", "me-how-it-works-row", "me-version-row"]
        let tops = order.map { anyElement(app, $0).frame.minY }
        XCTAssertEqual(tops, tops.sorted())
        XCTAssertFalse(app.staticTexts["Appearance"].exists)
        XCTAssertEqual(app.tabBars.buttons.count, 2)
        attachScreenshot(app, "me-en")
    }

    func testTheProfileRowOpensTheProfile() {
        let app = launchWalkable()
        openMe(app)
        anyElement(app, "me-profile-row").tap()
        // The figures, not the chart: a fresh install has no walks, and the
        // chart gives way to its empty state until there is one.
        XCTAssertTrue(anyElement(app, "profile-walk-count").waitForExistence(timeout: 5))
    }

    func testLanguageSwitchesImmediately() {
        let app = launchWalkable()
        openMe(app)
        anyElement(app, "me-language-picker").tap()
        app.buttons["简体中文"].tap()
        XCTAssertTrue(app.tabBars.buttons["地图"].waitForExistence(timeout: 3))
    }

    func testDownloadsListSavedRoutesAndRemoveAllClearsThem() {
        let app = launchWalkable()
        openMe(app)
        anyElement(app, "me-downloads-row").tap()
        for id in ["wukang", "creek", "century"] {
            XCTAssertTrue(anyElement(app, "download-row-\(id)").waitForExistence(timeout: 5), id)
        }
        anyElement(app, "remove-all-downloads").tap()
        app.sheets.buttons["Remove all downloads"].firstMatch.tap()
        XCTAssertTrue(anyElement(app, "downloads-empty").waitForExistence(timeout: 3))

        app.tabBars.buttons["Map"].tap()
        chooseRoutesOption(app, "Saved")
        XCTAssertTrue(anyElement(app, "routes-empty-saved").exists)
    }

    func testHowItWorksOpensOnboarding() {
        let app = launchWalkable()
        openMe(app)
        anyElement(app, "me-how-it-works-row").tap()
        XCTAssertTrue(app.buttons["Find a route near me"].waitForExistence(timeout: 5))
    }

    func testTheYouTabReadsInChinese() {
        let app = launchWalkable(language: "chinese")
        openMe(app, title: "我")
        XCTAssertTrue(app.staticTexts["已下载路线"].exists)
        attachScreenshot(app, "me-zh")
    }
}
