import XCTest

/// Launch and query helpers shared by every UI test.
///
/// Named so they cannot collide with the private helpers older test classes
/// still declare.
extension XCTestCase {

    /// Launches past onboarding, in the language asked for, from the seeded
    /// state unless `resetState` is false. Location is ignored so Nearby
    /// measures from People's Square and the order is fixed.
    /// `mapStyle` pins the basemap for the launch; pass nil to read whatever
    /// the previous launch stored.
    func launchWalkable(language: String = "english", resetState: Bool = true, mapStyle: String? = "standard", arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-settings.language", language, "-settings.hasSeenOnboarding", "YES", "-uitest.ignoreLocation"]
            + (resetState ? ["-uitest.resetUserState"] : [])
            + (mapStyle.map { ["-settings.mapStyle", $0] } ?? [])
            + arguments
        app.launch()
        XCTAssertTrue(anyElement(app, "routes-option-menu").waitForExistence(timeout: 10), "the Routes sheet never appeared")
        return app
    }

    /// An element by identifier, whatever type it surfaces as.
    func anyElement(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    func attachScreenshot(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// A row below the fold still exists to XCUITest, and tapping it lands on
    /// whatever covers it. Expand the sheet first when the row is not hittable.
    func revealRow(_ app: XCUIApplication, _ routeId: String) -> XCUIElement {
        let row = app.buttons["route-row-\(routeId)"]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "row \(routeId) missing")
        if !row.isHittable {
            anyElement(app, "sheet-handle").tap()
        }
        return row
    }

    /// Picks an option from the Routes dropdown by its visible title.
    func chooseRoutesOption(_ app: XCUIApplication, _ title: String) {
        anyElement(app, "routes-option-menu").tap()
        let item = app.buttons[title].firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 3), "menu item \(title) missing")
        item.tap()
    }

    /// Row identifiers in on-screen order, top to bottom.
    func visibleRowOrder(_ app: XCUIApplication) -> [String] {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'route-row-'")).allElementsBoundByIndex
            .sorted { $0.frame.minY < $1.frame.minY }
            .map { String($0.identifier.dropFirst("route-row-".count)) }
    }
}
