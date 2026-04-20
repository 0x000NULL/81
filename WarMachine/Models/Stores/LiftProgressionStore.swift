import Foundation
import SwiftData

/// Resolves a `LiftProgression` row by `liftKey`. On sync collision,
/// merges by taking MAX of `currentWeightLb`, MAX of
/// `consecutiveTopSessions`, and the latest `lastEvaluatedAt`.
@MainActor
enum LiftProgressionStore {
    static func findOrCreate(liftKey: String,
                             displayName: String,
                             currentWeightLb: Double,
                             isMainLift: Bool,
                             in context: ModelContext) -> LiftProgression {
        let descriptor = FetchDescriptor<LiftProgression>(
            predicate: #Predicate { $0.liftKey == liftKey }
        )
        let matches = (try? context.fetch(descriptor)) ?? []

        if let canonical = matches.first {
            for sibling in matches.dropFirst() {
                canonical.currentWeightLb = max(canonical.currentWeightLb, sibling.currentWeightLb)
                canonical.consecutiveTopSessions = max(canonical.consecutiveTopSessions, sibling.consecutiveTopSessions)
                if let theirs = sibling.lastEvaluatedAt {
                    canonical.lastEvaluatedAt = max(canonical.lastEvaluatedAt ?? .distantPast, theirs)
                }
                canonical.isMainLift = canonical.isMainLift || sibling.isMainLift
                context.delete(sibling)
            }
            return canonical
        }

        let fresh = LiftProgression(liftKey: liftKey, displayName: displayName,
                                    currentWeightLb: currentWeightLb, isMainLift: isMainLift)
        context.insert(fresh)
        return fresh
    }
}
