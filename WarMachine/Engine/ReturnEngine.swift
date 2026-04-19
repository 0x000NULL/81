import Foundation

enum ReturnPolicy: Equatable {
    case continueNormally
    case resumeAtCurrent
    case restartAt(percent: Double, rebuildWeeks: Int)
    case returningFromIllness           // 80% for 2-3 sessions via rebuildMode
    case injuryFlagged(note: String?)
    case travelOrLifeGap
}

enum ReturnEngine {

    /// Evaluates the user's current state.
    static func evaluate(now: Date,
                         lastCompletedWorkout: Date?,
                         recentDailyLogs: [DailyLog],
                         userProfile: UserProfile) -> ReturnPolicy {

        // 1. Injury flag wins
        if userProfile.injuryFlag {
            return .injuryFlagged(note: userProfile.injuryNote)
        }

        // 2. Rebuild mode active → returning from illness
        if userProfile.rebuildModeRemainingSessions > 0 {
            return .returningFromIllness
        }

        guard let last = lastCompletedWorkout else {
            return .continueNormally
        }

        let daysSince = Calendar.current.dateComponents(
            [.day], from: Calendar.current.startOfDay(for: last),
            to: Calendar.current.startOfDay(for: now)
        ).day ?? 0

        if daysSince <= 2 { return .continueNormally }

        // 3. Check if recent days were mostly skipped-with-reason
        let gapDays = recentDailyLogs.filter {
            $0.date > Calendar.current.startOfDay(for: last)
            && $0.date <= Calendar.current.startOfDay(for: now)
        }
        let sickCount = gapDays.filter { $0.skippedReason == .sick }.count
        let legitCount = gapDays.filter {
            if let r = $0.skippedReason {
                return [.travel, .life, .unplannedRest].contains(r)
            }
            return false
        }.count
        let unexplainedCount = gapDays.count - sickCount - legitCount

        // Sick-dominant → illness return
        if sickCount >= 2 && sickCount > unexplainedCount {
            return .returningFromIllness
        }

        // Travel/life-dominant → resume normally
        if legitCount > unexplainedCount && legitCount > 0 {
            return .travelOrLifeGap
        }

        // Otherwise — unexplained absence, apply original Return Protocol
        switch daysSince {
        case 3...7:   return .resumeAtCurrent
        case 8...21:  return .restartAt(percent: 0.80, rebuildWeeks: 1)
        default:      return .restartAt(percent: 0.70, rebuildWeeks: 2)
        }
    }
}
