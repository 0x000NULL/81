import SwiftUI
import HealthKit

struct Zone2LiveHRCard: View {
    let maxHR: Int?

    @State private var currentHR: Double?
    @State private var observer: LiveHRObserver?

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Theme.accent)
                    Text("Zone 2")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    if let maxHR {
                        Text("target ≤ \(maxHR) bpm")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(currentHR.map { "\(Int($0.rounded()))" } ?? "—")
                        .font(.system(size: 44, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(color)
                    Text("bpm")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    zoneLabel
                }

                if maxHR == nil {
                    Text("Set your birthday in Settings to enable the Zone 2 target.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .task {
            if observer == nil {
                observer = LiveHRObserver()
                await observer?.start { bpm in
                    Task { @MainActor in currentHR = bpm }
                }
            }
        }
        .onDisappear {
            observer?.stop()
            observer = nil
        }
    }

    private var color: Color {
        guard let currentHR, let maxHR else { return Theme.textPrimary }
        let floor = Double(maxHR) - 20  // rough Zone 2 floor
        if currentHR > Double(maxHR) { return .red }
        if currentHR < floor { return .orange }
        return .green
    }

    @ViewBuilder
    private var zoneLabel: some View {
        if let label = zoneLabelText {
            Text(label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .foregroundStyle(Theme.textSecondary)
                .background(Theme.bg)
                .clipShape(Capsule())
        }
    }

    private var zoneLabelText: String? {
        guard let currentHR, let maxHR else { return nil }
        let floor = Double(maxHR) - 20
        if currentHR > Double(maxHR) { return "over" }
        if currentHR < floor { return "under" }
        return "in band"
    }
}

/// Minimal live heart-rate observer using HKAnchoredObjectQuery. Independent of
/// HKWorkoutBuilder — just streams the latest BPM while the view is active.
@MainActor
final class LiveHRObserver {
    private let store = HKHealthStore()
    private var query: HKAnchoredObjectQuery?

    func start(_ update: @escaping @Sendable (Double) -> Void) async {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        if HKHealthStore.isHealthDataAvailable() {
            try? await store.requestAuthorization(toShare: [], read: [type])
        }
        let pred = HKQuery.predicateForSamples(withStart: .now, end: nil, options: .strictStartDate)
        let unit = HKUnit.count().unitDivided(by: .minute())
        let handler: @Sendable (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = { _, samples, _, _, _ in
            guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else { return }
            let latest = samples.max { $0.endDate < $1.endDate }
            if let bpm = latest?.quantity.doubleValue(for: unit) {
                update(bpm)
            }
        }
        let q = HKAnchoredObjectQuery(
            type: type,
            predicate: pred,
            anchor: nil,
            limit: HKObjectQueryNoLimit,
            resultsHandler: handler
        )
        q.updateHandler = handler
        self.query = q
        store.execute(q)
    }

    func stop() {
        if let q = query { store.stop(q) }
        query = nil
    }
}
