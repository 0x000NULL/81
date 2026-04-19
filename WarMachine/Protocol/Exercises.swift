import Foundation

struct ExerciseSpec: Identifiable, Hashable, Sendable {
    let key: String
    let displayName: String
    let orderIndex: Int
    let setsText: String          // e.g., "4 × 4–6"
    let targetSets: Int
    let targetRepsMin: Int
    let targetRepsMax: Int
    let restSeconds: Int
    let alternatives: [String]
    let isMainLift: Bool
    let dayType: DayType
    let travelAlternative: String?  // used when Travel Mode is on

    var id: String { key }
}

enum Exercises {

    // MARK: - Monday (Legs)
    static let monday: [ExerciseSpec] = [
        ExerciseSpec(
            key: "back-squat",
            displayName: "Back squat",
            orderIndex: 1,
            setsText: "4 × 4–6",
            targetSets: 4, targetRepsMin: 4, targetRepsMax: 6,
            restSeconds: 180,
            alternatives: ["Front squat", "Safety bar squat", "Goblet squat", "Bulgarian split squat"],
            isMainLift: true,
            dayType: .legs,
            travelAlternative: "Bulgarian split squat (bodyweight)"
        ),
        ExerciseSpec(
            key: "romanian-deadlift",
            displayName: "Romanian deadlift",
            orderIndex: 2,
            setsText: "3 × 6–8",
            targetSets: 3, targetRepsMin: 6, targetRepsMax: 8,
            restSeconds: 120,
            alternatives: ["Dumbbell RDL", "Single-leg RDL", "Good morning", "Hip thrust"],
            isMainLift: false,
            dayType: .legs,
            travelAlternative: "Single-leg RDL (bodyweight)"
        ),
        ExerciseSpec(
            key: "walking-lunge-db",
            displayName: "Walking lunges (DB)",
            orderIndex: 3,
            setsText: "3 × 10 each leg",
            targetSets: 3, targetRepsMin: 10, targetRepsMax: 10,
            restSeconds: 90,
            alternatives: ["Reverse lunge", "Step-up", "Split squat", "Bulgarian split squat"],
            isMainLift: false,
            dayType: .legs,
            travelAlternative: "Walking lunge (bodyweight)"
        ),
        ExerciseSpec(
            key: "leg-press",
            displayName: "Leg press",
            orderIndex: 4,
            setsText: "3 × 10–12",
            targetSets: 3, targetRepsMin: 10, targetRepsMax: 12,
            restSeconds: 90,
            alternatives: ["Hack squat", "Goblet squat", "Heel-elevated squat", "Belt squat"],
            isMainLift: false,
            dayType: .legs,
            travelAlternative: "Heel-elevated goblet squat"
        ),
        ExerciseSpec(
            key: "leg-curl",
            displayName: "Leg curl",
            orderIndex: 5,
            setsText: "3 × 12",
            targetSets: 3, targetRepsMin: 12, targetRepsMax: 12,
            restSeconds: 60,
            alternatives: ["Nordic curl", "Swiss ball curl", "Glute-ham raise", "Single-leg bridge"],
            isMainLift: false,
            dayType: .legs,
            travelAlternative: "Single-leg bridge"
        ),
        ExerciseSpec(
            key: "calf-raise",
            displayName: "Standing calf raise",
            orderIndex: 6,
            setsText: "4 × 12–15",
            targetSets: 4, targetRepsMin: 12, targetRepsMax: 15,
            restSeconds: 60,
            alternatives: ["Seated calf raise", "Single-leg calf raise", "Donkey calf raise"],
            isMainLift: false,
            dayType: .legs,
            travelAlternative: "Single-leg calf raise"
        ),
        ExerciseSpec(
            key: "sled-push",
            displayName: "Sled push (finisher)",
            orderIndex: 7,
            setsText: "6 × 20 yards heavy",
            targetSets: 6, targetRepsMin: 1, targetRepsMax: 1,
            restSeconds: 90,
            alternatives: ["Prowler", "Heavy farmer's carries", "Weighted step-ups", "Assault bike sprints"],
            isMainLift: false,
            dayType: .legs,
            travelAlternative: "Assault bike sprints"
        )
    ]

