import Foundation
import HealthKit
import OSLog

private let log = Logger(subsystem: "app.81", category: "workout")

/// Wraps HKWorkoutBuilder for foreground live sessions. Emits HR via AsyncStream.
/// Note: HKWorkoutSession is watchOS-only; on iOS we use HKWorkoutBuilder with live metrics.
@MainActor
final class WorkoutSessionService {
    private var builder: HKWorkoutBuilder?
    private var hrQuery: HKAnchoredObjectQuery?
    private let store = HKHealthStore()
    private var continuation: AsyncStream<Double>.Continuation?

    let hrStream: AsyncStream<Double>

    init() {
        var cont: AsyncStream<Double>.Continuation!
        self.hrStream = AsyncStream { cont = $0 }
        self.continuation = cont
    }

    func start(dayType: DayType) throws {
        let config = HKWorkoutConfiguration()
        switch dayType {
        case .legs, .push, .pull: config.activityType = .traditionalStrengthTraining
        case .intervals: config.activityType = .highIntensityIntervalTraining
        case .zone2: config.activityType = .running
        case .grit: config.activityType = .hiking
        case .rest: config.activityType = .mindAndBody
        }
        let b = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        self.builder = b
        Task {
            do {
                try await b.beginCollection(at: .now)
            } catch {
                log.error("beginCollection failed: \(String(describing: error))")
            }
        }
        startHRQuery()
    }

    func end() async throws -> HKWorkout? {
        stopHRQuery()
        continuation?.finish()
        guard let builder else { return nil }
        try await builder.endCollection(at: .now)
        let workout = try await builder.finishWorkout()
        self.builder = nil
        return workout
    }

    private func startHRQuery() {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        let pred = HKQuery.predicateForSamples(withStart: .now, end: nil, options: .strictStartDate)
        let cont = continuation
        let q = HKAnchoredObjectQuery(type: type,
                                      predicate: pred,
                                      anchor: nil,
                                      limit: HKObjectQueryNoLimit) { _, samples, _, _, _ in
            Self.yield(samples: samples, into: cont)
        }
        q.updateHandler = { _, samples, _, _, _ in
            Self.yield(samples: samples, into: cont)
        }
        self.hrQuery = q
        store.execute(q)
    }

    private func stopHRQuery() {
        if let q = hrQuery { store.stop(q) }
        hrQuery = nil
    }

    nonisolated private static func yield(samples: [HKSample]?, into continuation: AsyncStream<Double>.Continuation?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        let unit = HKUnit.count().unitDivided(by: .minute())
        for s in samples {
            continuation?.yield(s.quantity.doubleValue(for: unit))
        }
    }
}
