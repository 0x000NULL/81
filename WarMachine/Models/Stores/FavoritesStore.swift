import Foundation
import SwiftData

/// Resolves a `FavoriteVerse` row by reference. On sync collision,
/// merges by OR'ing memorization, taking the earliest `savedAt`, and
/// preferring the latest `lastReviewedAt`.
@MainActor
enum FavoritesStore {
    static func findOrCreate(reference: String,
                             note: String? = nil,
                             in context: ModelContext) -> FavoriteVerse {
        let descriptor = FetchDescriptor<FavoriteVerse>(
            predicate: #Predicate { $0.reference == reference }
        )
        let matches = (try? context.fetch(descriptor)) ?? []

        if let canonical = matches.first {
            for sibling in matches.dropFirst() {
                canonical.isMemorized = canonical.isMemorized || sibling.isMemorized
                canonical.savedAt = min(canonical.savedAt, sibling.savedAt)
                if let theirs = sibling.lastReviewedAt {
                    canonical.lastReviewedAt = max(canonical.lastReviewedAt ?? .distantPast, theirs)
                }
                if canonical.note == nil || canonical.note?.isEmpty == true {
                    canonical.note = sibling.note
                }
                context.delete(sibling)
            }
            return canonical
        }

        let fresh = FavoriteVerse(reference: reference, note: note)
        context.insert(fresh)
        return fresh
    }

    /// Looks up by reference and dedupes if needed; returns nil if
    /// no row exists. Used by the `VerseCard` toggle which must not
    /// create on the unfavorite branch.
    @discardableResult
    static func find(reference: String, in context: ModelContext) -> FavoriteVerse? {
        let descriptor = FetchDescriptor<FavoriteVerse>(
            predicate: #Predicate { $0.reference == reference }
        )
        let matches = (try? context.fetch(descriptor)) ?? []
        guard let canonical = matches.first else { return nil }
        for sibling in matches.dropFirst() {
            canonical.isMemorized = canonical.isMemorized || sibling.isMemorized
            canonical.savedAt = min(canonical.savedAt, sibling.savedAt)
            if let theirs = sibling.lastReviewedAt {
                canonical.lastReviewedAt = max(canonical.lastReviewedAt ?? .distantPast, theirs)
            }
            context.delete(sibling)
        }
        return canonical
    }
}
