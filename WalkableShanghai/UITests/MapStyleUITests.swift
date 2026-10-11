import XCTest

/// The map-style button switches between Map, Satellite and Traffic, and the
/// choice survives a relaunch.
@MainActor
final class MapStyleUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// "Map" is also the first tab's title, and on iOS 18 `app.buttons["Map"]`
    /// finds the tab first. So take the match that is not in the tab bar.
    private func chooseStyle(_ app: XCUIApplication, _ title: String) {
        anyElement(app, "map-style-button").tap()
        let tabBar = app.tabBars.firstMatch
        var item: XCUIElement?
        for _ in 0..<6 where item == nil {
            item = app.buttons.matching(NSPredicate(format: "label == %@", title)).allElementsBoundByIndex
                .first { !(tabBar.exists && tabBar.frame.intersects($0.frame)) }
            if item == nil { Thread.sleep(forTimeInterval: 0.5) }
        }
        guard let item else { return XCTFail("style \(title) missing") }
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
