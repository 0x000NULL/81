import Foundation
import SwiftData

/// Persistent high-water-mark cache keyed by `exerciseKey`. Written on
/// every checked set that clears a record; read by `PRDetector` to decide
/// if the incoming set is itself a PR.
///
/// High-water-mark semantics: on uncheck/delete, the cache is NOT rolled
/// back. A full rebuild from `SetLog` history runs on import and via the
/// "Reset PR cache" Settings action.
@Model
final class ExercisePRCache {
    var exerciseKey: String = ""
    var bestEstimated1RMLb: Double?
    var bestSetVolumeLb: Double?

    /// JSON-encoded `[Int: Int]` mapping whole-pound weight → best reps
    /// at that exact weight. Stored as Data because SwiftData doesn't
    /// persist dictionaries directly.
    var bestRepsAtWeightJSON: Data?

    var bestHoldSec: Int?

    /// JSON-encoded `[Int: Int]` mapping whole-pound load → best yards
    /// at that load.
    var bestCarryYardsAtLoadJSON: Data?

    /// JSON-encoded `[Int: Double]` mapping whole-pound ruck load → best
    /// miles at that load.
    var bestRuckMilesAtLoadJSON: Data?

    var lastUpdatedAt: Date = Date.now

    init(exerciseKey: String) {
        self.exerciseKey = exerciseKey
    }
}

extension ExercisePRCache {
    func repsAtWeight() -> [Int: Int] {
        guard let data = bestRepsAtWeightJSON else { return [:] }
        return (try? JSONDecoder().decode([Int: Int].self, from: data)) ?? [:]
    }

    func setRepsAtWeight(_ map: [Int: Int]) {
        bestRepsAtWeightJSON = try? JSONEncoder().encode(map)
    }

    func carryYardsAtLoad() -> [Int: Int] {
        guard let data = bestCarryYardsAtLoadJSON else { return [:] }
        return (try? JSONDecoder().decode([Int: Int].self, from: data)) ?? [:]
    }

    func setCarryYardsAtLoad(_ map: [Int: Int]) {
        bestCarryYardsAtLoadJSON = try? JSONEncoder().encode(map)
    }

    func ruckMilesAtLoad() -> [Int: Double] {
        guard let data = bestRuckMilesAtLoadJSON else { return [:] }
        return (try? JSONDecoder().decode([Int: Double].self, from: data)) ?? [:]
    }

    func setRuckMilesAtLoad(_ map: [Int: Double]) {
        bestRuckMilesAtLoadJSON = try? JSONEncoder().encode(map)
    }
}
