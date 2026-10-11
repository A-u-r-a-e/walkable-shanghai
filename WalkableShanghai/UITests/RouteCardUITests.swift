import XCTest

/// The route card: opened from a row or a pin, expanded in the spec's order,
/// collapsible to title and figures, and the actions on it.
@MainActor
final class RouteCardUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func openCard(_ app: XCUIApplication, _ routeId: String) {
        revealRow(app, routeId).tap()
        XCTAssertTrue(anyElement(app, "route-card").waitForExistence(timeout: 5))
    }

    func testARowOpensTheCardExpandedInOrder() {
        let app = launchWalkable()
        openCard(app, "wukang")

        let order = ["route-card-title", "route-card-figures", "route-card-description", "route-card-tags", "route-card-creator", "start-walking-button"]
        let tops = order.map { anyElement(app, $0) }.map { element -> CGFloat in
            XCTAssertTrue(element.exists, "\(element) missing")
            return element.frame.minY
        }
        XCTAssertEqual(tops, tops.sorted(), "card sections out of order")

        XCTAssertEqual(anyElement(app, "route-card-figures").label, "3.4 km · 52 min")
        XCTAssertTrue(app.staticTexts["Featured"].exists)
        XCTAssertTrue(app.staticTexts["Popular"].exists)
        XCTAssertEqual(anyElement(app, "route-card-walking-now").label, "0 walking now")
        XCTAssertFalse(app.staticTexts["Featured route"].exists, "no header line above the title")
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'dead end'")).count, 0)
        XCTAssertTrue(anyElement(app, "share-button").exists)
        XCTAssertTrue(anyElement(app, "save-toggle").exists)
        attachScreenshot(app, "route-card-expanded-en")
    }

    func testTheCardCollapsesToTitleAndFigures() {
        let app = launchWalkable()
        openCard(app, "wukang")
        anyElement(app, "sheet-handle").tap()
        XCTAssertTrue(anyElement(app, "route-card-title").exists)
        XCTAssertTrue(anyElement(app, "route-card-figures").exists)
        XCTAssertFalse(anyElement(app, "start-walking-button").exists)
        attachScreenshot(app, "route-card-collapsed-en")
    }

    func testCloseReturnsToTheList() {
        let app = launchWalkable()
        openCard(app, "creek")
        anyElement(app, "route-card-close").tap()
        XCTAssertTrue(anyElement(app, "routes-option-menu").waitForExistence(timeout: 3))
        XCTAssertFalse(anyElement(app, "route-card").exists)
    }

    func testAPinOpensTheSameCard() {
        let app = launchWalkable()
        let pin = anyElement(app, "route-pin-bund")
        XCTAssertTrue(pin.waitForExistence(timeout: 10))
        pin.tap()
        XCTAssertTrue(anyElement(app, "route-card").waitForExistence(timeout: 5))
        XCTAssertEqual(anyElement(app, "route-card-title").label, "The Bund to Yuyuan")
    }

    func testBookmarkingSavesAndSurvivesRelaunch() {
        var app = launchWalkable()
        openCard(app, "fuxing")
        anyElement(app, "save-toggle").tap()
        app.terminate()

        app = launchWalkable(resetState: false)
        chooseRoutesOption(app, "Saved")
        XCTAssertTrue(revealRow(app, "fuxing").exists)
    }

    func testShareOpensTheShareSheet() {
        let app = launchWalkable()
        openCard(app, "wukang")
        anyElement(app, "share-button").tap()
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 5)
            || app.navigationBars["UIActivityContentView"].waitForExistence(timeout: 5))
    }

    func testBeginRouteStartsTracking() {
        let app = launchWalkable(arguments: ["-uitest.simulateWalk", "wukang"])
        openCard(app, "wukang")
        anyElement(app, "start-walking-button").tap()
        XCTAssertTrue(anyElement(app, "recording-state").waitForExistence(timeout: 5))
    }

    func testTheCardReadsInChinese() {
        let app = launchWalkable(language: "chinese")
        openCard(app, "wukang")
        XCTAssertEqual(anyElement(app, "route-card-title").label, "武康路与法租界弄堂")
        XCTAssertTrue(app.staticTexts["精选"].exists)
        XCTAssertEqual(anyElement(app, "route-card-walking-now").label, "0 人正在走")
        attachScreenshot(app, "route-card-expanded-zh")
    }
}
