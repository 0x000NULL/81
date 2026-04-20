import Foundation
import SwiftData

@Model
final class FavoriteVerse {
    var reference: String = ""
    var savedAt: Date = Date.now
    var note: String?

    var isMemorized: Bool = false
    var lastReviewedAt: Date?

    init(reference: String, note: String? = nil) {
        self.reference = reference
        self.savedAt = .now
        self.note = note
    }
}
