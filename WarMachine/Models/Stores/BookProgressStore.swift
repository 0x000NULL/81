import Foundation
import SwiftData

/// Resolves a `BookProgress` row by exact title match. On sync
/// collision, merges by taking MAX of progress integers, OR of state
/// flags, and the latest non-nil timestamps.
@MainActor
enum BookProgressStore {
    static func findOrCreate(title: String,
                             author: String,
                             isChristian: Bool,
                             in context: ModelContext) -> BookProgress {
        let descriptor = FetchDescriptor<BookProgress>(
            predicate: #Predicate { $0.title == title }
        )
        let matches = (try? context.fetch(descriptor)) ?? []

        if let canonical = matches.first {
            for sibling in matches.dropFirst() {
                merge(sibling, into: canonical)
                context.delete(sibling)
            }
            return canonical
        }

        let fresh = BookProgress(title: title, author: author, isChristian: isChristian)
        context.insert(fresh)
        return fresh
    }

    private static func merge(_ src: BookProgress, into dst: BookProgress) {
        dst.started = dst.started || src.started
        dst.completed = dst.completed || src.completed
        dst.currentPage = max(dst.currentPage, src.currentPage)
        dst.totalPages = max(dst.totalPages, src.totalPages)
        dst.currentChapter = max(dst.currentChapter, src.currentChapter)
        dst.totalChapters = max(dst.totalChapters, src.totalChapters)
        if dst.notes == nil || dst.notes?.isEmpty == true { dst.notes = src.notes }
        if dst.startedAt == nil { dst.startedAt = src.startedAt }
        if dst.completedAt == nil { dst.completedAt = src.completedAt }
        if let theirs = src.lastReadAt {
            dst.lastReadAt = max(dst.lastReadAt ?? .distantPast, theirs)
        }
    }
}