    // MARK: - Wednesday (Push)
    static let wednesday: [ExerciseSpec] = [
        ExerciseSpec(
            key: "bench-press",
            displayName: "Barbell bench press",
            orderIndex: 1,
            setsText: "4 × 4–6",
            targetSets: 4, targetRepsMin: 4, targetRepsMax: 6,
            restSeconds: 180,
            alternatives: ["DB bench", "Floor press", "Incline bench", "Weighted push-up"],
            isMainLift: true,
            dayType: .push,
            travelAlternative: "Weighted push-up"
        ),
        ExerciseSpec(
            key: "overhead-press",
            displayName: "Standing overhead press",
            orderIndex: 2,
            setsText: "4 × 6–8",
            targetSets: 4, targetRepsMin: 6, targetRepsMax: 8,
            restSeconds: 120,
            alternatives: ["DB shoulder press", "Seated press", "Landmine press", "Push press"],
            isMainLift: true,
            dayType: .push,
            travelAlternative: "Pike push-up"
        ),
        ExerciseSpec(
            key: "incline-db-press",
            displayName: "Incline DB press",
            orderIndex: 3,
            setsText: "3 × 8–10",
            targetSets: 3, targetRepsMin: 8, targetRepsMax: 10,
            restSeconds: 90,
            alternatives: ["Incline barbell", "Incline machine", "Decline push-up", "Svend press"],
            isMainLift: false,
            dayType: .push,
            travelAlternative: "Decline push-up"
        ),
        ExerciseSpec(
            key: "lateral-raise",
            displayName: "Lateral raise",
            orderIndex: 4,
            setsText: "3 × 12–15",
            targetSets: 3, targetRepsMin: 12, targetRepsMax: 15,
            restSeconds: 60,
            alternatives: ["Cable lateral", "Machine lateral", "Band lateral", "Leaning lateral"],
            isMainLift: false,
            dayType: .push,
            travelAlternative: "Band lateral"
        ),
        ExerciseSpec(
            key: "weighted-dip",
            displayName: "Weighted dips",
            orderIndex: 5,
            setsText: "3 × 8–12",
            targetSets: 3, targetRepsMin: 8, targetRepsMax: 12,
            restSeconds: 90,
            alternatives: ["Bench dip", "Close-grip bench", "Ring dip", "Parallette dip"],
            isMainLift: false,
            dayType: .push,
            travelAlternative: "Bench dip"
        ),
        ExerciseSpec(
            key: "triceps-pushdown",
            displayName: "Triceps rope pushdown",
            orderIndex: 6,
            setsText: "3 × 12–15",
            targetSets: 3, targetRepsMin: 12, targetRepsMax: 15,
            restSeconds: 60,
            alternatives: ["Skull crusher", "Overhead extension", "Diamond push-up", "Close-grip bench"],
            isMainLift: false,
            dayType: .push,
            travelAlternative: "Diamond push-up"
        ),
        ExerciseSpec(
            key: "jump-rope-finisher",
            displayName: "Jump rope (finisher)",
            orderIndex: 7,
            setsText: "10 min, 30s on / 30s off",
            targetSets: 10, targetRepsMin: 1, targetRepsMax: 1,
            restSeconds: 30,
            alternatives: ["Shadow boxing", "Battle ropes", "Mountain climbers", "Bike sprints"],
            isMainLift: false,
            dayType: .push,
            travelAlternative: "Mountain climbers"
        )
    ]

