import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var startDate: Date = Date.now

    var levelRaw: String = TrainingLevel.intermediate.rawValue
    var level: TrainingLevel {
        get { TrainingLevel(rawValue: levelRaw) ?? .intermediate }
        set { levelRaw = newValue.rawValue }
    }

    var bodyweightLb: Double = 180
    var waistInches: Double = 34
    var identitySentence: String = "I am a son of God who does the work."

    // Notification times
    var morningReminderHour: Int = 6
    var morningReminderMinute: Int = 45
    var eveningReminderHour: Int = 21
    var eveningReminderMinute: Int = 0
    var workoutReminderHour: Int = 18

    // State flags
    var injuryFlag: Bool = false
    var injuryNote: String?
    var rebuildModeRemainingSessions: Int = 0

    // Uncomfortable Truth milestone tracking
    var lastUTMilestoneShown: Int?

    // Weekly scripture memorization target
    var currentMemorizationReference: String?

    // Optional — enables "180 − age" target for Thursday Zone 2
    var birthDate: Date?

    // SchemaV3 additions — barbell / plate config for the plate calculator.
    var preferredBarbellLb: Double = 45.0
    var availablePlatesLb: [Double] = [45, 35, 25, 10, 5, 2.5]

    // Optional beta — drive RuckLogger distance from CoreLocation while
    // the ruck is active. Off by default; toggled in Settings.
    var liveGPSRuckEnabled: Bool = false

    init() {}
}

extension UserProfile {
    /// Integer years between birthDate and `date`. Nil if birthDate isn't set.
    func ageYears(on date: Date = .now) -> Int? {
        guard let dob = birthDate else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: date).year
    }

    /// "180 − age" Zone 2 heart-rate ceiling. Nil if birthDate isn't set.
    func zone2MaxHR(on date: Date = .now) -> Int? {
        ageYears(on: date).map { 180 - $0 }
    }
}
