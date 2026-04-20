import Foundation
import SwiftData

@Model
final class BookProgress {
    var title: String = ""
    var author: String = ""
    var isChristian: Bool = false
    var started: Bool = false
    var completed: Bool = false
    var notes: String?
    var startedAt: Date?
    var completedAt: Date?

    var currentPage: Int = 0
    var totalPages: Int = 0
    var currentChapter: Int = 0
    var totalChapters: Int = 0
    var lastReadAt: Date?

    init(title: String, author: String, isChristian: Bool) {
        self.title = title
        self.author = author
        self.isChristian = isChristian
    }
}
