import Foundation
import SwiftData

@Model
final class DailyLog {
    var date: Date = Date.now

    // Morning
    var morningPrayerPrayed: Bool = false
    var promise: String?
    var hardThingCategoryRaw: String?
    var hardThingText: String?
    var hardThingCategory: HardThingCategory? {
        get { hardThingCategoryRaw.flatMap(HardThingCategory.init(rawValue:)) }
        set { hardThingCategoryRaw = newValue?.rawValue }
    }

    // Evening
    var eveningPrayerPrayed: Bool = false
    var examenNotes: String?
    var promiseKept: Bool?
    var whereIBroke: String?
    var triggerNote: String?

    // HealthKit snapshot
    var restingHR: Double?
    var sleepHours: Double?
    var energy: Int?

    // Skip handling
    var skippedReasonRaw: String?
    var skippedNote: String?
    var skippedReason: SkipReason? {
        get { skippedReasonRaw.flatMap(SkipReason.init(rawValue:)) }
        set { skippedReasonRaw = newValue?.rawValue }
    }

    // Prayer journal link
    var linkedJournalEntryID: UUID?

    // Verse link
    var verseOfDayReference: String?

    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
    }
}
