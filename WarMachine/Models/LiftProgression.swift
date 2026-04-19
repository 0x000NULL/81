import Foundation
import SwiftData

@Model
final class LiftProgression {
    @Attribute(.unique) var liftKey: String = ""
    var displayName: String = ""
    var currentWeightLb: Double = 0
    var consecutiveTopSessions: Int = 0
    var lastEvaluatedAt: Date?
    var isMainLift: Bool = false

    init(liftKey: String, displayName: String, currentWeightLb: Double, isMainLift: Bool) {
        self.liftKey = liftKey
        self.displayName = displayName
        self.currentWeightLb = currentWeightLb
        self.isMainLift = isMainLift
    }
}
