import Foundation
import SwiftData

@Model
final class BaselineTest {
    var id: UUID = UUID()
    var date: Date = Date.now
    var weekNumber: Int = 0

    var oneMileRunSeconds: Int?
    var maxPushUpsTwoMin: Int?
    var maxPullUps: Int?
    var twoMileRuckSeconds: Int?
    var twoMileRuckWeightLb: Double = 25
    var restingHR: Double?
    var bodyweightLb: Double?
    var waistInches: Double?

    init(date: Date, weekNumber: Int) {
        self.date = date
        self.weekNumber = weekNumber
    }
}
