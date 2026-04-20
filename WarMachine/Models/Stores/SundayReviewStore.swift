import Foundation
import SwiftData

/// Resolves the `SundayReview` for a week. On sync collision, merges
/// non-empty text fields, OR'd booleans, and per-stat MAX (the larger
/// snapshot is the more recent computation).
@MainActor
enum SundayReviewStore {
    static func findOrCreate(weekStartDate: Date, in context: ModelContext) -> SundayReview {
        let normalized = Calendar.current.startOfDay(for: weekStartDate)
        let descriptor = FetchDescriptor<SundayReview>(
            predicate: #Predicate { $0.weekStartDate == normalized }
        )
        let matches = (try? context.fetch(descriptor)) ?? []

        if let canonical = matches.first {
            for sibling in matches.dropFirst() {
                merge(sibling, into: canonical)
                context.delete(sibling)
            }
            return canonical
        }

        let fresh = SundayReview(weekStartDate: normalized)
        context.insert(fresh)
        return fresh
    }

    private static func merge(_ src: SundayReview, into dst: SundayReview) {
        dst.pattern = preferNonEmpty(dst.pattern, src.pattern)
        dst.win = preferNonEmpty(dst.win, src.win)
        dst.nextWeekFocus = preferNonEmpty(dst.nextWeekFocus, src.nextWeekFocus)
        dst.whereIsawGod = preferNonEmpty(dst.whereIsawGod, src.whereIsawGod)
        dst.sabbathPrayerPrayed = dst.sabbathPrayerPrayed || src.sabbathPrayerPrayed
        dst.workoutsCompleted = max(dst.workoutsCompleted, src.workoutsCompleted)
        dst.promisesKept = max(dst.promisesKept, src.promisesKept)
        dst.hardThingsDone = max(dst.hardThingsDone, src.hardThingsDone)
        dst.prayersPrayed = max(dst.prayersPrayed, src.prayersPrayed)
        dst.meditationsLogged = max(dst.meditationsLogged, src.meditationsLogged)
        dst.averageRestingHR = preferLatest(dst.averageRestingHR, src.averageRestingHR)
        dst.averageSleepHours = preferLatest(dst.averageSleepHours, src.averageSleepHours)
    }

    private static func preferNonEmpty(_ a: String?, _ b: String?) -> String? {
        if let a, !a.isEmpty { return a }
        if let b, !b.isEmpty { return b }
        return a ?? b
    }

    private static func preferLatest(_ a: Double?, _ b: Double?) -> Double? {
        a ?? b
    }
}
