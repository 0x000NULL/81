import Foundation

enum ProgressionEngine {

    struct Evaluation {
        let liftKey: String
        let shouldProgress: Bool
        let suggestedNewWeight: Double
        let reason: String
    }

    /// Did every working set reach the top of its rep range?
    /// Warmup and drop sets are excluded; failure sets are included.
    static func hitTopOfRange(sets: [SetLog], targetTopReps: Int) -> Bool {
        let evaluable = sets.filter { $0.setType.countsTowardProgression }
        guard !evaluable.isEmpty else { return false }
        return evaluable.allSatisfy { $0.reps >= targetTopReps }
    }

    /// Evaluate a main or accessory lift for progression.
    /// - Main lifts: one session at top → +5 upper / +10 lower.
    /// - Accessories: 2 consecutive sessions at top → +5 lb.
    static func evaluate(liftKey: String,
                         isMainLift: Bool,
                         isLowerBody: Bool,
                         currentWeight: Double,
                         thisSessionSets: [SetLog],
                         targetTopReps: Int,
                         priorConsecutiveTopSessions: Int) -> Evaluation {

        let cleanTop = hitTopOfRange(sets: thisSessionSets, targetTopReps: targetTopReps)

        if isMainLift {
            if cleanTop {
                let bump: Double = isLowerBody ? 10 : 5
                return Evaluation(
                    liftKey: liftKey,
                    shouldProgress: true,
                    suggestedNewWeight: currentWeight + bump,
                    reason: "Top of rep range cleanly. +\(Int(bump)) lb."
                )
            }
            return Evaluation(
                liftKey: liftKey,
                shouldProgress: false,
                suggestedNewWeight: currentWeight,
                reason: "Hit top next time for +\(isLowerBody ? 10 : 5) lb."
            )
        }

        // Accessory: needs 2 consecutive top sessions
        if cleanTop {
            if priorConsecutiveTopSessions + 1 >= 2 {
                return Evaluation(
                    liftKey: liftKey,
                    shouldProgress: true,
                    suggestedNewWeight: currentWeight + 5,
                    reason: "2 consecutive top sessions. +5 lb."
                )
            }
            return Evaluation(
                liftKey: liftKey,
                shouldProgress: false,
                suggestedNewWeight: currentWeight,
                reason: "One more top session for +5 lb."
            )
        }
        return Evaluation(
            liftKey: liftKey,
            shouldProgress: false,
            suggestedNewWeight: currentWeight,
            reason: "Hit top next time to start the streak."
        )
    }

    /// Ruck progression: +2.5–5 lb or +0.5 mi when distance held at target pace.
    enum RuckProgression {
        case holdLoad(newMiles: Double)
        case holdDistance(newWeight: Double)
        case none
    }

    static func evaluateRuck(currentMiles: Double,
                             currentWeightLb: Double,
                             completedDurationSeconds: Int,
                             perceivedFelt: Int) -> RuckProgression {
        let pace = Double(completedDurationSeconds) / 60.0 / max(currentMiles, 0.1)
        let madeTargetPace = pace <= 16.0 // 15 min/mi target, allow 16 for "comfortable"
        let easyEnough = perceivedFelt <= 6
        guard madeTargetPace else { return .none }

        if easyEnough && currentMiles < 12 {
            return .holdLoad(newMiles: currentMiles + 0.5)
        } else {
            return .holdDistance(newWeight: currentWeightLb + 2.5)
        }
    }
}
