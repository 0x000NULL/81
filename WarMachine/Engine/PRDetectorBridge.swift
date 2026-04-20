import Foundation
import SwiftData

/// Persistence-aware wrapper over `PRDetector`. Each call:
///   1. Fetches or creates the `ExercisePRCache` row for `exerciseKey`.
///   2. Feeds the new `SetLog` into the pure detector.
///   3. Writes `set.prKinds` + cache updates back in one save.
enum PRDetectorBridge {
    @discardableResult
    static func detectAndPersist(set: SetLog,
                                 exerciseKey: String,
                                 loggerKind: LoggerKind,
                                 context: ModelContext) -> [PRKind] {
        let cache = cache(for: exerciseKey, in: context)
        let input = PRDetector.Input(
            exerciseKey: exerciseKey,
            loggerKind: loggerKind,
            setType: set.setType,
            weightLb: set.weightLb,
            reps: set.reps,
            durationSec: set.durationSec,
            distanceYards: set.distanceYards,
            distanceMiles: set.distanceMiles,
            loadLb: set.loadLb
        )
        let out = PRDetector.detect(
            input,
            priorEstimated1RM: cache.bestEstimated1RMLb,
            priorSetVolume: cache.bestSetVolumeLb,
            priorRepsAtWeight: cache.repsAtWeight(),
            priorHoldSec: cache.bestHoldSec,
            priorCarryYardsAtLoad: cache.carryYardsAtLoad(),
            priorRuckMilesAtLoad: cache.ruckMilesAtLoad()
        )
        set.prKinds = out.kinds.map(\.rawValue)
        if let v = out.updatedEstimated1RM {
            cache.bestEstimated1RMLb = v
        }
        if let v = out.updatedSetVolume {
            cache.bestSetVolumeLb = v
        }
        if let v = out.updatedRepsAtWeight {
            cache.setRepsAtWeight(v)
        }
        if let v = out.updatedHoldSec {
            cache.bestHoldSec = v
        }
        if let v = out.updatedCarryYardsAtLoad {
            cache.setCarryYardsAtLoad(v)
        }
        if let v = out.updatedRuckMilesAtLoad {
            cache.setRuckMilesAtLoad(v)
        }
        if !out.kinds.isEmpty {
            cache.lastUpdatedAt = .now
        }
        try? context.save()
        return out.kinds
    }

    private static func cache(for key: String, in context: ModelContext) -> ExercisePRCache {
        var descriptor = FetchDescriptor<ExercisePRCache>(
            predicate: #Predicate { $0.exerciseKey == key }
        )
        descriptor.fetchLimit = 1
        if let existing = (try? context.fetch(descriptor))?.first { return existing }
        let fresh = ExercisePRCache(exerciseKey: key)
        context.insert(fresh)
        return fresh
    }
}
