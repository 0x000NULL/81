import Foundation
import SwiftData

@Model
final class BookProgress {
    @Attribute(.unique) var title: String = ""
    var author: String = ""
    var isChristian: Bool = false
    var started: Bool = false
    var completed: Bool = false
    var notes: String?
    var startedAt: Date?
    var completedAt: Date?

    init(title: String, author: String, isChristian: Bool) {
        self.title = title
        self.author = author
        self.isChristian = isChristian
    }
}
