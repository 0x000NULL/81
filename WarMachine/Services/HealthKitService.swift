import Foundation
import HealthKit
import OSLog

private let log = Logger(subsystem: "app.81", category: "healthkit")

actor HealthKitService {
    static let shared = HealthKitService()

    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var set: Set<HKObjectType> = []
        if let t = HKObjectType.quantityType(forIdentifier: .restingHeartRate) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .heartRate) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .bodyMass) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { set.insert(t) }
        return set
    }

    private var shareTypes: Set<HKSampleType> {
        var set: Set<HKSampleType> = []
        set.insert(HKObjectType.workoutType())
        if let t = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) { set.insert(t) }
        return set
    }

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.unavailable
        }
        try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
    }

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        store.authorizationStatus(for: type)
    }

    // MARK: Reads

    func latestBodyweightLb() async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return nil }
        return try await mostRecentQuantity(type: type, unit: .pound())
    }

    func latestRestingHR() async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else { return nil }
        return try await mostRecentQuantity(type: type, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    func latestHRV() async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return nil }
        return try await mostRecentQuantity(type: type, unit: .secondUnit(with: .milli))
    }

    /// Sleep duration for the night ending this morning.
    /// Sums only asleepCore + asleepREM + asleepDeep — excludes .inBed and .awake.
    func lastNightSleepSeconds(endingOn date: Date = .now) async throws -> TimeInterval? {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let cal = Calendar.current
        let end = cal.startOfDay(for: date).addingTimeInterval(12 * 3600)  // today noon
        let start = end.addingTimeInterval(-24 * 3600)
        let pred = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<TimeInterval?, Error>) in
            let q = HKSampleQuery(sampleType: type, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                guard let samples = samples as? [HKCategorySample] else {
                    cont.resume(returning: nil)
                    return
                }
                let keep: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                ]
                let total = samples
                    .filter { keep.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                cont.resume(returning: total > 0 ? total : nil)
            }
            store.execute(q)
        }
    }

    // MARK: 7-day series (for Today recovery dashboard)

    func restingHRSeries(days: Int, endingOn date: Date = .now) async throws -> [DailyMetric] {
        guard let type = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else { return [] }
        return try await quantityDailySeries(
            type: type,
            unit: HKUnit.count().unitDivided(by: .minute()),
            days: days,
            endingOn: date
        )
    }

    func hrvSeries(days: Int, endingOn date: Date = .now) async throws -> [DailyMetric] {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return [] }
        return try await quantityDailySeries(
            type: type,
            unit: .secondUnit(with: .milli),
            days: days,
            endingOn: date
        )
    }

    /// Sleep-hours per night over the past `days` nights. Sums asleepCore + asleepREM + asleepDeep
    /// (matches the single-night convention used elsewhere). A sample is bucketed to the night that
    /// contains its endDate, using noon-to-noon windows.
    func sleepHoursSeries(days: Int, endingOn date: Date = .now) async throws -> [DailyMetric] {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        let cal = Calendar.current
        let endOverall = cal.startOfDay(for: date).addingTimeInterval(12 * 3600)
        let startOverall = cal.date(byAdding: .day, value: -days, to: endOverall) ?? endOverall
        let pred = HKQuery.predicateForSamples(withStart: startOverall, end: endOverall, options: .strictStartDate)

        let keep: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue
        ]

        let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[HKCategorySample], Error>) in
            let q = HKSampleQuery(sampleType: type, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error { cont.resume(throwing: error); return }
                cont.resume(returning: samples as? [HKCategorySample] ?? [])
            }
            store.execute(q)
        }

        var buckets: [Date: TimeInterval] = [:]
        for s in samples where keep.contains(s.value) {
            let bucketDay = cal.startOfDay(for: s.endDate.addingTimeInterval(12 * 3600))
            buckets[bucketDay, default: 0] += s.endDate.timeIntervalSince(s.startDate)
        }
        return buckets
            .map { DailyMetric(day: $0.key, value: $0.value / 3600.0) }
            .sorted { $0.day < $1.day }
    }

    private func quantityDailySeries(type: HKQuantityType,
                                     unit: HKUnit,
                                     days: Int,
                                     endingOn date: Date) async throws -> [DailyMetric] {
        let cal = Calendar.current
        let end = cal.startOfDay(for: date).addingTimeInterval(86400)
        let start = cal.date(byAdding: .day, value: -days, to: cal.startOfDay(for: date)) ?? date
        let pred = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[HKQuantitySample], Error>) in
            let q = HKSampleQuery(sampleType: type, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error { cont.resume(throwing: error); return }
                cont.resume(returning: samples as? [HKQuantitySample] ?? [])
            }
            store.execute(q)
        }

        var buckets: [Date: [Double]] = [:]
        for s in samples {
            let day = cal.startOfDay(for: s.startDate)
            buckets[day, default: []].append(s.quantity.doubleValue(for: unit))
        }
        return buckets
            .map { DailyMetric(day: $0.key, value: $0.value.reduce(0, +) / Double($0.value.count)) }
            .sorted { $0.day < $1.day }
    }

    private func mostRecentQuantity(type: HKQuantityType, unit: HKUnit) async throws -> Double? {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Double?, Error>) in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    cont.resume(returning: nil)
                    return
                }
                cont.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    // MARK: Writes

    func saveWorkout(dayType: DayType,
                     startDate: Date,
                     endDate: Date,
                     distanceMi: Double? = nil,
                     activeEnergyKcal: Double? = nil,
                     avgHR: Double? = nil) async throws {
        let activity: HKWorkoutActivityType = {
            switch dayType {
            case .legs, .push, .pull: return .traditionalStrengthTraining
            case .intervals: return .highIntensityIntervalTraining
            case .zone2: return .running
            case .grit: return .hiking
            case .rest: return .mindAndBody
            }
        }()

        let config = HKWorkoutConfiguration()
        config.activityType = activity

        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        try await builder.beginCollection(at: startDate)

        var samples: [HKSample] = []
        if let distanceMi, let type = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            let q = HKQuantity(unit: .mile(), doubleValue: distanceMi)
            samples.append(HKQuantitySample(type: type, quantity: q, start: startDate, end: endDate))
        }
        if let activeEnergyKcal, let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            let q = HKQuantity(unit: .kilocalorie(), doubleValue: activeEnergyKcal)
            samples.append(HKQuantitySample(type: type, quantity: q, start: startDate, end: endDate))
        }
        if !samples.isEmpty {
            try await builder.addSamples(samples)
        }

        try await builder.endCollection(at: endDate)
        _ = try await builder.finishWorkout()
        _ = avgHR // reserved for future metadata
    }
}

enum HealthKitError: Error {
    case unavailable
}

struct DailyMetric: Identifiable, Sendable, Hashable {
    let day: Date
    let value: Double
    var id: Date { day }
}
