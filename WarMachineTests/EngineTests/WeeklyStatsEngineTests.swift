import Testing
import Foundation
import SwiftData
@testable import WarMachine

@Suite("WeeklyStatsEngine")
@MainActor
struct WeeklyStatsEngineTests {

    private func inMemoryContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV4.self)
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        return ModelContext(container)
    }

    /// Helper to build a Monday anchor date.
    private func monday(_ offsetWeeks: Int, from anchor: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: 7 * offsetWeeks, to: anchor)!
    }

    @Test("empty inputs produce zero-filled rows for every Monday between start and now")
    func emptyFillsWeeks() throws {
        let start = VerseEngine.weekStart(of: Date(timeIntervalSince1970: 1_700_000_000))
        let now = monday(3, from: start)
        let rows = WeeklyStatsEngine.weeklyStats(startDate: start, now: now, dailyLogs: [], sessions: [])
        #expect(rows.count == 4) // weeks 0, 1, 2, 3
        #expect(rows.allSatisfy { $0.promisesLogged == 0 && $0.workoutsCompleted == 0 })
        #expect(rows.first?.weekStartDate == start)
        #expect(rows.last?.weekStartDate == now)
    }

    @Test("promise rate = kept / logged; unlogged days excluded from denominator")
    func promiseRate() throws {
        _ = try inMemoryContext()
        let start = VerseEngine.weekStart(of: Date(timeIntervalSince1970: 1_700_000_000))
        let now = start // single-week series

        var logs: [DailyLog] = []
        // 5 logged days: 3 kept, 2 broken. 2 unlogged (promiseKept nil).
        for day in 0..<5 {
            let d = DailyLog(date: Calendar.current.date(byAdding: .day, value: day, to: start)!)
            d.promiseKept = day < 3
            logs.append(d)
        }
        for day in 5..<7 {
            logs.append(DailyLog(date: Calendar.current.date(byAdding: .day, value: day, to: start)!))
        }

        let rows = WeeklyStatsEngine.weeklyStats(startDate: start, now: now, dailyLogs: logs, sessions: [])
        #expect(rows.count == 1)
        #expect(rows[0].promisesLogged == 5)
        #expect(rows[0].promisesKept == 3)
        #expect(abs(rows[0].promiseRate - 0.6) < 0.0001)
    }

    @Test("workoutsCompleted excludes abandoned sessions and sessions without completedAt")
    func workoutFiltering() throws {
        let start = VerseEngine.weekStart(of: Date(timeIntervalSince1970: 1_700_000_000))
        let now = start

        let s1 = WorkoutSession(date: start, dayType: .legs)
        s1.completedAt = start.addingTimeInterval(3600)
        let s2 = WorkoutSession(date: start, dayType: .pull)
        s2.completedAt = start.addingTimeInterval(7200)
        s2.abandoned = true
        let s3 = WorkoutSession(date: start, dayType: .push) // no completedAt

        let rows = WeeklyStatsEngine.weeklyStats(startDate: start, now: now, dailyLogs: [], sessions: [s1, s2, s3])
        #expect(rows.count == 1)
        #expect(rows[0].workoutsCompleted == 1)
    }

    @Test("rows are bucketed by their own Monday; spillover weeks don't double-count")
    func bucketing() throws {
        let weekA = VerseEngine.weekStart(of: Date(timeIntervalSince1970: 1_700_000_000))
        let weekB = monday(1, from: weekA)

        let logA = DailyLog(date: weekA); logA.promiseKept = true
        let logB = DailyLog(date: weekB); logB.promiseKept = false
        let sA = WorkoutSession(date: weekA, dayType: .legs); sA.completedAt = weekA
        let sB = WorkoutSession(date: weekB, dayType: .push); sB.completedAt = weekB

        let rows = WeeklyStatsEngine.weeklyStats(
            startDate: weekA, now: weekB,
            dailyLogs: [logA, logB],
            sessions: [sA, sB]
        )
        #expect(rows.count == 2)
        #expect(rows[0].weekStartDate == weekA)
        #expect(rows[0].promisesKept == 1)
        #expect(rows[0].workoutsCompleted == 1)
        #expect(rows[1].weekStartDate == weekB)
        #expect(rows[1].promisesKept == 0)
        #expect(rows[1].workoutsCompleted == 1)
    }

    @Test("start mid-week: first bucket is the Monday of that week")
    func partialWeekStart() throws {
        let monday0 = VerseEngine.weekStart(of: Date(timeIntervalSince1970: 1_700_000_000))
        let midWeek = Calendar.current.date(byAdding: .day, value: 3, to: monday0)!
        let rows = WeeklyStatsEngine.weeklyStats(startDate: midWeek, now: midWeek, dailyLogs: [], sessions: [])
        #expect(rows.first?.weekStartDate == monday0)
    }
}
