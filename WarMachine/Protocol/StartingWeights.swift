import Foundation

enum StartingWeights {

    /// Returns the starting working weight (lbs) for a given lift.
    /// `bodyweight` is in pounds.
    static func weight(for liftKey: String,
                       level: TrainingLevel,
                       bodyweight bw: Double) -> Double {

        func round5(_ x: Double) -> Double { max(0, (x / 5.0).rounded() * 5.0) }
        func round25(_ x: Double) -> Double { max(0, (x / 2.5).rounded() * 2.5) }

        switch liftKey {
        // Main lifts (barbell, bodyweight multipliers)
        case "back-squat":
            return round5(bw * [.beginner: 1.00, .intermediate: 1.25, .advanced: 1.50][level]!)
        case "bench-press":
            return round5(bw * [.beginner: 0.60, .intermediate: 0.80, .advanced: 1.00][level]!)
        case "deadlift":
            return round5(bw * [.beginner: 1.25, .intermediate: 1.50, .advanced: 1.85][level]!)
        case "overhead-press":
            return round5(bw * [.beginner: 0.40, .intermediate: 0.55, .advanced: 0.65][level]!)
        case "barbell-row":
            return round5(bw * [.beginner: 0.50, .intermediate: 0.70, .advanced: 0.80][level]!)
        case "weighted-pullup":
            // Added weight on top of bodyweight. Beginners & intermediates start unweighted.
            return level == .advanced ? round5(bw * 0.10) : 0

        // Accessory lower
        case "romanian-deadlift":
            return round5(weight(for: "deadlift", level: level, bodyweight: bw) * 0.70)
        case "walking-lunge-db":   // per dumbbell
            return [.beginner: 20, .intermediate: 25, .advanced: 35][level]!
        case "leg-press":
            return round5(weight(for: "back-squat", level: level, bodyweight: bw) * 1.50)
        case "leg-curl":
            return [.beginner: 40, .intermediate: 60, .advanced: 80][level]!
        case "calf-raise":
            return round5(weight(for: "back-squat", level: level, bodyweight: bw) * 0.50)

        // Accessory upper push
        case "incline-db-press":   // per dumbbell
            return round25(weight(for: "bench-press", level: level, bodyweight: bw) * 0.25)
        case "lateral-raise":      // per dumbbell
            return [.beginner: 10.0, .intermediate: 12.5, .advanced: 15.0][level]!
        case "weighted-dip":
            return level == .advanced ? 25 : 0
        case "triceps-pushdown":
            return round5(bw * 0.25)

        // Accessory upper pull
        case "seated-cable-row":
            return round5(bw * 0.60)
        case "face-pull":
            return [.beginner: 25, .intermediate: 35, .advanced: 45][level]!
        case "barbell-curl":
            return round5(bw * 0.30)
        case "hammer-curl":        // per dumbbell
            return [.beginner: 15, .intermediate: 20, .advanced: 30][level]!

        // Carries (per hand unless noted)
        case "farmers-carry":
            return round5(bw * 0.50)
        case "suitcase-carry":
            return round5(bw * 0.40)

        // Ruck starting load
        case "ruck-load":
            return [.beginner: 20, .intermediate: 35, .advanced: 45][level]!

        default:
            return 0
        }
    }

    /// All lift keys that get seeded into LiftProgression on onboarding.
    static let allLiftKeys: [(key: String, name: String, isMain: Bool)] = [
        ("back-squat", "Back squat", true),
        ("bench-press", "Bench press", true),
        ("deadlift", "Deadlift", true),
        ("overhead-press", "Overhead press", true),
        ("barbell-row", "Barbell row", true),
        ("weighted-pullup", "Weighted pull-up", true),

        ("romanian-deadlift", "Romanian deadlift", false),
        ("walking-lunge-db", "Walking lunges (DB)", false),
        ("leg-press", "Leg press", false),
        ("leg-curl", "Leg curl", false),
        ("calf-raise", "Calf raise", false),

        ("incline-db-press", "Incline DB press", false),
        ("lateral-raise", "Lateral raise", false),
        ("weighted-dip", "Weighted dips", false),
        ("triceps-pushdown", "Triceps pushdown", false),

        ("seated-cable-row", "Seated cable row", false),
        ("face-pull", "Face pull", false),
        ("barbell-curl", "Barbell curl", false),
        ("hammer-curl", "Hammer curl", false),

        ("farmers-carry", "Farmer's carry", false),
        ("suitcase-carry", "Suitcase carry", false),

        ("ruck-load", "Ruck load", false)
    ]
}
