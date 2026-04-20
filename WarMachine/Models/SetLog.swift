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

    // SchemaV3 additions — all optional or defaulted so existing rows
    // migrate cleanly.
    var durationSec: Int?
    var distanceYards: Int?
    var distanceMiles: Double?
    var loadLb: Double?
    var rpe: Double?
    var heartRateAvg: Int?
    var cutRestShort: Bool = false
    var roundIndex: Int?
    var setTypeRaw: String = SetType.normal.rawValue
    var prKinds: [String] = []
    var isCompleted: Bool = true

    var setType: SetType {
        get { SetType(rawValue: setTypeRaw) ?? .normal }
        set { setTypeRaw = newValue.rawValue }
    }

    init(setIndex: Int, weightLb: Double, reps: Int, completedAt: Date = .now) {
        self.setIndex = setIndex
        self.weightLb = weightLb
        self.reps = reps
        self.completedAt = completedAt
    }
}
