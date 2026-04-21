import Foundation
import SwiftData

/// Resolves the `WeeklyVerseTarget` for a given Monday. On sync collision,
/// prefers the earliest `pickedAt`, ORs `memorizedAt`/`dismissedAt` to the
/// earliest non-nil value, and keeps the canonical row's `reference` unless
/// only a sibling has one.
@MainActor
enum WeeklyVerseTargetStore {
    static func findOrCreate(weekStartDate: Date, reference: String, in context: ModelContext) -> WeeklyVerseTarget {
        let normalized = Calendar.current.startOfDay(for: weekStartDate)
        let descriptor = FetchDescriptor<WeeklyVerseTarget>(
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

        let fresh = WeeklyVerseTarget(weekStartDate: normalized, reference: reference)
        context.insert(fresh)
        return fresh
    }

    /// Finds the row for a week if one exists, without creating.
    static func find(weekStartDate: Date, in context: ModelContext) -> WeeklyVerseTarget? {
        let normalized = Calendar.current.startOfDay(for: weekStartDate)
        let descriptor = FetchDescriptor<WeeklyVerseTarget>(
            predicate: #Predicate { $0.weekStartDate == normalized }
        )
        let matches = (try? context.fetch(descriptor)) ?? []
        guard let canonical = matches.first else { return nil }
        for sibling in matches.dropFirst() {
            merge(sibling, into: canonical)
            context.delete(sibling)
        }
        return canonical
    }

    private static func merge(_ src: WeeklyVerseTarget, into dst: WeeklyVerseTarget) {
        if dst.reference.isEmpty, !src.reference.isEmpty {
            dst.reference = src.reference
        }
        dst.pickedAt = min(dst.pickedAt, src.pickedAt)
        dst.memorizedAt = earliestNonNil(dst.memorizedAt, src.memorizedAt)
        dst.dismissedAt = earliestNonNil(dst.dismissedAt, src.dismissedAt)
    }

    private static func earliestNonNil(_ a: Date?, _ b: Date?) -> Date? {
        switch (a, b) {
        case (nil, nil): return nil
        case (let x?, nil): return x
        case (nil, let y?): return y
        case (let x?, let y?): return min(x, y)
        }
    }
}
