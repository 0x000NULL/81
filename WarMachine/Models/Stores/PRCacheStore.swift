import Foundation
import SwiftData

/// Resolves the `ExercisePRCache` row for an `exerciseKey`. The cache
/// has high-water-mark semantics: on sync collision, take MAX of every
/// scalar field and per-key MAX inside the JSON-encoded dictionaries.
@MainActor
enum PRCacheStore {
    static func findOrCreate(exerciseKey: String, in context: ModelContext) -> ExercisePRCache {
        let descriptor = FetchDescriptor<ExercisePRCache>(
            predicate: #Predicate { $0.exerciseKey == exerciseKey }
        )
        let matches = (try? context.fetch(descriptor)) ?? []

        if let canonical = matches.first {
            for sibling in matches.dropFirst() {
                merge(sibling, into: canonical)
                context.delete(sibling)
            }
            return canonical
        }

        let fresh = ExercisePRCache(exerciseKey: exerciseKey)
        context.insert(fresh)
        return fresh
    }

    private static func merge(_ src: ExercisePRCache, into dst: ExercisePRCache) {
        dst.bestEstimated1RMLb = maxOptional(dst.bestEstimated1RMLb, src.bestEstimated1RMLb)
        dst.bestSetVolumeLb = maxOptional(dst.bestSetVolumeLb, src.bestSetVolumeLb)
        dst.bestHoldSec = maxOptional(dst.bestHoldSec, src.bestHoldSec)

        let mergedReps = mergeIntDict(dst.repsAtWeight(), src.repsAtWeight())
        if !mergedReps.isEmpty { dst.setRepsAtWeight(mergedReps) }

        let mergedCarry = mergeIntDict(dst.carryYardsAtLoad(), src.carryYardsAtLoad())
        if !mergedCarry.isEmpty { dst.setCarryYardsAtLoad(mergedCarry) }

        let mergedRuck = mergeDoubleDict(dst.ruckMilesAtLoad(), src.ruckMilesAtLoad())
        if !mergedRuck.isEmpty { dst.setRuckMilesAtLoad(mergedRuck) }

        dst.lastUpdatedAt = max(dst.lastUpdatedAt, src.lastUpdatedAt)
    }

    private static func maxOptional<T: Comparable>(_ a: T?, _ b: T?) -> T? {
        switch (a, b) {
        case let (a?, b?): return max(a, b)
        case let (a?, nil): return a
        case let (nil, b?): return b
        case (nil, nil): return nil
        }
    }

    private static func mergeIntDict(_ a: [Int: Int], _ b: [Int: Int]) -> [Int: Int] {
        var out = a
        for (k, v) in b { out[k] = max(out[k] ?? 0, v) }
        return out
    }

    private static func mergeDoubleDict(_ a: [Int: Double], _ b: [Int: Double]) -> [Int: Double] {
        var out = a
        for (k, v) in b { out[k] = max(out[k] ?? 0, v) }
        return out
    }
}
