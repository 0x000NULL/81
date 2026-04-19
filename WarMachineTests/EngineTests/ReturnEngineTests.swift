import Testing
import Foundation
@testable import WarMachine

@Suite("ReturnEngine")
struct ReturnEngineTests {

    private func makeProfile(injury: Bool = false, rebuild: Int = 0) -> UserProfile {
        let p = UserProfile()
        p.injuryFlag = injury
        p.rebuildModeRemainingSessions = rebuild
        return p
    }

    @Test("injury flag wins over everything")
    func injuryFlagWins() {
        let p = makeProfile(injury: true)
        p.injuryNote = "shoulder"
        let policy = ReturnEngine.evaluate(now: .now, lastCompletedWorkout: .now, recentDailyLogs: [], userProfile: p)
        if case .injuryFlagged(let note) = policy {
            #expect(note == "shoulder")
        } else {
            Issue.record("Expected injuryFlagged")
        }
    }

    @Test("rebuild mode → returning from illness")
    func rebuildMode() {
        let p = makeProfile(rebuild: 2)
        let policy = ReturnEngine.evaluate(now: .now, lastCompletedWorkout: .now, recentDailyLogs: [], userProfile: p)
        #expect(policy == .returningFromIllness)
    }

    @Test("no prior workouts → continueNormally")
    func noHistory() {
        let p = makeProfile()
        #expect(ReturnEngine.evaluate(now: .now, lastCompletedWorkout: nil, recentDailyLogs: [], userProfile: p) == .continueNormally)
    }

    @Test("≤ 2 days gap → continueNormally")
    func smallGap() {
        let p = makeProfile()
        let yesterday = Calendar.current.date(byAdding: .day, value: -2, to: .now)!
        #expect(ReturnEngine.evaluate(now: .now, lastCompletedWorkout: yesterday, recentDailyLogs: [], userProfile: p) == .continueNormally)
    }

    @Test("3–7 days unexplained → resumeAtCurrent")
    func shortUnexplained() {
        let p = makeProfile()
        let last = Calendar.current.date(byAdding: .day, value: -5, to: .now)!
        let result = ReturnEngine.evaluate(now: .now, lastCompletedWorkout: last, recentDailyLogs: [], userProfile: p)
        #expect(result == .resumeAtCurrent)
    }

    @Test("8–21 days unexplained → restart 80% / 1 wk")
    func mediumUnexplained() {
        let p = makeProfile()
        let last = Calendar.current.date(byAdding: .day, value: -14, to: .now)!
        let result = ReturnEngine.evaluate(now: .now, lastCompletedWorkout: last, recentDailyLogs: [], userProfile: p)
        #expect(result == .restartAt(percent: 0.80, rebuildWeeks: 1))
    }

    @Test("22+ days unexplained → restart 70% / 2 wks")
    func longUnexplained() {
        let p = makeProfile()
        let last = Calendar.current.date(byAdding: .day, value: -30, to: .now)!
        let result = ReturnEngine.evaluate(now: .now, lastCompletedWorkout: last, recentDailyLogs: [], userProfile: p)
        #expect(result == .restartAt(percent: 0.70, rebuildWeeks: 2))
    }

    @Test("sick-dominated gap → returningFromIllness")
    func sickGap() {
        let p = makeProfile()
        let last = Calendar.current.date(byAdding: .day, value: -10, to: .now)!
        var logs: [DailyLog] = []
        for i in 1...5 {
            let d = Calendar.current.date(byAdding: .day, value: -i, to: .now)!
            let dl = DailyLog(date: d)
            dl.skippedReason = .sick
            logs.append(dl)
        }
        let result = ReturnEngine.evaluate(now: .now, lastCompletedWorkout: last, recentDailyLogs: logs, userProfile: p)
        #expect(result == .returningFromIllness)
    }

    @Test("travel-dominated gap → travelOrLifeGap")
    func travelGap() {
        let p = makeProfile()
        let last = Calendar.current.date(byAdding: .day, value: -10, to: .now)!
        var logs: [DailyLog] = []
        for i in 1...5 {
            let d = Calendar.current.date(byAdding: .day, value: -i, to: .now)!
            let dl = DailyLog(date: d)
            dl.skippedReason = .travel
            logs.append(dl)
        }
        let result = ReturnEngine.evaluate(now: .now, lastCompletedWorkout: last, recentDailyLogs: logs, userProfile: p)
        #expect(result == .travelOrLifeGap)
    }
}
