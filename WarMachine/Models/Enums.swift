import Foundation

enum TrainingLevel: String, Codable, CaseIterable, Sendable, Hashable {
    case beginner, intermediate, advanced

    var label: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

enum DayType: String, Codable, CaseIterable, Sendable {
    case legs, intervals, push, zone2, pull, grit, rest

    var label: String {
        switch self {
        case .legs: return "Legs"
        case .intervals: return "Intervals + Core"
        case .push: return "Push"
        case .zone2: return "Zone 2"
        case .pull: return "Pull + Carries"
        case .grit: return "Grit Day"
        case .rest: return "Rest"
        }
    }

    var durationLabel: String {
        switch self {
        case .legs: return "60–75 min"
        case .intervals: return "45–60 min"
        case .push: return "60–75 min"
        case .zone2: return "45–60 min"
        case .pull: return "60–75 min"
        case .grit: return "90–150 min"
        case .rest: return "20–30 min"
        }
    }
}

enum HardThingCategory: String, Codable, CaseIterable, Sendable {
    case physical, mental, social, spiritual

    var label: String {
        switch self {
        case .physical: return "Physical"
        case .mental: return "Mental"
        case .social: return "Social"
        case .spiritual: return "Spiritual"
        }
    }
}

enum PrayerKind: String, Codable, CaseIterable, Sendable {
    case morning
    case preWorkout
    case postWorkout
    case evening
    case sabbath
    case afterFailure
    case beforeHardThing

    var label: String {
        switch self {
        case .morning: return "Morning Prayer"
        case .preWorkout: return "Pre-Workout Prayer"
        case .postWorkout: return "Post-Workout Prayer"
        case .evening: return "Evening Prayer"
        case .sabbath: return "Sabbath Prayer"
        case .afterFailure: return "Prayer After Failure"
        case .beforeHardThing: return "Prayer Before the Hard Thing"
        }
    }
}

enum MeditationKind: String, Codable, CaseIterable, Sendable {
    case lectioDivina
    case breathPrayer
    case examen
    case scriptureMemorization
    case silentWaiting
    case attributeOfGod

    var label: String {
        switch self {
        case .lectioDivina: return "Lectio Divina"
        case .breathPrayer: return "Breath Prayer / Jesus Prayer"
        case .examen: return "The Examen"
        case .scriptureMemorization: return "Scripture Memorization"
        case .silentWaiting: return "Silent Waiting"
        case .attributeOfGod: return "Attribute of God"
        }
    }
}

enum SkipReason: String, Codable, CaseIterable, Sendable {
    case sick, injured, travel, life, unplannedRest

    var label: String {
        switch self {
        case .sick: return "Sick"
        case .injured: return "Injured"
        case .travel: return "Traveling / no equipment"
        case .life: return "Life / emergency"
        case .unplannedRest: return "Unplanned rest"
        }
    }
}

enum VerseTheme: String, Codable, CaseIterable, Sendable {
    case strength, perseverance, discipline, warfare, rest, identity, failureAndReturn, trust, workAndPurpose

    var label: String {
        switch self {
        case .strength: return "Strength"
        case .perseverance: return "Perseverance"
        case .discipline: return "Discipline"
        case .warfare: return "Warfare & Courage"
        case .rest: return "Rest & Sabbath"
        case .identity: return "Identity"
        case .failureAndReturn: return "Failure & Return"
        case .trust: return "Trust"
        case .workAndPurpose: return "Work & Purpose"
        }
    }
}
