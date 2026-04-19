import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    func daysSince(_ other: Date) -> Int {
        Calendar.current.dateComponents([.day], from: other.startOfDay, to: self.startOfDay).day ?? 0
    }

    var isSunday: Bool {
        Calendar.current.component(.weekday, from: self) == 1
    }

    var weekdayISO: Int {
        // 1 = Monday … 7 = Sunday
        let sunday1 = Calendar.current.component(.weekday, from: self)
        return sunday1 == 1 ? 7 : sunday1 - 1
    }
}

enum DateHelpers {
    static func weeksBetween(_ a: Date, _ b: Date) -> Int {
        let days = b.daysSince(a)
        return max(0, days / 7)
    }

    static func weekNumber(start: Date, on day: Date) -> Int {
        // Week 1 is the week containing `start`. Increments every 7 days.
        let days = day.daysSince(start)
        return max(1, days / 7 + 1)
    }
}
