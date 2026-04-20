import Foundation

/// Detects whether a newly-completed set clears any PR thresholds
/// recorded in `ExercisePRCache`. Purely functional — the caller is
/// responsible for persisting the returned cache updates.
///
/// Warm-up and drop-set rows never produce PRs; failure sets are
/// eligible (a rep PR at failure is still a PR).
enum PRDetector {

    struct Input {
        let exerciseKey: String
        let loggerKind: LoggerKind
        let setType: SetType
        let weightLb: Double?
        let reps: Int?
        let durationSec: Int?
        let distanceYards: Int?
        let distanceMiles: Double?
        let loadLb: Double?
    }

    struct Output {
        let kinds: [PRKind]
        let updatedEstimated1RM: Double?
        let updatedSetVolume: Double?
        let updatedRepsAtWeight: [Int: Int]?
        let updatedHoldSec: Int?
        let updatedCarryYardsAtLoad: [Int: Int]?
        let updatedRuckMilesAtLoad: [Int: Double]?
    }

    /// Epley estimator (lifted from the canonical formulation).
    static func estimated1RM(weightLb: Double, reps: Int) -> Double {
        guard reps > 0 else { return 0 }
        if reps == 1 { return weightLb }
        return weightLb * (1.0 + Double(reps) / 30.0)
    }

    static func detect(_ input: Input,
                       priorEstimated1RM: Double?,
                       priorSetVolume: Double?,
                       priorRepsAtWeight: [Int: Int],
                       priorHoldSec: Int?,
                       priorCarryYardsAtLoad: [Int: Int],
                       priorRuckMilesAtLoad: [Int: Double]) -> Output {
        guard input.setType.eligibleForPR else {
            return Output(kinds: [],
                          updatedEstimated1RM: nil,
                          updatedSetVolume: nil,
                          updatedRepsAtWeight: nil,
                          updatedHoldSec: nil,
                          updatedCarryYardsAtLoad: nil,
                          updatedRuckMilesAtLoad: nil)
        }

        var kinds: [PRKind] = []
        var newEstimated1RM: Double?
        var newVolume: Double?
        var newRepsAtWeight: [Int: Int]?
        var newHold: Int?
        var newCarry: [Int: Int]?
        var newRuck: [Int: Double]?

        switch input.loggerKind {
        case .weightReps:
            guard let w = input.weightLb, let r = input.reps, w > 0, r > 0 else { break }
            let est = estimated1RM(weightLb: w, reps: r)
            if est > (priorEstimated1RM ?? 0) + 0.01 {
                kinds.append(.estimated1RM)
                newEstimated1RM = est
            }
            let vol = w * Double(r)
            if vol > (priorSetVolume ?? 0) + 0.01 {
                kinds.append(.volume)
                newVolume = vol
            }
            let key = Int(w.rounded())
            let priorReps = priorRepsAtWeight[key] ?? 0
            if r > priorReps {
                kinds.append(.repsAtWeight)
                var map = priorRepsAtWeight
                map[key] = r
                newRepsAtWeight = map
            }

        case .bodyweightReps:
            guard let r = input.reps, r > 0 else { break }
            // No weight — track reps-at-weight keyed at 0 (bodyweight) and
            // set-volume as reps (weightLb == 0 so volume == 0, skip).
            let key = 0
            let priorReps = priorRepsAtWeight[key] ?? 0
            if r > priorReps {
                kinds.append(.repsAtWeight)
                var map = priorRepsAtWeight
                map[key] = r
                newRepsAtWeight = map
            }

        case .durationHold:
            guard let secs = input.durationSec, secs > 0 else { break }
            if secs > (priorHoldSec ?? 0) {
                kinds.append(.longestHoldSec)
                newHold = secs
            }

        case .distanceLoad:
            guard let yd = input.distanceYards,
                  let load = input.loadLb,
                  yd > 0, load > 0 else { break }
            let key = Int(load.rounded())
            let priorYd = priorCarryYardsAtLoad[key] ?? 0
            if yd > priorYd {
                kinds.append(.furthestCarryAtLoad)
                var map = priorCarryYardsAtLoad
                map[key] = yd
                newCarry = map
            }

        case .ruck:
            guard let miles = input.distanceMiles,
                  let load = input.loadLb,
                  miles > 0, load > 0 else { break }
            let key = Int(load.rounded())
            let priorMi = priorRuckMilesAtLoad[key] ?? 0
            if miles > priorMi + 0.001 {
                kinds.append(.furthestRuckAtLoad)
                var map = priorRuckMilesAtLoad
                map[key] = miles
                newRuck = map
            }

        case .cardioIntervals, .cardioSession, .jumpRopeFinisher:
            // Too noisy (HR-dependent) to badge as a PR.
            break
        }

        return Output(
            kinds: kinds,
            updatedEstimated1RM: newEstimated1RM,
            updatedSetVolume: newVolume,
            updatedRepsAtWeight: newRepsAtWeight,
            updatedHoldSec: newHold,
            updatedCarryYardsAtLoad: newCarry,
            updatedRuckMilesAtLoad: newRuck
        )
    }
}
