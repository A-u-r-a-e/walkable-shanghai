import XCTest

/// The Routes sheet: its five options, Popular's period selector, the
/// sections under Saved, search, and what each row says.
final class RouteListUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testNearbyIsTheDefaultAndOrdersFromPeoplesSquare() {
        let app = launchWalkable()
        XCTAssertTrue(anyElement(app, "routes-option-menu").label.contains("Nearby"))
        XCTAssertEqual(anyElement(app, "route-pin-wukang").label, "Wukang Road & the Concession Lanes")
        anyElement(app, "sheet-handle").tap()
        XCTAssertEqual(visibleRowOrder(app), ["fuxing", "bund", "creek", "wukang", "century"])
        attachScreenshot(app, "routes-nearby-en")
    }

    func testRowsShowFiguresUpdatedDateAndWalkingNow() {
        let app = launchWalkable()
        let status = anyElement(app, "route-row-status-fuxing")
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertTrue(status.label.contains("Last updated:"))
        XCTAssertTrue(status.label.contains("0 walking now"))
        XCTAssertFalse(app.staticTexts["1"].exists, "rows must not be numbered")
    }

    func testPopularHasAPeriodSelectorAndRanksByIt() {
        let app = launchWalkable()
        chooseRoutesOption(app, "Popular")
        XCTAssertTrue(anyElement(app, "period-week").isSelected)
        anyElement(app, "sheet-handle").tap()
        XCTAssertEqual(visibleRowOrder(app), ["wukang", "bund", "creek", "fuxing"])

        anyElement(app, "period-month").tap()
        XCTAssertEqual(visibleRowOrder(app), ["wukang", "creek", "bund", "fuxing", "century"])
    }

    func testFeaturedListsOnlyFeaturedRoutes() {
        let app = launchWalkable()
        chooseRoutesOption(app, "Featured")
        XCTAssertEqual(visibleRowOrder(app), ["wukang"])
        XCTAssertFalse(anyElement(app, "period-week").exists)
    }

    func testMineOffersANewRouteThatOpensTheBuilder() {
        let app = launchWalkable()
        chooseRoutesOption(app, "Mine")
        XCTAssertTrue(anyElement(app, "routes-empty-mine").exists)
        anyElement(app, "new-route-button").tap()
        XCTAssertTrue(anyElement(app, "builder-map").waitForExistence(timeout: 5))
    }

    func testSavedShowsMineAboveSaved() {
        let app = launchWalkable()
        chooseRoutesOption(app, "Saved")
        let mine = anyElement(app, "routes-section-mine")
        let saved = anyElement(app, "routes-section-saved")
        XCTAssertTrue(mine.exists && saved.exists)
        XCTAssertLessThan(mine.frame.minY, saved.frame.minY)
        XCTAssertTrue(anyElement(app, "new-route-button").exists)
        anyElement(app, "sheet-handle").tap()
        XCTAssertEqual(Set(visibleRowOrder(app)), ["wukang", "creek", "century"])
    }

    func testSearchFiltersByName() {
        let app = launchWalkable()
        let field = anyElement(app, "map-search-field")
        field.tap()
        field.typeText("bund")
        XCTAssertEqual(visibleRowOrder(app), ["bund"])
    }

    func testTheSheetReadsInChinese() {
        let app = launchWalkable(language: "chinese")
        XCTAssertTrue(anyElement(app, "routes-option-menu").label.contains("附近"))
        XCTAssertEqual(anyElement(app, "route-pin-wukang").label, "武康路与法租界弄堂")
        XCTAssertTrue(app.staticTexts["路线"].exists)
        XCTAssertTrue(anyElement(app, "route-row-status-fuxing").label.contains("人正在走"))
        attachScreenshot(app, "routes-nearby-zh")
    }
}
