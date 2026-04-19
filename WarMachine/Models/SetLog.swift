import Foundation
import SwiftData

@Model
final class SetLog {
    var id: UUID = UUID()
    var setIndex: Int = 0
    var weightLb: Double = 0
    var reps: Int = 0
    var completedAt: Date = Date.now
    var exercise: ExerciseLog?

    init(setIndex: Int, weightLb: Double, reps: Int, completedAt: Date = .now) {
        self.setIndex = setIndex
        self.weightLb = weightLb
        self.reps = reps
        self.completedAt = completedAt
    }
}
