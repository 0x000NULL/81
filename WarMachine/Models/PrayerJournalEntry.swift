import Foundation
import SwiftData

@Model
final class PrayerJournalEntry {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var date: Date = Date.now
    var text: String = ""
    var tag: String?
    var linkedFromDailyLog: Bool = false

    init(text: String, tag: String? = nil, linkedFromDailyLog: Bool = false) {
        self.id = UUID()
        self.createdAt = .now
        self.date = Calendar.current.startOfDay(for: .now)
        self.text = text
        self.tag = tag
        self.linkedFromDailyLog = linkedFromDailyLog
    }
}
