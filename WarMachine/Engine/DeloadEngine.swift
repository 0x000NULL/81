import Foundation

enum DeloadEngine {

    /// Deload multiplier: cut weights 40% during deload weeks.
    static let deloadMultiplier: Double = 0.60

    /// Rebuild multiplier after illness return.
    static let rebuildMultiplier: Double = 0.80

    /// Is this week a deload week? (5–6-week cadence: weeks 6 and 12.)
    static func isDeloadWeek(_ weekNumber: Int) -> Bool {
        weekNumber == 6 || weekNumber == 12
    }

    /// Applied multiplier based on deload + rebuild mode + return restart.
    static func weightMultiplier(weekNumber: Int,
                                 rebuildModeActive: Bool,
                                 returnRestartPercent: Double?) -> Double {
        if let pct = returnRestartPercent { return pct }
        if rebuildModeActive { return rebuildMultiplier }
        if isDeloadWeek(weekNumber) { return deloadMultiplier }
        return 1.0
    }
}
