import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var date: Date = Date.now
    var dayTypeRaw: String = DayType.legs.rawValue
    var dayType: DayType {
        get { DayType(rawValue: dayTypeRaw) ?? .legs }
        set { dayTypeRaw = newValue.rawValue }
    }

    var startedAt: Date?
    var completedAt: Date?
    var difficulty: Int?
    var notes: String?
    var isTravelMode: Bool = false
    var abandoned: Bool = false
    var prePrayed: Bool = false
    var postPrayed: Bool = false
    var appliedRebuildDiscount: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.session)
    var exercises: [ExerciseLog]? = []

    init(date: Date = .now, dayType: DayType) {
        self.date = date
        self.dayTypeRaw = dayType.rawValue
    }
}
