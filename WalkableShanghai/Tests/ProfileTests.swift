import XCTest
import SwiftData
@testable import WalkableShanghai

/// The walk-range chart's arithmetic, and the plural rules the interface needs
/// to count things without embarrassing itself.
@MainActor
final class ProfileTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    /// A fixed "now" so the six months the chart covers are the same on every
    /// run. A test that depends on the real date fails once a month.
    private var now: Date {
        DateComponents(
            calendar: calendar, year: 2026, month: 8, day: 15, hour: 12
        ).date!
    }

    private func walk(monthsAgo: Int, km: Double, day: Int = 10) -> StoredWalk {
        let month = calendar.date(byAdding: .month, value: -monthsAgo, to: now)!
        var components = calendar.dateComponents([.year, .month], from: month)
        components.day = day
        components.hour = 9
        let ended = calendar.date(from: components)!
        return StoredWalk(
            routeId: "wukang",
            startedAt: ended.addingTimeInterval(-1800),
            endedAt: ended,
            distanceMeters: km * 1000,
            elapsedSeconds: 1800
        )
    }

    // MARK: - The six months

    func testTheChartCoversSixMonthsOldestFirst() {
        let months = WalkRange.lastMonths(walks: [], now: now, calendar: calendar)

        XCTAssertEqual(months.count, 6)
        // Oldest first, so the chart reads left to right as time passing.
        XCTAssertEqual(months.map(\.id), [5, 4, 3, 2, 1, 0])
        for (earlier, later) in zip(months, months.dropFirst()) {
            XCTAssertLessThan(earlier.start, later.start)
        }
        // The last column is the month "now" falls in.
        XCTAssertEqual(calendar.component(.month, from: months.last!.start), 8)
        XCTAssertEqual(calendar.component(.month, from: months.first!.start), 3)
    }

    func testAMonthReportsItsLongestWalkNotItsTotal() {
        let walks = [
            walk(monthsAgo: 1, km: 3.0, day: 4),
            walk(monthsAgo: 1, km: 8.2, day: 11),
            walk(monthsAgo: 1, km: 5.5, day: 20),
        ]
        let months = WalkRange.lastMonths(walks: walks, now: now, calendar: calendar)
        let lastMonth = try! XCTUnwrap(months.first { $0.id == 1 })

        // The chart is "walk range" — the longest single walk. Summing them
        // would answer a different question, and a much less interesting one.
        XCTAssertEqual(lastMonth.longestKm, 8.2, accuracy: 0.001)
    }

    func testAMonthWithNoWalksIsZeroRatherThanMissing() {
        let months = WalkRange.lastMonths(
            walks: [walk(monthsAgo: 0, km: 4.0)], now: now, calendar: calendar
        )
        XCTAssertEqual(months.count, 6, "an empty month must keep its column")
        XCTAssertEqual(months.first { $0.id == 3 }?.longestKm, 0)
        XCTAssertEqual(months.first { $0.id == 0 }?.longestKm, 4.0)
    }

    func testWalksOlderThanTheWindowAreLeftOut() {
        let months = WalkRange.lastMonths(
            walks: [walk(monthsAgo: 9, km: 20.0)], now: now, calendar: calendar
        )
        XCTAssertTrue(months.allSatisfy { $0.longestKm == 0 },
                      "a walk from outside the window leaked into the chart")
    }

    func testTheScaleNeverCollapsesToZero() {
        let empty = WalkRange.lastMonths(walks: [], now: now, calendar: calendar)
        XCTAssertGreaterThan(WalkRange.scaleTop(empty), 0,
                             "an empty chart would have no height to draw in")

        let months = WalkRange.lastMonths(
            walks: [walk(monthsAgo: 2, km: 8.2)], now: now, calendar: calendar
        )
        // Headroom above the tallest bar, so it does not touch the ceiling.
        XCTAssertGreaterThan(WalkRange.scaleTop(months), 8.2)
    }

    // MARK: - The four profile figures

    func testTheProfileFiguresComeFromStoredRecords() throws {
        let container = try UserStateContainer.make(inMemory: true)
        let store = WalkStore(container: container, resetForTests: true)

        XCTAssertEqual(store.walkCount, 0)
        XCTAssertEqual(store.totalKm, 0)
        XCTAssertNil(store.bestDistanceMeters)
        XCTAssertEqual(store.draftRoutes.count, 0)

        store.record(routeId: "wukang", startedAt: now.addingTimeInterval(-1800),
                     endedAt: now, distanceMeters: 3400, elapsedSeconds: 1800,
                     note: "", photo: nil)
        store.record(routeId: "creek", startedAt: now.addingTimeInterval(-3600),
                     endedAt: now, distanceMeters: 8200, elapsedSeconds: 3600,
                     note: "", photo: nil)
        store.saveDraftRoute(name: "Mine", coordinates: [])

        XCTAssertEqual(store.walkCount, 2)
        XCTAssertEqual(store.totalKm, 11.6, accuracy: 0.001)
        XCTAssertEqual(store.bestDistanceMeters, 8200)
        XCTAssertEqual(store.draftRoutes.count, 1)
    }

    // MARK: - Plurals

    /// English needs two forms and Chinese needs one. Both come out of the
    /// String Catalog, resolved against the *app's* language rather than the
    /// phone's — this app can run in Chinese on an English phone.
    func testCountedStringsUseTheRightPluralForm() {
        XCTAssertEqual("builder.points".localized(.english, count: 1), "1 point")
        XCTAssertEqual("builder.points".localized(.english, count: 5), "5 points")
    }

    /// The plural halves are composed back into the sentences that carry them,
    /// so the whole line has to read correctly, not just the fragment.
    func testComposedSentencesReadCorrectlyAtOne() {
        let tally = "builder.tally".localized(
            .english, "builder.points".localized(.english, count: 1), "0.4"
        )
        XCTAssertEqual(tally, "1 point · 0.4 km")
    }

    func testTheShareMessageCarriesTheRouteAndItsFigures() {
        for language in [AppLanguage.english, .chinese] {
            let message = "route.share.message".localized(
                language, "Wukang Road & the Concession Lanes", "3.4", "52"
            )
            XCTAssertTrue(message.contains("Wukang Road & the Concession Lanes"), message)
            XCTAssertTrue(message.contains("3.4"), message)
            XCTAssertTrue(message.contains("52"), message)
            XCTAssertFalse(message.contains("dead end"), message)
            XCTAssertFalse(message.contains("断点"), message)
        }
    }
}
