import XCTest

/// Phase 7's acceptance tests: the Saved screen's two lists track the toggles,
/// sizes are real, and a downloaded route opens with the network denied.
final class SavedUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp(
        language: String = "english",
        resetUserState: Bool = true,
        forceOffline: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = [
            "-settings.language", language,
            "-settings.hasSeenOnboarding", "YES",
        ]
        if resetUserState { arguments.append("-uitest.resetUserState") }
        if forceOffline { arguments.append("-uitest.forceOffline") }
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
        XCTAssertTrue(app.staticTexts["routes-in-view-count"].waitForExistence(timeout: 15),
                      "the map screen never appeared")
        Thread.sleep(forTimeInterval: 1.5)
    }

    private func openSaved(_ app: XCUIApplication, tabLabel: String = "Saved") {
        app.tabBars.buttons[tabLabel].tap()
        XCTAssertTrue(element(app, "saved-count").waitForExistence(timeout: 10),
                      "the Saved screen never appeared")
        Thread.sleep(forTimeInterval: 1.0)
    }


    /// Makes a route row reachable before tapping it.
    ///
    /// The peeking sheet shows as many rows as the screen has room for, and how
    /// many that is depends on the OS: iOS 26 draws its floating tab bar *over*
    /// the sheet, while iOS 18's opaque tab bar takes layout space, so two fewer
    /// rows fit in the peek. A row below the fold still "exists", and tapping it
    /// lands on whatever covers it — which is why this expands the sheet instead
    /// of trusting the fold.
    @discardableResult
    private func revealRouteRow(_ app: XCUIApplication, _ routeId: String) -> XCUIElement {
        let row = app.buttons["route-row-\(routeId)"]
        XCTAssertTrue(row.waitForExistence(timeout: 10), "no row for \(routeId)")

        if !row.isHittable {
            element(app, "sheet-handle").tap()
            Thread.sleep(forTimeInterval: 1.2)
        }
        for _ in 0..<3 where !row.isHittable {
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.6)
        }
        XCTAssertTrue(row.isHittable, "\(routeId) is not reachable even with the sheet open")
        return row
    }

    private func openRoute(_ app: XCUIApplication, _ routeId: String) {
        revealRouteRow(app, routeId).tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 10))
        XCTAssertTrue(element(app, "save-toggle").waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1.2)
    }

    // MARK: - The two lists

    func testSavedListsMatchTheSeededToggles() {
        let app = launchApp()
        waitForMap(app)
        openSaved(app)

        // Seed: saved = wukang, creek, century. Offline = fuxing, wukang.
        XCTAssertEqual(element(app, "saved-count").label, "3 routes")
        XCTAssertTrue(app.staticTexts["Offline"].exists)
        XCTAssertTrue(app.staticTexts["Saved routes"].exists)

        XCTAssertTrue(element(app, "offline-row-wukang").exists)
        XCTAssertTrue(element(app, "offline-row-fuxing").exists)
        XCTAssertFalse(element(app, "offline-row-creek").exists,
                       "creek is saved but not downloaded")

        XCTAssertTrue(element(app, "saved-row-wukang").exists)
        XCTAssertTrue(element(app, "saved-row-creek").exists)
        XCTAssertTrue(element(app, "saved-row-century").exists)
        XCTAssertFalse(element(app, "saved-row-bund").exists)
        capture(app, "60-saved-en")
    }

    func testOfflineRowsCarryARealSizeNotTheCataloguesFigure() {
        let app = launchApp()
        waitForMap(app)
        openSaved(app)

        let row = element(app, "offline-row-wukang")
        XCTAssertTrue(row.exists)
        // The row reads "km · min · size". The size must be a real figure, not
        // the mockup's flat 18 MB that every route used to claim.
        XCTAssertFalse(row.label.contains("18 MB"),
                       "the catalogue's fictional size leaked into the row: \(row.label)")
        XCTAssertTrue(row.label.contains("KB") || row.label.contains("MB"),
                      "no size on the offline row: \(row.label)")

        // And the footer totals what is actually on the phone.
        XCTAssertTrue(element(app, "saved-total-stored").exists,
                      "the total stored figure is missing")
    }

    func testBothListsOpenTheRightRoute() {
        let app = launchApp()
        waitForMap(app)
        openSaved(app)

        element(app, "offline-row-fuxing").tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["route-detail-name"].label, "Fuxing Park to Xintiandi")
        element(app, "route-back-button").tap()
        openSaved(app)

        element(app, "saved-row-century").tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["route-detail-name"].label, "Century Park Outer Loop")
    }

    // MARK: - The lists track the toggles

    func testTogglingBookmarkAndDownloadUpdatesBothLists() {
        let app = launchApp()
        waitForMap(app)

        // The Bund starts neither saved nor downloaded.
        openRoute(app, "bund")
        element(app, "save-toggle").tap()
        Thread.sleep(forTimeInterval: 0.8)
        element(app, "offline-toggle").tap()
        // Downloading renders and stores an image, so give it a moment.
        Thread.sleep(forTimeInterval: 2.0)
        XCTAssertTrue(app.staticTexts["Offline ready"].exists)
        element(app, "route-back-button").tap()

        openSaved(app)
        XCTAssertEqual(element(app, "saved-count").label, "4 routes",
                       "the count did not follow the new bookmark")
        XCTAssertTrue(element(app, "saved-row-bund").exists)
        let row = element(app, "offline-row-bund")
        XCTAssertTrue(row.exists, "the new download is not in the Offline list")
        XCTAssertTrue(row.label.contains("KB") || row.label.contains("MB"),
                      "the new download has no size: \(row.label)")
        capture(app, "61-saved-after-download-en")

        // And removing the download takes it back out of the Offline list while
        // leaving the bookmark alone.
        element(app, "offline-row-bund").tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1.0)
        element(app, "offline-toggle").tap()
        Thread.sleep(forTimeInterval: 1.5)
        element(app, "route-back-button").tap()

        openSaved(app)
        XCTAssertFalse(element(app, "offline-row-bund").exists,
                       "the removed download is still listed")
        XCTAssertTrue(element(app, "saved-row-bund").exists,
                      "removing a download should not remove the bookmark")
        XCTAssertEqual(element(app, "saved-count").label, "4 routes")
    }

    // MARK: - With the network denied

    /// The simulator has no airplane mode `simctl` can reach, so the app is
    /// launched with its reachability forced offline. Everything below the flag
    /// is the real offline path: the stored image, the stored notes count, and
    /// no MapKit view at all.
    func testADownloadedRouteOpensWithTheNetworkDenied() {
        // First launch: seed the downloads (fuxing and wukang are seeded
        // offline, and the app builds their bundles at startup).
        let seeding = launchApp()
        waitForMap(seeding)
        openSaved(seeding)
        XCTAssertTrue(element(seeding, "offline-row-wukang").exists)

        // Relaunch with no network, keeping what was downloaded.
        let app = launchApp(resetUserState: false, forceOffline: true)
        waitForMap(app)
        openRoute(app, "wukang")

        // The stored picture is shown, and the live map is not built at all.
        XCTAssertTrue(element(app, "offline-map-image").exists,
                      "a downloaded route did not fall back to its stored map")
        XCTAssertFalse(element(app, "live-map").exists,
                       "the live map was still used with no network")

        // Its figures and its notes are all there, read from the snapshot.
        XCTAssertEqual(app.staticTexts["route-detail-name"].label,
                       "Wukang Road & the Concession Lanes")
        XCTAssertTrue(app.staticTexts["3.4"].exists, "the figures are missing offline")
        XCTAssertTrue(app.staticTexts["Xuhui"].exists)
        capture(app, "62-offline-route-detail-en")

        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertTrue(app.buttons["Notes from walkers (4)"].exists,
                      "the walker notes were not counted offline")

        app.buttons["notes-button"].tap()
        XCTAssertTrue(app.staticTexts["Notes from walkers"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertTrue(app.staticTexts["Wukang Rd × Hunan Rd"].exists,
                      "the stored walker notes are not readable offline")
        capture(app, "63-offline-notes-en")
    }

    /// The stored picture is wider than the slot it is drawn into, and a
    /// picture must never be allowed to decide how wide the screen is. It did:
    /// `scaledToFill` reported its scaled width, the frame around it passed
    /// that width up, and the entire column of text was centred off screen.
    /// This pins the layout to the one thing that cannot lie — the window.
    func testTheStoredMapDoesNotShiftTheLayoutSideways() {
        let seeding = launchApp()
        waitForMap(seeding)
        openSaved(seeding)
        XCTAssertTrue(element(seeding, "offline-row-wukang").exists)

        // With a network, the live map is drawn and the text sits where it
        // always has. Record that as the reference.
        let online = launchApp(resetUserState: false)
        waitForMap(online)
        openRoute(online, "wukang")
        XCTAssertTrue(element(online, "live-map").exists)
        let referenceLeftEdge = online.staticTexts["route-detail-name"].frame.minX

        let app = launchApp(resetUserState: false, forceOffline: true)
        waitForMap(app)
        openRoute(app, "wukang")
        XCTAssertTrue(element(app, "offline-map-image").exists)

        let window = app.windows.firstMatch.frame
        let title = app.staticTexts["route-detail-name"]
        XCTAssertEqual(title.frame.minX, referenceLeftEdge, accuracy: 1,
                       "the stored picture moved the title away from where the live map leaves it")

        // And nothing in the column hangs off either edge of the window.
        for identifier in ["offline-toggle", "share-button", "start-walking-button", "notes-button"] {
            let control = element(app, identifier)
            XCTAssertTrue(control.exists, "\(identifier) is missing")
            XCTAssertGreaterThanOrEqual(control.frame.minX, window.minX - 1,
                                        "\(identifier) hangs off the left edge")
            XCTAssertLessThanOrEqual(control.frame.maxX, window.maxX + 1,
                                     "\(identifier) hangs off the right edge")
        }
    }

    func testAnUndownloadedRouteStillUsesTheLiveMapWithNoNetwork() {
        let app = launchApp(forceOffline: true)
        waitForMap(app)
        // The Bund is not downloaded, so there is no stored picture to show and
        // we do not invent one.
        openRoute(app, "bund")
        XCTAssertFalse(element(app, "offline-map-image").exists)
        XCTAssertTrue(element(app, "live-map").exists)
    }

    // MARK: - Chinese

    func testSavedReadsInChinese() {
        let app = launchApp(language: "chinese")
        waitForMap(app)
        openSaved(app, tabLabel: "收藏")

        XCTAssertEqual(element(app, "saved-count").label, "3 条路线")
        XCTAssertTrue(app.staticTexts["离线可用"].exists)
        XCTAssertTrue(app.staticTexts["已收藏"].exists)
        XCTAssertTrue(element(app, "offline-row-wukang").exists)
        XCTAssertTrue(element(app, "saved-row-creek").exists)

        // The footer says what offline really keeps, and does not promise sync.
        let footer = element(app, "saved-footer").label
        XCTAssertTrue(footer.contains("离线路线"), "the footer is not in Chinese")
        XCTAssertTrue(element(app, "saved-total-stored").label.contains("本机已存储"))
        capture(app, "64-saved-zh")
    }

    /// The offline screen in Chinese. Worth its own test rather than trusting
    /// the English one: the stored snapshot carries both languages, and the
    /// point of storing the whole route rather than a rendering of it is that
    /// the language can still be switched with no network.
    func testADownloadedRouteReadsInChineseWithTheNetworkDenied() {
        let seeding = launchApp(language: "chinese")
        waitForMap(seeding)
        openSaved(seeding, tabLabel: "收藏")
        XCTAssertTrue(element(seeding, "offline-row-wukang").exists)

        let app = launchApp(language: "chinese", resetUserState: false, forceOffline: true)
        waitForMap(app)
        openRoute(app, "wukang")

        XCTAssertTrue(element(app, "offline-map-image").exists,
                      "a downloaded route did not fall back to its stored map")
        XCTAssertFalse(element(app, "live-map").exists)

        // Read out of the snapshot, in the other language.
        XCTAssertEqual(app.staticTexts["route-detail-name"].label, "武康路与法租界弄堂")
        XCTAssertTrue(app.staticTexts["3.4"].exists, "the figures are missing offline")
        XCTAssertTrue(app.staticTexts["徐汇"].exists)
        capture(app, "65-offline-route-detail-zh")

        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertTrue(app.buttons["走过的人说（4）"].exists,
                      "the walker notes were not counted offline")

        app.buttons["notes-button"].tap()
        XCTAssertTrue(app.staticTexts["走过的人说"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertTrue(app.staticTexts["武康路 × 湖南路"].exists,
                      "the stored walker notes are not readable offline in Chinese")
        capture(app, "66-offline-notes-zh")
    }

    func testTheFooterDoesNotPromiseSync() {
        let app = launchApp()
        waitForMap(app)
        openSaved(app)

        let footer = element(app, "saved-footer").label
        // The mockup promised routes "sync when you are back on data". There is
        // no backend, so the app must not say so.
        XCTAssertFalse(footer.lowercased().contains("sync when"),
                       "the footer promises syncing the app cannot do: \(footer)")
        XCTAssertTrue(footer.contains("no signal") || footer.contains("Offline routes"),
                      "the footer does not say what offline keeps: \(footer)")
    }
}
