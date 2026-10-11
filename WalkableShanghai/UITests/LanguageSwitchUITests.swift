import XCTest

/// Phase 1's other acceptance test: the in-app language switch actually works,
/// by tapping the real control rather than by setting a flag.
///
/// This is the criterion most worth automating. The whole app is bilingual, the
/// switch is a product feature rather than a system setting, and a regression
/// here is invisible to anyone testing in one language.
///
/// It also captures the screenshots used to review the design, so they are
/// reproducible rather than hand-taken.
final class LanguageSwitchUITests: XCTestCase {

    // The two headlines, as they appear in the String Catalog. If these change,
    // this test should change with them — that is the point.
    private let englishHeadline = "Walks end too soon."
    private let chineseHeadline = "散步总是被迫结束。"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches with a known state. Passing defaults as launch arguments puts
    /// them in UserDefaults' argument domain, which wins over anything a
    /// previous run persisted — so the test starts from onboarding in English
    /// every time.
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-settings.language", "english",
            "-settings.hasSeenOnboarding", "NO",
        ]
        app.launch()
        return app
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testLanguageSwitchChangesOnboardingAndTabShell() {
        let app = launchApp()

        // 1 — Onboarding, English.
        XCTAssertTrue(
            app.staticTexts[englishHeadline].waitForExistence(timeout: 10),
            "expected the English onboarding headline on launch"
        )
        XCTAssertTrue(app.staticTexts["Length"].exists)
        XCTAssertTrue(app.staticTexts["How far it actually goes"].exists)
        capture(app, "01-onboarding-en")

        // 2 — Tap 简体中文. This is the real control, not a test hook.
        let chineseOption = app.buttons["简体中文"]
        XCTAssertTrue(chineseOption.exists, "expected the Chinese option in the language switch")
        chineseOption.tap()

        XCTAssertTrue(
            app.staticTexts[chineseHeadline].waitForExistence(timeout: 5),
            "tapping 中文 did not switch the headline"
        )
        XCTAssertFalse(
            app.staticTexts[englishHeadline].exists,
            "the English headline is still on screen after switching to Chinese"
        )
        // Content strings and interface strings both have to move.
        XCTAssertTrue(app.staticTexts["长度"].exists, "the Length row did not switch")
        XCTAssertTrue(app.staticTexts["实际能走多远"].exists)
        capture(app, "02-onboarding-zh")

        // 3 — Into the tab shell, still Chinese. Proves the choice survives the
        // move off the onboarding screen.
        app.buttons["查找附近路线"].tap()

        let mapTab = app.tabBars.buttons["地图"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5), "expected Chinese tab titles")
        XCTAssertTrue(app.tabBars.buttons["社区"].exists)
        XCTAssertTrue(app.tabBars.buttons["收藏"].exists)
        XCTAssertTrue(app.tabBars.buttons["我"].exists)
        capture(app, "03-tabshell-zh")

        // 4 — Switch back from the language switch's permanent home.
        app.tabBars.buttons["我"].tap()
        let englishOption = app.buttons["English"]
        XCTAssertTrue(englishOption.waitForExistence(timeout: 5), "expected the language switch on the You tab")
        englishOption.tap()

        XCTAssertTrue(
            app.tabBars.buttons["Map"].waitForExistence(timeout: 5),
            "switching back to English did not update the tab bar"
        )
        XCTAssertTrue(app.tabBars.buttons["Community"].exists)
        XCTAssertTrue(app.tabBars.buttons["Saved"].exists)
        XCTAssertTrue(app.tabBars.buttons["Me"].exists)
        capture(app, "04-tabshell-en")

        // 5 — The map screen, which is where the bundled catalogue first shows
        // up as something you can act on. (Phase 2 replaced the placeholder
        // this step used to assert.)
        app.tabBars.buttons["Map"].tap()
        XCTAssertTrue(
            app.staticTexts["Routes in view"].waitForExistence(timeout: 10),
            "the map screen did not appear on the Map tab"
        )
        XCTAssertEqual(
            app.staticTexts["routes-in-view-count"].label, "5",
            "the bundled catalogue did not reach the map screen"
        )
        capture(app, "05-map-tab-en")
    }

    /// Both ways out of onboarding reach a screen, and the app opens on
    /// onboarding in the first place.
    ///
    /// The two buttons go to different places on purpose: "find a route" lands
    /// on the Map tab, "I have a route to share" opens the route builder as a
    /// full-screen cover over the shell. That is the navigation shape Phase 5
    /// will build for real, so it is worth pinning down now.
    func testBothOnboardingButtonsReachAScreen() {
        // Primary.
        var app = launchApp()
        XCTAssertTrue(app.staticTexts[englishHeadline].waitForExistence(timeout: 10))
        app.buttons["Find a route near me"].tap()
        XCTAssertTrue(
            app.tabBars.buttons["Map"].waitForExistence(timeout: 5),
            "the primary button did not reach the tab shell"
        )
        XCTAssertFalse(app.staticTexts[englishHeadline].exists, "onboarding is still on screen")

        // Secondary — opens the builder over the shell.
        app.terminate()
        app = launchApp()
        XCTAssertTrue(app.staticTexts[englishHeadline].waitForExistence(timeout: 10))
        app.buttons["I have a route to share"].tap()
        // Phase 5 replaced the placeholder this used to assert with the real
        // builder, which draws no navigation bar of its own.
        XCTAssertTrue(
            app.descendants(matching: .any).matching(identifier: "builder-map")
                .firstMatch.waitForExistence(timeout: 10),
            "the secondary button did not open the route builder"
        )
        capture(app, "08-builder-from-onboarding-en")

        // And it dismisses back to the shell underneath. The real builder
        // brings its own back button; the placeholder's "Done" toolbar item
        // went away with it in Phase 5.
        app.descendants(matching: .any).matching(identifier: "builder-back-button")
            .firstMatch.tap()
        XCTAssertTrue(app.tabBars.buttons["Map"].waitForExistence(timeout: 10))
    }

    /// The design system gallery, in both languages. Not an acceptance
    /// criterion, but it is the screen that shows every shared component at
    /// once, so it is the one worth having a picture of.
    func testDesignSystemGalleryRendersInBothLanguages() {
        let app = launchApp()

        app.buttons["Find a route near me"].tap()
        app.tabBars.buttons["Me"].tap()

        app.buttons["Design system"].tap()
        // Assert on the navigation title, not on a section label: the labels are
        // uppercased with `.textCase(.uppercase)`, which changes what is drawn
        // but not the underlying accessibility string.
        XCTAssertTrue(app.navigationBars["Design system"].waitForExistence(timeout: 5))
        capture(app, "06-design-system-en")

        app.buttons["Done"].tap()
        app.buttons["简体中文"].tap()
        app.buttons["设计系统"].tap()
        XCTAssertTrue(app.navigationBars["设计系统"].waitForExistence(timeout: 5))
        capture(app, "07-design-system-zh")
    }
}
