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

    init() {}
}
