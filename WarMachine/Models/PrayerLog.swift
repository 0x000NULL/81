import Foundation
import SwiftData

@Model
final class PrayerLog {
    var id: UUID = UUID()
    var prayedAt: Date = Date.now
    var kindRaw: String = PrayerKind.morning.rawValue
    var kind: PrayerKind {
        get { PrayerKind(rawValue: kindRaw) ?? .morning }
        set { kindRaw = newValue.rawValue }
    }
    var linkedDate: Date?

    init(kind: PrayerKind, prayedAt: Date = .now, linkedDate: Date? = nil) {
        self.kindRaw = kind.rawValue
        self.prayedAt = prayedAt
        self.linkedDate = linkedDate
    }
}
