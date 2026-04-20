import Foundation
import SwiftData

/// Resolves today's `GtgLog` row safely under CloudKit sync, where two
/// devices logging an offline GTG set on the same day can deliver
/// duplicate rows on convergence. `findOrCreate` returns the canonical
/// row, additively merging duplicates (sum reps + sets, keep larger
/// target).
@MainActor
enum GtgLogStore {
    static func findOrCreate(date: Date, in context: ModelContext) -> GtgLog {
        let normalized = Calendar.current.startOfDay(for: date)
        let descriptor = FetchDescriptor<GtgLog>(
            predicate: #Predicate { $0.date == normalized }
        )
        let matches = (try? context.fetch(descriptor)) ?? []

        if let canonical = matches.first {
            for sibling in matches.dropFirst() {
                canonical.totalReps += sibling.totalReps
                canonical.setsCompleted += sibling.setsCompleted
                canonical.target = max(canonical.target, sibling.target)
                context.delete(sibling)
            }
            return canonical
        }

        let fresh = GtgLog(date: normalized, target: 30)
        context.insert(fresh)
        return fresh
    }
}
