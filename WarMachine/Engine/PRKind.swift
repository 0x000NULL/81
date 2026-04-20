import Foundation

/// The kinds of personal record a completed set can establish.
///
/// Stored on `SetLog.prKinds` as raw values at check-in time so Summary
/// views don't recompute. Detector lives in `PRDetector`.
enum PRKind: String, Codable, CaseIterable, Sendable, Hashable {
    case estimated1RM        // Epley: weight * (1 + reps/30)
    case volume              // single-set weight * reps
    case repsAtWeight        // more reps than prior best at this weight
    case longestHoldSec      // durationHold
    case furthestCarryAtLoad // distanceLoad — more yards at >= this load
    case furthestRuckAtLoad  // ruck — more miles at >= this load

    var label: String {
        switch self {
        case .estimated1RM:        return "1RM"
        case .volume:              return "Volume"
        case .repsAtWeight:        return "Reps"
        case .longestHoldSec:      return "Hold"
        case .furthestCarryAtLoad: return "Distance"
        case .furthestRuckAtLoad:  return "Ruck"
        }
    }

    var shortBadge: String { "PR" }
}
