import Foundation

/// Per-exercise logger shape. Stored on `ExerciseLog.loggerKindRaw`.
///
/// The protocol defines which kind each `ExerciseSpec` uses; `SeedExercises`
/// copies that onto the log row. Legacy rows (pre-SchemaV3) default to
/// `.weightReps` and are reclassified at first boot on V3 via
/// `LoggerKindBackfill`.
enum LoggerKind: String, Codable, CaseIterable, Sendable, Hashable {
    case weightReps          // barbell / DB / machine lifts
    case bodyweightReps      // ab wheel, unweighted push-ups
    case distanceLoad        // farmer's carry, suitcase carry, sled push
    case durationHold        // side plank, dead hang, hollow hold
    case cardioIntervals     // Tuesday interval block
    case cardioSession       // Thursday Zone 2 continuous
    case ruck                // Saturday long ruck
    case jumpRopeFinisher    // Wednesday 10 × 30s on / 30s off

    var label: String {
        switch self {
        case .weightReps:        return "Weight × reps"
        case .bodyweightReps:    return "Bodyweight reps"
        case .distanceLoad:      return "Distance × load"
        case .durationHold:      return "Timed hold"
        case .cardioIntervals:   return "Cardio intervals"
        case .cardioSession:     return "Cardio session"
        case .ruck:              return "Ruck"
        case .jumpRopeFinisher:  return "Jump rope finisher"
        }
    }
}
