import Foundation
import SwiftData

@Model
final class MeditationLog {
    var id: UUID = UUID()
    var completedAt: Date = Date.now
    var kindRaw: String = MeditationKind.breathPrayer.rawValue
    var kind: MeditationKind {
        get { MeditationKind(rawValue: kindRaw) ?? .breathPrayer }
        set { kindRaw = newValue.rawValue }
    }
    var durationMinutes: Int = 10
    var notes: String?

    init(kind: MeditationKind, durationMinutes: Int, notes: String? = nil, completedAt: Date = .now) {
        self.kindRaw = kind.rawValue
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.completedAt = completedAt
    }
}
