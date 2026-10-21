import XCTest

/// A route shared by another walker, arriving as a `jwalk://` link.
@MainActor
final class ShareUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// A link as another walker's JWalk would write it: version 1 JSON,
    /// base64url, coordinates in units of 1e-5 degrees.
    private func sharedLink(id: String = "draft-ui5e1d00", name: String = "Gao'an Road canopy") throws -> URL {
        let json = try JSONSerialization.data(withJSONObject: [
            "v": 1,
            "id": id,
            "name": ["en": name, "zh": name],
            "note": ["en": "", "zh": ""],
            "author": "Mei",
            "initial": "M",
            "updated": 1_790_000_000,
            "line": [[3120310, 12144130], [3120600, 12144420], [3120890, 12144700]],
        ])
        let d = json.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return try XCTUnwrap(URL(string: "jwalk://route?d=\(d)"))
    }

    func testASharedLinkOpensTheRouteAndSavingKeepsIt() throws {
        let app = launchJWalk()
        app.open(try sharedLink())

        let card = anyElement(app, "route-card")
        XCTAssertTrue(card.waitForExistence(timeout: 10), "the shared link did not open a route card")
        XCTAssertEqual(anyElement(app, "route-card-title").label, "Gao'an Road canopy")
        XCTAssertTrue(app.staticTexts["Mei"].exists, "the card does not name who shared the route")
        attachScreenshot(app, "49-shared-route-card-en")

        anyElement(app, "save-toggle").tap()
        Thread.sleep(forTimeInterval: 1.0)

        // Saved, so it is still there after a relaunch.
        let relaunched = launchJWalk(resetState: false)
        chooseRoutesOption(relaunched, "Saved")
        // Below the three seeded saved routes, so it may need scrolling to.
        revealRow(relaunched, "draft-ui5e1d00").tap()
        XCTAssertTrue(anyElement(relaunched, "route-card").waitForExistence(timeout: 5))
        XCTAssertEqual(anyElement(relaunched, "route-card-title").label, "Gao'an Road canopy",
                       "the saved shared route did not survive a relaunch")
    }

    func testAnUnsavedSharedRouteIsGoneAfterRelaunch() throws {
        let app = launchJWalk()
        app.open(try sharedLink())
        XCTAssertTrue(anyElement(app, "route-card").waitForExistence(timeout: 10))

        let relaunched = launchJWalk(resetState: false)
        XCTAssertFalse(relaunched.buttons["route-row-draft-ui5e1d00"].exists)
        XCTAssertFalse(anyElement(relaunched, "route-pin-draft-ui5e1d00").exists)
    }

    func testALinkWithNoRouteSaysSo() throws {
        let app = launchJWalk()
        app.open(try XCTUnwrap(URL(string: "jwalk://route?d=bm90LWEtcm91dGU")))
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "a broken link failed silently")
        XCTAssertTrue(alert.staticTexts["This link or file does not hold a JWalk route."].exists)
        alert.buttons["OK"].tap()
    }

    /// A link that arrives mid-walk does not interrupt it; the route opens when
    /// the walk is done.
    func testASharedLinkWaitsForAWalkToFinish() throws {
        let app = launchJWalk(arguments: ["-uitest.simulateWalk", "wukang"])
        anyElement(app, "record-button").tap()
        XCTAssertTrue(anyElement(app, "elapsed-clock").waitForExistence(timeout: 10))

        app.open(try sharedLink())
        Thread.sleep(forTimeInterval: 2.0)
        XCTAssertTrue(anyElement(app, "elapsed-clock").exists, "the link interrupted the walk")

        app.buttons["end-walk-button"].tap()
        XCTAssertTrue(app.buttons["summary-done-button"].waitForExistence(timeout: 10))
        app.buttons["summary-done-button"].tap()
        XCTAssertTrue(anyElement(app, "route-card").waitForExistence(timeout: 10),
                      "the shared route did not open after the walk")
        XCTAssertEqual(anyElement(app, "route-card-title").label, "Gao'an Road canopy")
    }

    /// "How it works" covers the screen; a link closes it to show the route.
    func testASharedLinkClosesHowItWorks() throws {
        let app = launchJWalk()
        app.tabBars.buttons["Me"].tap()
        anyElement(app, "me-how-it-works-row").tap()
        XCTAssertTrue(app.buttons["onboarding-primary"].waitForExistence(timeout: 5))

        app.open(try sharedLink())
        XCTAssertTrue(anyElement(app, "route-card").waitForExistence(timeout: 10),
                      "the shared route opened behind How it works")
        XCTAssertFalse(app.buttons["onboarding-primary"].exists)
    }

    func testASharedLinkSkipsOnboarding() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-settings.language", "english", "-settings.hasSeenOnboarding", "NO",
                               "-uitest.ignoreLocation", "-uitest.resetUserState"]
        app.launch()
        XCTAssertTrue(app.buttons["onboarding-primary"].waitForExistence(timeout: 10))

        app.open(try sharedLink())
        XCTAssertTrue(anyElement(app, "route-card").waitForExistence(timeout: 10),
                      "the shared link stayed behind onboarding")
        XCTAssertEqual(anyElement(app, "route-card-title").label, "Gao'an Road canopy")
    }
}
