import Foundation

enum TrainingSchedule {

    /// Returns the scheduled DayType for a given weekday (ISO: 1=Mon … 7=Sun).
    static func dayType(forISOWeekday weekday: Int) -> DayType {
        switch weekday {
        case 1: return .legs
        case 2: return .intervals
        case 3: return .push
        case 4: return .zone2
        case 5: return .pull
        case 6: return .grit
        case 7: return .rest
        default: return .rest
        }
    }

    static func dayType(on date: Date) -> DayType {
        dayType(forISOWeekday: date.weekdayISO)
    }

    static func isTrainingDay(_ dayType: DayType) -> Bool {
        dayType != .rest
    }

    static let trainingWeekdays: [Int] = [1, 2, 3, 4, 5, 6]
}
