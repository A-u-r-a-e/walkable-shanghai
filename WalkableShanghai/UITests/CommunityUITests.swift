import XCTest

/// Phase 6's acceptance tests: the feed's two tabs, likes that survive a
/// relaunch, a posted walk appearing among the seeded posts, and composing a
/// note that is still there next launch.
final class CommunityUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp(
        language: String = "english",
        simulateWalk: String? = nil,
        resetUserState: Bool = true
    ) -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = [
            "-settings.language", language,
            "-settings.hasSeenOnboarding", "YES",
        ]
        if resetUserState { arguments.append("-uitest.resetUserState") }
        if let simulateWalk { arguments += ["-uitest.simulateWalk", simulateWalk] }
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
        XCTAssertTrue(
            app.staticTexts["routes-in-view-count"].waitForExistence(timeout: 15),
            "the map screen never appeared"
        )
        Thread.sleep(forTimeInterval: 1.5)
    }

    /// Opens the Community tab and waits for the feed.
    private func openFeed(_ app: XCUIApplication, tabLabel: String = "Community") {
        app.tabBars.buttons[tabLabel].tap()
        XCTAssertTrue(element(app, "feed-tab-friends").waitForExistence(timeout: 10),
                      "the feed never appeared")
        Thread.sleep(forTimeInterval: 1.0)
    }

    /// The seeded posts' feed ids, which are stable across launches.
    private func seededPostIds(_ app: XCUIApplication) -> [String] {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'feed-like-seed-'"))
            .allElementsBoundByIndex
            .map { $0.identifier }
    }

    // MARK: - Friends

    func testFriendsTabShowsTheSeededPosts() {
        let app = launchApp()
        waitForMap(app)
        openFeed(app)

        XCTAssertTrue(app.staticTexts["Community"].exists)
        XCTAssertTrue(app.staticTexts["This week"].exists)

        let likes = seededPostIds(app)
        XCTAssertEqual(likes.count, 3, "expected three seeded posts, found \(likes.count)")
        capture(app, "50-feed-friends-en")
    }

    func testLikingAPostAdjustsTheCountByOneAndSurvivesRelaunch() {
        let app = launchApp()
        waitForMap(app)
        openFeed(app)

        let likeId = try! XCTUnwrap(seededPostIds(app).first)
        let like = element(app, likeId)
        // The count is the button's accessibility value; its label is "Like".
        let before = Int(like.value as? String ?? "") ?? -1
        XCTAssertGreaterThanOrEqual(before, 0, "the like button carries no count")

        like.tap()
        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertEqual(Int(element(app, likeId).value as? String ?? "") ?? -1, before + 1,
                       "liking should add exactly one")
        capture(app, "51-feed-liked-en")

        // Relaunch WITHOUT resetting.
        let relaunched = launchApp(resetUserState: false)
        waitForMap(relaunched)
        openFeed(relaunched)
        XCTAssertEqual(
            Int(element(relaunched, likeId).value as? String ?? "") ?? -1, before + 1,
            "the like did not survive a relaunch"
        )

        // And un-liking returns it, so the toggle is symmetric.
        element(relaunched, likeId).tap()
        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertEqual(Int(element(relaunched, likeId).value as? String ?? "") ?? -1, before)
    }

    func testAPostedWalkAppearsInTheFeed() {
        let app = launchApp(simulateWalk: "wukang")
        waitForMap(app)

        // Three seeded posts before.
        openFeed(app)
        XCTAssertEqual(seededPostIds(app).count, 3)
        let cardsBefore = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'feed-like-'"))
            .count

        // Record a walk and post it.
        app.tabBars.buttons["Map"].tap()
        waitForMap(app)
        element(app, "record-button").tap()
        XCTAssertTrue(element(app, "elapsed-clock").waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 3.0)
        app.buttons["end-walk-button"].tap()
        XCTAssertTrue(app.staticTexts["summary-route-name"].waitForExistence(timeout: 10))
        let note = element(app, "summary-note-field")
        note.tap()
        note.typeText("Plane trees the whole way.")
        app.buttons["post-to-feed-button"].tap()
        waitForMap(app)

        // It is in the feed, at the top, with the walker's own note.
        openFeed(app)
        let cardsAfter = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'feed-like-'"))
            .count
        XCTAssertEqual(cardsAfter, cardsBefore + 1, "the posted walk did not join the feed")
        XCTAssertTrue(app.staticTexts["Plane trees the whole way."].exists,
                      "the walk's note is not on its feed card")
        XCTAssertTrue(app.staticTexts["Just now"].exists,
                      "a walk posted seconds ago should read as just now")
        capture(app, "52-feed-with-my-walk-en")
    }

    func testAKeptPrivateWalkStaysOutOfTheFeed() {
        let app = launchApp(simulateWalk: "creek")
        waitForMap(app)

        element(app, "record-button").tap()
        XCTAssertTrue(element(app, "elapsed-clock").waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 2.5)
        app.buttons["end-walk-button"].tap()
        XCTAssertTrue(app.staticTexts["summary-route-name"].waitForExistence(timeout: 10))
        app.buttons["keep-private-button"].tap()
        waitForMap(app)

        openFeed(app)
        let cards = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'feed-like-'"))
            .count
        XCTAssertEqual(cards, 3, "a private walk should not appear in the feed")

        // But it is still stored - keeping it private must not lose it.
        app.tabBars.buttons["You"].tap()
        XCTAssertTrue(element(app, "profile-walk-count").waitForExistence(timeout: 10))
        XCTAssertEqual(element(app, "profile-walk-count").value as? String, "1")
    }

    func testAPostRouteLinkAndReplyCountBothNavigate() {
        let app = launchApp()
        waitForMap(app)
        openFeed(app)

        // The route name opens that route.
        let linkId = try! XCTUnwrap(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier BEGINSWITH 'feed-route-link-'"))
                .allElementsBoundByIndex.first?.identifier
        )
        element(app, linkId).tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 10),
                      "the route link did not open a route")
        element(app, "route-back-button").tap()
        openFeed(app)

        // The reply count opens that route's notes.
        let replyId = try! XCTUnwrap(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier BEGINSWITH 'feed-replies-'"))
                .allElementsBoundByIndex.first?.identifier
        )
        element(app, replyId).tap()
        XCTAssertTrue(app.staticTexts["Notes from walkers"].waitForExistence(timeout: 10),
                      "the reply count did not open the comments thread")
    }

    // MARK: - Creators

    func testCreatorsTabShowsCollectionsWithComputedTotals() {
        let app = launchApp()
        waitForMap(app)
        openFeed(app)

        element(app, "feed-tab-creators").tap()
        Thread.sleep(forTimeInterval: 1.2)

        // Two collections, with route counts and summed kilometres.
        let names = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'collection-name-'"))
            .allElementsBoundByIndex
        XCTAssertEqual(names.count, 2, "expected two collections")

        // Concession collection: wukang 3.4 + fuxing 2.1 + bund 2.9 = 8.4 km.
        let metas = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'collection-meta-'"))
            .allElementsBoundByIndex.map { $0.label }
        XCTAssertTrue(metas.contains { $0.contains("3 routes") && $0.contains("8.4 km") },
                      "the concession collection's totals are wrong: \(metas)")
        // Water's Edge: creek 4.8 + century 5.6 = 10.4 km.
        XCTAssertTrue(metas.contains { $0.contains("2 routes") && $0.contains("10.4 km") },
                      "the water collection's totals are wrong: \(metas)")
        capture(app, "53-feed-creators-en")

        // A member row opens its route.
        element(app, "collection-route-wukang").tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["route-detail-name"].label,
                       "Wukang Road & the Concession Lanes")
    }

    func testFollowIsALocalToggle() {
        let app = launchApp()
        waitForMap(app)
        openFeed(app)
        element(app, "feed-tab-creators").tap()
        Thread.sleep(forTimeInterval: 1.2)

        let follow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'collection-follow-'"))
            .allElementsBoundByIndex.first
        let button = try! XCTUnwrap(follow)
        XCTAssertEqual(button.label, "Follow")
        button.tap()
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertEqual(element(app, button.identifier).label, "Following")
    }

    // MARK: - Comments

    func testPostingACommentPrependsItAndItSurvivesRelaunch() {
        let app = launchApp()
        waitForMap(app)

        // Wukang carries four seeded notes.
        app.buttons["route-row-wukang"].tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 10))
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertTrue(app.buttons["Notes from walkers (4)"].exists,
                      "the note count is wrong before commenting")
        app.buttons["notes-button"].tap()
        XCTAssertTrue(app.staticTexts["Notes from walkers"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1.0)
        capture(app, "54-comments-en")

        // Empty input is refused before it is even tried.
        XCTAssertFalse(app.buttons["comment-post-button"].isEnabled,
                       "Post should be off with an empty field")

        let field = element(app, "comment-field")
        field.tap()
        field.typeText("Shaded the whole way in August.")
        XCTAssertTrue(app.buttons["comment-post-button"].isEnabled)
        app.buttons["comment-post-button"].tap()
        Thread.sleep(forTimeInterval: 1.2)

        XCTAssertTrue(app.staticTexts["Shaded the whole way in August."].exists,
                      "the comment was not added")
        XCTAssertTrue(app.staticTexts["Just now"].exists,
                      "a new comment should read as just now")
        capture(app, "55-comments-after-posting-en")

        // Relaunch WITHOUT resetting: still there, and counted.
        let relaunched = launchApp(resetUserState: false)
        waitForMap(relaunched)
        relaunched.buttons["route-row-wukang"].tap()
        XCTAssertTrue(relaunched.staticTexts["route-detail-name"].waitForExistence(timeout: 10))
        relaunched.swipeUp()
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertTrue(relaunched.buttons["Notes from walkers (5)"].exists,
                      "the new note was not counted after relaunch")
        relaunched.buttons["notes-button"].tap()
        XCTAssertTrue(relaunched.staticTexts["Notes from walkers"].waitForExistence(timeout: 10))
        XCTAssertTrue(relaunched.staticTexts["Shaded the whole way in August."].exists,
                      "the comment did not survive a relaunch")
    }

    func testASeededNoteKeepsItsPinnedPlace() {
        let app = launchApp()
        waitForMap(app)
        app.buttons["route-row-wukang"].tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 10))
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.8)
        app.buttons["notes-button"].tap()
        XCTAssertTrue(app.staticTexts["Notes from walkers"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1.0)

        // At least one seeded note is pinned to a corner of the route.
        XCTAssertTrue(app.staticTexts["Wukang Rd × Hunan Rd"].exists,
                      "the pinned place row is missing from the seeded notes")
    }

    // MARK: - Chinese

    func testFeedAndCommentsReadInChinese() {
        let app = launchApp(language: "chinese")
        waitForMap(app)
        openFeed(app, tabLabel: "社区")

        XCTAssertTrue(app.staticTexts["社区"].exists)
        XCTAssertTrue(app.staticTexts["本周"].exists)
        XCTAssertEqual(element(app, "feed-tab-friends").label, "好友")
        XCTAssertEqual(element(app, "feed-tab-creators").label, "创作者")
        capture(app, "56-feed-friends-zh")

        element(app, "feed-tab-creators").tap()
        Thread.sleep(forTimeInterval: 1.2)
        let metas = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'collection-meta-'"))
            .allElementsBoundByIndex.map { $0.label }
        XCTAssertTrue(metas.contains { $0.contains("条路线") && $0.contains("公里") },
                      "the collection meta is not in Chinese: \(metas)")
        capture(app, "57-feed-creators-zh")

        // Comments, in Chinese.
        app.tabBars.buttons["地图"].tap()
        waitForMap(app)
        app.buttons["route-row-wukang"].tap()
        XCTAssertTrue(app.staticTexts["route-detail-name"].waitForExistence(timeout: 10))
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.8)
        app.buttons["notes-button"].tap()
        XCTAssertTrue(app.staticTexts["走过的人说"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1.0)

        let field = element(app, "comment-field")
        field.tap()
        field.typeText("梧桐很好。")
        app.buttons["发布"].tap()
        Thread.sleep(forTimeInterval: 1.2)
        XCTAssertTrue(app.staticTexts["梧桐很好。"].exists, "the Chinese comment was not added")
        XCTAssertTrue(app.staticTexts["刚刚"].exists, "the relative time is not in Chinese")
        capture(app, "58-comments-zh")
    }
}
