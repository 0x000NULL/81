import Foundation
import SwiftData

@Model
final class RuckLog {
    var id: UUID = UUID()
    var date: Date = Date.now
    var distanceMi: Double = 0
    var weightLb: Double = 0
    var durationSeconds: Int = 0
    var averageHR: Double?
    var routeData: Data?
    var notes: String?

    init(date: Date, distanceMi: Double, weightLb: Double, durationSeconds: Int) {
        self.date = date
        self.distanceMi = distanceMi
        self.weightLb = weightLb
        self.durationSeconds = durationSeconds
    }

    var paceMinPerMile: Double {
        guard distanceMi > 0 else { return 0 }
        return Double(durationSeconds) / 60.0 / distanceMi
    }
}
