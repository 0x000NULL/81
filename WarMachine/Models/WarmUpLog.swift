import Foundation
import SwiftData

/// Per-session warm-up completion state. Replaces the single-boolean
/// `WorkoutView.warmUpDone` @State with persisted per-item check-off.
@Model
final class WarmUpLog {
    var id: UUID = UUID()
    var session: WorkoutSession?
    var completedItemKeys: [String] = []
    var skipped: Bool = false
    var completedAt: Date?

    init() {}
}
