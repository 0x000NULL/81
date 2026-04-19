import Foundation
import SwiftData

@Model
final class GtgLog {
    @Attribute(.unique) var date: Date = Date.now
    var totalReps: Int = 0
    var setsCompleted: Int = 0
    var target: Int = 30

    init(date: Date, target: Int) {
        self.date = Calendar.current.startOfDay(for: date)
        self.target = target
    }
}
