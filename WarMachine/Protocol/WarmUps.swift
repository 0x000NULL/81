import Foundation

struct WarmUpRoutine: Identifiable, Hashable, Sendable {
    let dayType: DayType
    let durationMinutes: ClosedRange<Int>
    let steps: [String]

    var id: DayType { dayType }

    var durationLabel: String {
        "\(durationMinutes.lowerBound)–\(durationMinutes.upperBound) min"
    }
}

enum WarmUps {

    static let legs = WarmUpRoutine(
        dayType: .legs,
        durationMinutes: 5...8,
        steps: [
            "Bike or row 5 minutes",
            "20 bodyweight squats",
            "10 walking lunges each leg",
            "10 glute bridges",
            "10 leg swings each direction"
        ]
    )

    static let intervals = WarmUpRoutine(
        dayType: .intervals,
        durationMinutes: 10...10,
        steps: [
            "Easy jog or bike, 10 minutes",
            "Dynamic stretching"
        ]
    )

    static let push = WarmUpRoutine(
        dayType: .push,
        durationMinutes: 5...8,
        steps: [
            "5 minutes row or bike",
            "Band pull-aparts, 2 sets of 15",
            "Light pressing sets"
        ]
    )

    static let zone2 = WarmUpRoutine(
        dayType: .zone2,
        durationMinutes: 5...5,
        steps: [
            "Start at conversation pace",
            "Settle into 180-minus-age heart rate range",
            "Nose-breathe if possible"
        ]
    )

    static let pull = WarmUpRoutine(
        dayType: .pull,
        durationMinutes: 5...8,
        steps: [
            "5 minutes row",
            "Band pull-aparts",
            "Light deadlift ramps"
        ]
    )

    static let grit = WarmUpRoutine(
        dayType: .grit,
        durationMinutes: 5...5,
        steps: [
            "Easy walk 5 minutes with unloaded pack",
            "Shoulder and hip mobility",
            "Loaded walk build-up"
        ]
    )

    static let rest = WarmUpRoutine(
        dayType: .rest,
        durationMinutes: 5...5,
        steps: [
            "Easy mobility flow"
        ]
    )

    static func of(_ dayType: DayType) -> WarmUpRoutine {
        switch dayType {
        case .legs: return legs
        case .intervals: return intervals
        case .push: return push
        case .zone2: return zone2
        case .pull: return pull
        case .grit: return grit
        case .rest: return rest
        }
    }
}
