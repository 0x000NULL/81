import Foundation

struct ScalingAdjustment: Sendable {
    let beginnerFirst4WeeksOnlyMWFSat: Bool
    let mainLiftSets: Int
    let thursdayZone2Minutes: Int
    let skipIntervalsUntilWeek: Int?
    let saturdayCircuitPushUps: Int
    let saturdayCircuitPullUps: Int
    let saturdayCircuitSquats: Int
    let saturdayCircuitSitUps: Int
    let saturdayCircuitBearCrawlYards: Int
    let ruckMiles: Double
    let ruckWeightLb: Double
}

enum Scaling {

    static func adjustments(for level: TrainingLevel, weekNumber: Int) -> ScalingAdjustment {
        switch level {
        case .beginner:
            // First 4 weeks: 4-day split, 3 sets main lifts, 30 min Zone 2, no intervals, half circuit.
            if weekNumber <= 4 {
                return ScalingAdjustment(
                    beginnerFirst4WeeksOnlyMWFSat: true,
                    mainLiftSets: 3,
                    thursdayZone2Minutes: 30,
                    skipIntervalsUntilWeek: 5,
                    saturdayCircuitPushUps: 25,
                    saturdayCircuitPullUps: 12,
                    saturdayCircuitSquats: 50,
                    saturdayCircuitSitUps: 25,
                    saturdayCircuitBearCrawlYards: 20,
                    ruckMiles: 3,
                    ruckWeightLb: 20
                )
            } else {
                return ScalingAdjustment(
                    beginnerFirst4WeeksOnlyMWFSat: false,
                    mainLiftSets: 3,
                    thursdayZone2Minutes: 45,
                    skipIntervalsUntilWeek: nil,
                    saturdayCircuitPushUps: 35,
                    saturdayCircuitPullUps: 18,
                    saturdayCircuitSquats: 75,
                    saturdayCircuitSitUps: 35,
                    saturdayCircuitBearCrawlYards: 30,
                    ruckMiles: 4,
                    ruckWeightLb: 25
                )
            }

        case .intermediate:
            return ScalingAdjustment(
                beginnerFirst4WeeksOnlyMWFSat: false,
                mainLiftSets: 4,
                thursdayZone2Minutes: 60,
                skipIntervalsUntilWeek: nil,
                saturdayCircuitPushUps: 50,
                saturdayCircuitPullUps: 25,
                saturdayCircuitSquats: 100,
                saturdayCircuitSitUps: 50,
                saturdayCircuitBearCrawlYards: 40,
                ruckMiles: 7,
                ruckWeightLb: 35
            )

        case .advanced:
            return ScalingAdjustment(
                beginnerFirst4WeeksOnlyMWFSat: false,
                mainLiftSets: 4,
                thursdayZone2Minutes: 75,
                skipIntervalsUntilWeek: nil,
                saturdayCircuitPushUps: 50,
                saturdayCircuitPullUps: 25,
                saturdayCircuitSquats: 100,
                saturdayCircuitSitUps: 50,
                saturdayCircuitBearCrawlYards: 40,
                ruckMiles: 12,
                ruckWeightLb: 47.5
            )
        }
    }
}
