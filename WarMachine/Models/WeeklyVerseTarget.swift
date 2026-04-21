import Foundation
import SwiftData

@Model
final class WeeklyVerseTarget {
    var id: UUID = UUID()
    /// Monday-of-week, normalized via Calendar.startOfDay.
    var weekStartDate: Date = Date.now
    /// Matches `BibleVerse.reference`.
    var reference: String = ""
    var pickedAt: Date = Date.now
    /// Non-nil once the user confirms they've memorized the verse.
    var memorizedAt: Date?
    /// Non-nil once the user dismisses the week's target without memorizing.
    var dismissedAt: Date?

    init(weekStartDate: Date, reference: String) {
        self.weekStartDate = Calendar.current.startOfDay(for: weekStartDate)
        self.reference = reference
        self.pickedAt = .now
    }
}
