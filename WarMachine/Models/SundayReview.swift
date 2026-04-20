import Foundation
import SwiftData

@Model
final class SundayReview {
    var weekStartDate: Date = Date.now
    var createdAt: Date = Date.now
    var pattern: String?
    var win: String?
    var nextWeekFocus: String?
    var whereIsawGod: String?
    var sabbathPrayerPrayed: Bool = false

    // Computed stats snapshot
    var workoutsCompleted: Int = 0
    var promisesKept: Int = 0
    var hardThingsDone: Int = 0
    var prayersPrayed: Int = 0
    var meditationsLogged: Int = 0
    var averageRestingHR: Double?
    var averageSleepHours: Double?

    init(weekStartDate: Date) {
        self.weekStartDate = Calendar.current.startOfDay(for: weekStartDate)
    }
}
