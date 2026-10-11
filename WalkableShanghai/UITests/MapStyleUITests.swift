import XCTest

/// The map-style button switches between Map, Satellite and Traffic, and the
/// choice survives a relaunch.
final class MapStyleUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func chooseStyle(_ app: XCUIApplication, _ title: String) {
        anyElement(app, "map-style-button").tap()
        let item = app.buttons[title].firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 3), "style \(title) missing")
        item.tap()
    }

    func testEachStyleCanBeChosen() {
        let app = launchWalkable()
        let map = anyElement(app, "route-map")
        XCTAssertEqual(map.value as? String, "standard")
        chooseStyle(app, "Satellite")
        XCTAssertEqual(map.value as? String, "satellite")
        attachScreenshot(app, "map-style-satellite")
        chooseStyle(app, "Traffic")
        XCTAssertEqual(map.value as? String, "traffic")
        attachScreenshot(app, "map-style-traffic")
        chooseStyle(app, "Map")
        XCTAssertEqual(map.value as? String, "standard")
    }

    func testTheChoiceSurvivesRelaunch() {
        var app = launchWalkable()
        chooseStyle(app, "Satellite")
        app.terminate()
        app = launchWalkable(resetState: false, mapStyle: nil)
        XCTAssertEqual(anyElement(app, "route-map").value as? String, "satellite")
        chooseStyle(app, "Map")
    }

    func testTheMenuReadsInChinese() {
        let app = launchWalkable(language: "chinese")
        anyElement(app, "map-style-button").tap()
        XCTAssertTrue(app.buttons["卫星"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["路况"].exists)
    }
}
