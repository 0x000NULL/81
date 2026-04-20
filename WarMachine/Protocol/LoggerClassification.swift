import Foundation

/// Single source of truth mapping `ExerciseSpec.key` → `LoggerKind`.
/// Used both by `SeedExercises` when creating fresh `ExerciseLog` rows and
/// by `LoggerKindBackfill` when reclassifying legacy (pre-V3) rows.
enum LoggerClassification {
    static func kind(for exerciseKey: String) -> LoggerKind {
        switch exerciseKey {
        // Monday — legs
        case "back-squat",
             "romanian-deadlift",
             "walking-lunge-db",
             "leg-press",
             "leg-curl",
             "calf-raise":
            return .weightReps
        case "sled-push":
            return .distanceLoad

        // Tuesday — intervals + core
        case "interval-block":
            return .cardioIntervals
        case "pallof-press":
            return .weightReps
        case "side-plank":
            return .durationHold
        case "ab-wheel-rollout":
            return .bodyweightReps

        // Wednesday — push
        case "bench-press",
             "overhead-press",
             "incline-db-press",
             "lateral-raise",
             "weighted-dip",
             "triceps-pushdown":
            return .weightReps
        case "jump-rope-finisher":
            return .jumpRopeFinisher

        // Thursday — Zone 2
        case "zone2-block":
            return .cardioSession

        // Friday — pull + carries
        case "deadlift",
             "weighted-pullup",
             "barbell-row",
             "seated-cable-row",
             "face-pull",
             "barbell-curl",
             "hammer-curl":
            return .weightReps
        case "farmers-carry",
             "suitcase-carry":
            return .distanceLoad

        // Saturday — ruck
        case "long-ruck":
            return .ruck

        default:
            return .weightReps
        }
    }

    /// Whether this exercise uses a barbell — gates the plate calculator.
    static func usesBarbell(exerciseKey: String) -> Bool {
        switch exerciseKey {
        case "back-squat",
             "romanian-deadlift",
             "bench-press",
             "overhead-press",
             "deadlift",
             "barbell-row",
             "barbell-curl":
            return true
        default:
            return false
        }
    }
}