    // MARK: - Friday (Pull + Carries)
    static let friday: [ExerciseSpec] = [
        ExerciseSpec(
            key: "deadlift",
            displayName: "Deadlift (conventional or trap bar)",
            orderIndex: 1,
            setsText: "4 × 3–5",
            targetSets: 4, targetRepsMin: 3, targetRepsMax: 5,
            restSeconds: 180,
            alternatives: ["Sumo deadlift", "Rack pull", "Romanian deadlift", "Kettlebell swing (heavy)"],
            isMainLift: true,
            dayType: .pull,
            travelAlternative: "Heavy kettlebell swing"
        ),
        ExerciseSpec(
            key: "weighted-pullup",
            displayName: "Weighted pull-ups",
            orderIndex: 2,
            setsText: "4 × 5–8",
            targetSets: 4, targetRepsMin: 5, targetRepsMax: 8,
            restSeconds: 120,
            alternatives: ["Bodyweight pull-up", "Lat pulldown", "Assisted pull-up", "Inverted row"],
            isMainLift: true,
            dayType: .pull,
            travelAlternative: "Inverted row"
        ),
        ExerciseSpec(
            key: "barbell-row",
            displayName: "Barbell row",
            orderIndex: 3,
            setsText: "4 × 6–8",
            targetSets: 4, targetRepsMin: 6, targetRepsMax: 8,
            restSeconds: 120,
            alternatives: ["Pendlay row", "T-bar row", "Seal row", "Chest-supported DB row"],
            isMainLift: true,
            dayType: .pull,
            travelAlternative: "Chest-supported DB row"
        ),
        ExerciseSpec(
            key: "seated-cable-row",
            displayName: "Seated cable row",
            orderIndex: 4,
            setsText: "3 × 10–12",
            targetSets: 3, targetRepsMin: 10, targetRepsMax: 12,
            restSeconds: 90,
            alternatives: ["Machine row", "Inverted row", "One-arm DB row", "Band row"],
            isMainLift: false,
            dayType: .pull,
            travelAlternative: "Band row"
        ),
        ExerciseSpec(
            key: "face-pull",
            displayName: "Face pull",
            orderIndex: 5,
            setsText: "3 × 15",
            targetSets: 3, targetRepsMin: 15, targetRepsMax: 15,
            restSeconds: 60,
            alternatives: ["Rear delt fly", "Band pull-apart", "Reverse pec deck", "YTW raises"],
            isMainLift: false,
            dayType: .pull,
            travelAlternative: "Band pull-apart"
        ),
        ExerciseSpec(
            key: "barbell-curl",
            displayName: "Barbell curl",
            orderIndex: 6,
            setsText: "3 × 8–10",
            targetSets: 3, targetRepsMin: 8, targetRepsMax: 10,
            restSeconds: 60,
            alternatives: ["EZ bar curl", "DB curl", "Cable curl", "Chin-up"],
            isMainLift: false,
            dayType: .pull,
            travelAlternative: "Chin-up"
        ),
        ExerciseSpec(
            key: "hammer-curl",
            displayName: "Hammer curl",
            orderIndex: 7,
            setsText: "3 × 10–12",
            targetSets: 3, targetRepsMin: 10, targetRepsMax: 12,
            restSeconds: 60,
            alternatives: ["Cross-body curl", "Rope hammer curl", "Zottman curl", "Towel curl"],
            isMainLift: false,
            dayType: .pull,
            travelAlternative: "Towel curl"
        ),
        ExerciseSpec(
            key: "farmers-carry",
            displayName: "Farmer's carry",
            orderIndex: 8,
            setsText: "4 × 40 yards heavy",
            targetSets: 4, targetRepsMin: 1, targetRepsMax: 1,
            restSeconds: 90,
            alternatives: ["Trap bar carry", "Kettlebell carry", "Sandbag carry", "Dumbbell carry"],
            isMainLift: false,
            dayType: .pull,
            travelAlternative: "Backpack carry"
        ),
        ExerciseSpec(
            key: "suitcase-carry",
            displayName: "Suitcase carry (one-sided)",
            orderIndex: 9,
            setsText: "2 × 20 yards each side",
            targetSets: 2, targetRepsMin: 1, targetRepsMax: 1,
            restSeconds: 60,
            alternatives: ["Waiter's walk", "Bottoms-up KB carry", "Rack carry", "Overhead carry"],
            isMainLift: false,
            dayType: .pull,
            travelAlternative: "Backpack one-sided carry"
        )
    ]

    // MARK: - Tuesday (Intervals + Core)
    static let tuesday: [ExerciseSpec] = [
        ExerciseSpec(
            key: "interval-block",
            displayName: "Interval block",
            orderIndex: 1,
            setsText: "Pick one option",
            targetSets: 1, targetRepsMin: 1, targetRepsMax: 1,
            restSeconds: 0,
            alternatives: [
                "Track 400s: 8 × 400m at 85–90%, 90 sec walking rest",
                "Hill sprints: 10 × 30 sec hill sprint, walk down recovery",
                "Assault bike: 10 × 1 min hard / 1 min easy",
                "Rower: 10 × 250m hard / 90 sec easy",
                "Treadmill: 8 × 2 min hard / 1 min easy",
                "Jump rope: 10 × 1 min fast / 30 sec rest",
                "Swim: 10 × 50m hard / 30 sec rest",
                "Bodyweight (travel): 8 rounds 30 sec burpees / 30 sec rest"
            ],
            isMainLift: false,
            dayType: .intervals,
            travelAlternative: "8 rounds 30 sec burpees / 30 sec rest"
        ),
        ExerciseSpec(
            key: "pallof-press",
            displayName: "Pallof press",
            orderIndex: 2,
            setsText: "3 × 10 each side",
            targetSets: 3, targetRepsMin: 10, targetRepsMax: 10,
            restSeconds: 45,
            alternatives: ["Cable woodchop", "Band anti-rotation", "Side plank with reach"],
            isMainLift: false,
            dayType: .intervals,
            travelAlternative: "Band anti-rotation"
        ),
        ExerciseSpec(
            key: "side-plank",
            displayName: "Side plank",
            orderIndex: 3,
            setsText: "3 × 30 sec each side",
            targetSets: 3, targetRepsMin: 30, targetRepsMax: 30,
            restSeconds: 30,
            alternatives: ["Side plank with hip dip", "Copenhagen plank", "Suitcase carry"],
            isMainLift: false,
            dayType: .intervals,
            travelAlternative: "Side plank with hip dip"
        ),
        ExerciseSpec(
            key: "ab-wheel-rollout",
            displayName: "Ab wheel rollout",
            orderIndex: 4,
            setsText: "3 × 8–12",
            targetSets: 3, targetRepsMin: 8, targetRepsMax: 12,
            restSeconds: 45,
            alternatives: ["Barbell rollout", "Plank to push-up", "Dead bug", "Hollow hold"],
            isMainLift: false,
            dayType: .intervals,
            travelAlternative: "Hollow hold"
        )
    ]

