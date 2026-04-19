import Foundation
import SwiftData

enum TodayEngine {

    /// Current program week (1-based). Week 1 contains the startDate.
    static func currentWeek(startDate: Date, now: Date = .now) -> Int {
        DateHelpers.weekNumber(start: startDate, on: now)
    }

    /// Deload weeks: 6 and 12 (every 5–6 weeks after a 5-week block).
    static func isDeloadWeek(_ weekNumber: Int) -> Bool {
        weekNumber == 6 || weekNumber == 12
    }

    static func dayType(on date: Date = .now) -> DayType {
        TrainingSchedule.dayType(on: date)
    }

    /// True if a baseline test is due (week 4, 8, or 12 and no test yet this week).
    static func baselineDue(weekNumber: Int, recentTests: [BaselineTest]) -> Bool {
        let milestones = [4, 8, 12]
        guard milestones.contains(weekNumber) else { return false }
        return !recentTests.contains { $0.weekNumber == weekNumber }
    }

    /// Returns the most recent incomplete (not completedAt, not abandoned) WorkoutSession dated today.
    static func incompleteWorkout(in sessions: [WorkoutSession], on date: Date = .now) -> WorkoutSession? {
        let today = Calendar.current.startOfDay(for: date)
        return sessions
            .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            .filter { $0.completedAt == nil && !$0.abandoned }
            .sorted { ($0.startedAt ?? $0.date) > ($1.startedAt ?? $1.date) }
            .first
    }

    /// Cleans up sessions from yesterday or earlier that were started but never completed.
    /// Sets abandoned = true. Mutates in place; caller saves context.
    static func cleanupStaleSessions(_ sessions: [WorkoutSession], now: Date = .now) {
        let today = Calendar.current.startOfDay(for: now)
        for session in sessions
        where session.completedAt == nil && !session.abandoned
            && session.date < today {
            session.abandoned = true
        }
    }

    /// True if today is the first open on or after week 4, 8, or 12 that hasn't been shown yet.
    static func uncomfortableTruthMilestoneDue(now: Date,
                                               startDate: Date,
                                               lastShownMilestone: Int?) -> Int? {
        let week = currentWeek(startDate: startDate, now: now)
        for m in UncomfortableTruth.milestoneWeeks where week >= m {
            if (lastShownMilestone ?? 0) < m {
                return m
            }
        }
        return nil
    }
}
