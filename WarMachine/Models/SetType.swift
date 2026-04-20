import Foundation

/// Classifies a `SetLog` for progression, tonnage, and PR purposes.
///
/// Legacy rows (pre-SchemaV3) migrate as `.normal` — all historical logged
/// sets were implicitly working sets since there was no warm-up UI.
enum SetType: String, Codable, CaseIterable, Sendable, Hashable {
    case warmup
    case normal
    case failure
    case drop

    var label: String {
        switch self {
        case .warmup:  return "Warm-up"
        case .normal:  return "Normal"
        case .failure: return "Failure"
        case .drop:    return "Drop set"
        }
    }

    var systemImage: String? {
        switch self {
        case .warmup:  return "flame"
        case .normal:  return nil
        case .failure: return "flame.fill"
        case .drop:    return "arrow.down.forward.circle"
        }
    }

    var countsTowardProgression: Bool {
        self == .normal || self == .failure
    }

    var countsTowardTonnage: Bool {
        self != .warmup
    }

    var eligibleForPR: Bool {
        self == .normal || self == .failure
    }
}
