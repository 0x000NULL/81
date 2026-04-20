import Foundation
import SwiftData

@Model
final class ExerciseLog {
    var id: UUID = UUID()
    var orderIndex: Int = 0
    var exerciseKey: String = ""
    var displayName: String = ""
    var targetSets: Int = 3
    var targetRepsMin: Int = 8
    var targetRepsMax: Int = 12
    var targetWeight: Double = 0
    var restSeconds: Int = 90
    var alternativeChosen: String?
    var isSwappedForTravel: Bool = false
    var session: WorkoutSession?

    // SchemaV3 additions.
    var loggerKindRaw: String = LoggerKind.weightReps.rawValue
    var pickedVariantKey: String?
    var workDurationSec: Int?

    var loggerKind: LoggerKind {
        get { LoggerKind(rawValue: loggerKindRaw) ?? .weightReps }
        set { loggerKindRaw = newValue.rawValue }
    }

    @Relationship(deleteRule: .cascade, inverse: \SetLog.exercise)
    var sets: [SetLog]? = []

    init(orderIndex: Int, exerciseKey: String, displayName: String,
         targetSets: Int, targetRepsMin: Int, targetRepsMax: Int,
         targetWeight: Double, restSeconds: Int) {
        self.orderIndex = orderIndex
        self.exerciseKey = exerciseKey
        self.displayName = displayName
        self.targetSets = targetSets
        self.targetRepsMin = targetRepsMin
        self.targetRepsMax = targetRepsMax
        self.targetWeight = targetWeight
        self.restSeconds = restSeconds
    }
}