    // MARK: - Thursday (Zone 2)
    static let thursday: [ExerciseSpec] = [
        ExerciseSpec(
            key: "zone2-block",
            displayName: "Zone 2 continuous",
            orderIndex: 1,
            setsText: "45–60 min continuous",
            targetSets: 1, targetRepsMin: 45, targetRepsMax: 60,
            restSeconds: 0,
            alternatives: [
                "Easy jog outdoors (conversation pace)",
                "Incline treadmill walk (10–15% grade, 3.0–3.5 mph)",
                "Unloaded hike",
                "Bike (road or stationary)",
                "Swim (easy laps)",
                "Rowing (steady state)",
                "Elliptical",
                "Ruck (light, 15–20 lbs)"
            ],
            isMainLift: false,
            dayType: .zone2,
            travelAlternative: "Unloaded walk outdoors 45 min"
        )
    ]

    // MARK: - Saturday (Grit) — ruck first, then circuit (handled by GritCircuitView).
    static let saturdayRuck: [ExerciseSpec] = [
        ExerciseSpec(
            key: "long-ruck",
            displayName: "Long ruck",
            orderIndex: 1,
            setsText: "6–10 miles at 35–45 lb, 15 min/mi target",
            targetSets: 1, targetRepsMin: 6, targetRepsMax: 10,
            restSeconds: 0,
            alternatives: [
                "Beginner: 3 mi at 20 lb",
                "Advanced: 12 mi at 45–50 lb"
            ],
            isMainLift: false,
            dayType: .grit,
            travelAlternative: "Weighted backpack hike"
        )
    ]

    // MARK: - Lookups
    static func forDay(_ dayType: DayType) -> [ExerciseSpec] {
        switch dayType {
        case .legs: return monday
        case .intervals: return tuesday
        case .push: return wednesday
        case .zone2: return thursday
        case .pull: return friday
        case .grit: return saturdayRuck
        case .rest: return []
        }
    }

    static func spec(key: String) -> ExerciseSpec? {
        let all = monday + tuesday + wednesday + thursday + friday + saturdayRuck
        return all.first { $0.key == key }
    }
}

/// The five Saturday Grit Circuit movements.
enum GritCircuit {
    struct Tile: Identifiable, Hashable, Sendable {
        let key: String
        let displayName: String
        let defaultTarget: Int
        let unit: String
        let alternatives: [String]
        var id: String { key }
    }

    static func tiles(for level: TrainingLevel, weekNumber: Int) -> [Tile] {
        let scaling = Scaling.adjustments(for: level, weekNumber: weekNumber)
        return [
            Tile(key: "push-ups", displayName: "Push-ups", defaultTarget: scaling.saturdayCircuitPushUps, unit: "reps",
                 alternatives: ["Incline push-up", "Knee push-up", "Wall push-up"]),
            Tile(key: "pull-ups", displayName: "Pull-ups", defaultTarget: scaling.saturdayCircuitPullUps, unit: "reps",
                 alternatives: ["Inverted row", "Band-assisted pull-up", "Lat pulldown"]),
            Tile(key: "air-squats", displayName: "Air squats", defaultTarget: scaling.saturdayCircuitSquats, unit: "reps",
                 alternatives: ["Goblet squat", "Split squat", "Wall sit (60 sec each round of 20)"]),
            Tile(key: "sit-ups", displayName: "Sit-ups", defaultTarget: scaling.saturdayCircuitSitUps, unit: "reps",
                 alternatives: ["Crunch", "V-up", "Leg raise"]),
            Tile(key: "bear-crawl", displayName: "Bear crawl", defaultTarget: scaling.saturdayCircuitBearCrawlYards, unit: "yards",
                 alternatives: ["Crab walk", "High plank shoulder tap", "Mountain climbers"])
        ]
    }
}
