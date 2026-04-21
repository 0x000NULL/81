import Foundation

struct WeeklyStats: Equatable {
    /// Monday-normalized start of the week.
    let weekStartDate: Date
    /// DailyLog rows in this week where `promiseKept != nil`.
    let promisesLogged: Int
    let promisesKept: Int
    /// kept/logged. 0 when nothing was logged (so chart shows a visible 0,
    /// not a gap — avoids misleading the eye into thinking the user just
    /// hasn't opened the app).
    let promiseRate: Double
    /// WorkoutSession rows with `completedAt != nil` and `abandoned == false`.
    let workoutsCompleted: Int
}

/// Builds a per-week stats series spanning the user's program from
/// `startDate` (or the Monday it falls in) through the Monday of `now`.
/// Empty weeks still surface as zero-valued rows.
enum WeeklyStatsEngine {

    static func weeklyStats(
        startDate: Date,
        now: Date = .now,
        dailyLogs: [DailyLog],
        sessions: [WorkoutSession]
    ) -> [WeeklyStats] {
        let firstMonday = VerseEngine.weekStart(of: startDate)
        let lastMonday = VerseEngine.weekStart(of: now)
        guard firstMonday <= lastMonday else { return [] }

        let cal = Calendar.current
        var buckets: [WeeklyStats] = []
        var cursor = firstMonday

        // Pre-bucket inputs by week for O(rows + weeks) total.
        var logsByWeek: [Date: [DailyLog]] = [:]
        for log in dailyLogs {
            let key = VerseEngine.weekStart(of: log.date)
            logsByWeek[key, default: []].append(log)
        }
        var sessionsByWeek: [Date: [WorkoutSession]] = [:]
        for s in sessions {
            let key = VerseEngine.weekStart(of: s.date)
            sessionsByWeek[key, default: []].append(s)
        }

        while cursor <= lastMonday {
            let logs = logsByWeek[cursor] ?? []
            let sess = sessionsByWeek[cursor] ?? []
            let logged = logs.filter { $0.promiseKept != nil }.count
            let kept = logs.filter { $0.promiseKept == true }.count
            let rate = logged > 0 ? Double(kept) / Double(logged) : 0
            let completed = sess.filter { $0.completedAt != nil && !$0.abandoned }.count

            buckets.append(WeeklyStats(
                weekStartDate: cursor,
                promisesLogged: logged,
                promisesKept: kept,
                promiseRate: rate,
                workoutsCompleted: completed
            ))

            guard let next = cal.date(byAdding: .day, value: 7, to: cursor) else { break }
            cursor = next
        }
        return buckets
    }
}
