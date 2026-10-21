import Foundation

/// One month of the walk-range chart: when it started, and the longest single
/// walk recorded in it.
///
/// `longestKm` is zero for a month with no walks, not nil. A month you did not
/// walk is a real answer — the chart should show a gap in the run, not skip the
/// month and quietly compress the timeline.
struct MonthlyBest: Identifiable, Hashable, Sendable {
    /// Months back from the current one: 5 for the oldest, 0 for this month.
    let id: Int
    let start: Date
    let longestKm: Double
}

/// Builds the six months behind the profile's "Walk range" chart.
///
/// The source design hardcoded six bar heights. These are computed from stored
/// walks, which means the chart is empty on a fresh install — and that is the
/// correct thing for it to show, so the screen has an empty state rather than a
/// decorative default.
enum WalkRange {

    /// How many months the chart shows. Six, matching the source design's six
    /// labelled columns.
    static let monthCount = 6

    /// The longest walk in each of the last `monthCount` months, oldest first.
    ///
    /// A walk belongs to the month it *ended* in. Walks are short enough that
    /// start and end almost always agree; when they disagree — a walk over
    /// midnight on the last of the month — the end is when it was finished, and
    /// finishing is what the figure reports.
    static func lastMonths(
        walks: [StoredWalk],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [MonthlyBest] {
        let thisMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now

        return (0..<monthCount).reversed().compactMap { monthsBack in
            guard let start = calendar.date(byAdding: .month, value: -monthsBack, to: thisMonth),
                  let interval = calendar.dateInterval(of: .month, for: start)
            else { return nil }

            let longest = walks
                .filter { interval.contains($0.endedAt) }
                .map(\.distanceKm)
                .max() ?? 0

            return MonthlyBest(id: monthsBack, start: interval.start, longestKm: longest)
        }
    }

    /// The top of the chart's scale.
    ///
    /// Never zero, so an empty chart still draws its months and its baseline
    /// rather than collapsing to a line. Rounded up to the next whole kilometre
    /// so the tallest bar does not touch the ceiling.
    static func scaleTop(_ months: [MonthlyBest]) -> Double {
        let tallest = months.map(\.longestKm).max() ?? 0
        guard tallest > 0 else { return 1 }
        return (tallest * 1.15).rounded(.up)
    }
}
