import Foundation
import HealthKit

/// The Tuesday interval-block modality the user picks at the start of
/// the workout. Each case encodes its own rounds / work / rest and the
/// HealthKit activity type used when `HealthKitService.saveWorkout`
/// fires on completion.
enum IntervalModality: String, Codable, CaseIterable, Sendable, Hashable {
    case track400s
    case hillSprints
    case assaultBike
    case rower
    case treadmill
    case jumpRope
    case swim
    case bodyweightBurpees

    var label: String {
        switch self {
        case .track400s:         return "Track 400s"
        case .hillSprints:       return "Hill sprints"
        case .assaultBike:       return "Assault bike"
        case .rower:             return "Rower"
        case .treadmill:         return "Treadmill"
        case .jumpRope:          return "Jump rope"
        case .swim:              return "Swim"
        case .bodyweightBurpees: return "Bodyweight burpees"
        }
    }

    var prescription: String {
        switch self {
        case .track400s:         return "8 × 400m at 85–90%, 90 sec walking rest"
        case .hillSprints:       return "10 × 30 sec hill sprint, walk down recovery"
        case .assaultBike:       return "10 × 1 min hard / 1 min easy"
        case .rower:             return "10 × 250m hard / 90 sec easy"
        case .treadmill:         return "8 × 2 min hard / 1 min easy"
        case .jumpRope:          return "10 × 1 min fast / 30 sec rest"
        case .swim:              return "10 × 50m hard / 30 sec rest"
        case .bodyweightBurpees: return "8 rounds 30 sec burpees / 30 sec rest"
        }
    }

    var rounds: Int {
        switch self {
        case .track400s, .treadmill, .bodyweightBurpees: return 8
        case .hillSprints, .assaultBike, .rower, .jumpRope, .swim: return 10
        }
    }

    var workSec: Int {
        switch self {
        case .track400s:         return 90    // rough 400m target
        case .hillSprints:       return 30
        case .assaultBike:       return 60
        case .rower:             return 60    // ~250m effort
        case .treadmill:         return 120
        case .jumpRope:          return 60
        case .swim:              return 60    // ~50m effort
        case .bodyweightBurpees: return 30
        }
    }

    var restSec: Int {
        switch self {
        case .track400s:         return 90
        case .hillSprints:       return 60    // walk down
        case .assaultBike:       return 60
        case .rower:             return 90
        case .treadmill:         return 60
        case .jumpRope:          return 30
        case .swim:              return 30
        case .bodyweightBurpees: return 30
        }
    }

    var hkActivityType: HKWorkoutActivityType {
        switch self {
        case .track400s, .hillSprints, .treadmill: return .running
        case .assaultBike:                         return .cycling
        case .rower:                               return .rowing
        case .jumpRope:                            return .jumpRope
        case .swim:                                return .swimming
        case .bodyweightBurpees:                   return .highIntensityIntervalTraining
        }
    }
}
