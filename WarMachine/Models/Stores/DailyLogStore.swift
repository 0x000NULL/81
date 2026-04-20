import Foundation
import SwiftData

/// Resolves a `DailyLog` for a given calendar day under CloudKit sync.
/// On collision, merges by preferring non-empty text fields, OR'd
/// booleans, and earlier non-nil timestamps for HealthKit snapshots.
@MainActor
enum DailyLogStore {
    static func findOrCreate(date: Date, in context: ModelContext) -> DailyLog {
        let normalized = Calendar.current.startOfDay(for: date)
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate { $0.date == normalized }
        )
        let matches = (try? context.fetch(descriptor)) ?? []

        if let canonical = matches.first {
            for sibling in matches.dropFirst() {
                merge(sibling, into: canonical)
                context.delete(sibling)
            }
            return canonical
        }

        let fresh = DailyLog(date: normalized)
        context.insert(fresh)
        return fresh
    }

    private static func merge(_ src: DailyLog, into dst: DailyLog) {
        dst.morningPrayerPrayed = dst.morningPrayerPrayed || src.morningPrayerPrayed
        dst.eveningPrayerPrayed = dst.eveningPrayerPrayed || src.eveningPrayerPrayed
        dst.promise = preferNonEmpty(dst.promise, src.promise)
        dst.hardThingCategoryRaw = preferNonEmpty(dst.hardThingCategoryRaw, src.hardThingCategoryRaw)
        dst.hardThingText = preferNonEmpty(dst.hardThingText, src.hardThingText)
        dst.examenNotes = preferNonEmpty(dst.examenNotes, src.examenNotes)
        if dst.promiseKept == nil { dst.promiseKept = src.promiseKept }
        dst.whereIBroke = preferNonEmpty(dst.whereIBroke, src.whereIBroke)
        dst.triggerNote = preferNonEmpty(dst.triggerNote, src.triggerNote)
        if dst.restingHR == nil { dst.restingHR = src.restingHR }
        if dst.sleepHours == nil { dst.sleepHours = src.sleepHours }
        if dst.energy == nil { dst.energy = src.energy }
        dst.skippedReasonRaw = preferNonEmpty(dst.skippedReasonRaw, src.skippedReasonRaw)
        dst.skippedNote = preferNonEmpty(dst.skippedNote, src.skippedNote)
        if dst.linkedJournalEntryID == nil { dst.linkedJournalEntryID = src.linkedJournalEntryID }
        dst.verseOfDayReference = preferNonEmpty(dst.verseOfDayReference, src.verseOfDayReference)
    }

    private static func preferNonEmpty(_ a: String?, _ b: String?) -> String? {
        if let a, !a.isEmpty { return a }
        if let b, !b.isEmpty { return b }
        return a ?? b
    }
}
