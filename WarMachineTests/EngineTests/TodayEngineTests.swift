import Testing
import Foundation
@testable import WarMachine

@Suite("TodayEngine")
struct TodayEngineTests {

    @Test("currentWeek starts at 1 on startDate")
    func currentWeekOne() {
        let start = Date.now
        #expect(TodayEngine.currentWeek(startDate: start, now: start) == 1)
    }

    @Test("currentWeek increments after 7 days")
    func currentWeekIncrement() {
        let start = Date.now
        let day8 = Calendar.current.date(byAdding: .day, value: 7, to: start)!
        #expect(TodayEngine.currentWeek(startDate: start, now: day8) == 2)
    }

    @Test("isDeloadWeek true for 6, 12")
    func deload() {
        #expect(TodayEngine.isDeloadWeek(6))
        #expect(TodayEngine.isDeloadWeek(12))
        #expect(!TodayEngine.isDeloadWeek(5))
        #expect(!TodayEngine.isDeloadWeek(7))
    }

    @Test("UT milestone returns 4 at week 4 when never shown")
    func utMilestone() {
        let start = Date.now
        let week4 = Calendar.current.date(byAdding: .day, value: 21, to: start)!
        let result = TodayEngine.uncomfortableTruthMilestoneDue(now: week4, startDate: start, lastShownMilestone: nil)
        #expect(result == 4)
    }

    @Test("UT milestone returns nil when already shown")
    func utMilestoneAlreadyShown() {
        let start = Date.now
        let week4 = Calendar.current.date(byAdding: .day, value: 21, to: start)!
        let result = TodayEngine.uncomfortableTruthMilestoneDue(now: week4, startDate: start, lastShownMilestone: 4)
        #expect(result == nil)
    }

    @Test("cleanupStaleSessions marks yesterday's incomplete session abandoned")
    func cleanupStale() {
        let s = WorkoutSession(dayType: .legs)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: .now))!
        s.date = yesterday
        s.startedAt = yesterday
        s.completedAt = nil
        s.abandoned = false
        TodayEngine.cleanupStaleSessions([s])
        #expect(s.abandoned == true)
    }
}
