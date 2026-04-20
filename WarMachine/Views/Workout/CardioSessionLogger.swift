import SwiftUI
import SwiftData

/// Thursday Zone 2 continuous session. One big Start button, a live
/// elapsed clock driven by a TimelineView, a live HR readout reusing
/// LiveHRObserver, an optional modality dropdown (jog / treadmill walk
/// / bike / swim / hike / elliptical), and an optional manual miles
/// entry. Stop commits a single SetLog with durationSec, heartRateAvg,
/// and distanceMiles if provided.
struct CardioSessionLogger: View {
    let exercise: ExerciseLog
    let spec: ExerciseSpec?
    let onCheckboxToggled: (SetLog, Bool) -> Void

    @Environment(\.modelContext) private var context
    @Query private var sessions: [WorkoutSession]
    @Query private var profiles: [UserProfile]

    @State private var startedAt: Date?
    @State private var hrSamples: [Double] = []
    @State private var observer: LiveHRObserver?
    @State private var currentHR: Double?
    @State private var distanceMiles: Double = 0
    @State private var modality: String = "Easy jog"
    @State private var persistedSet: SetLog?

    private let modalities = [
        "Easy jog",
        "Incline treadmill walk",
        "Unloaded hike",
        "Bike",
        "Swim",
        "Rowing",
        "Elliptical",
        "Ruck (light)"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let hint = aggregateHint {
                HStack {
                    Text("Last: \(hint.summary)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                }
            }

            Menu {
                ForEach(modalities, id: \.self) { m in
                    Button(m) { modality = m }
                }
            } label: {
                HStack {
                    Text(modality)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(10)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            }

            if let startedAt {
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    let elapsed = max(0, Int(context.date.timeIntervalSince(startedAt)))
                    HStack(alignment: .firstTextBaseline) {
                        Text(Format.duration(seconds: elapsed))
                            .font(.system(size: 48, weight: .semibold, design: .rounded).monospacedDigit())
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(currentHR.map { "\(Int($0.rounded())) bpm" } ?? "—")
                                .font(.title3.monospacedDigit())
                                .foregroundStyle(hrColor)
                            if let maxHR = profile?.zone2MaxHR() {
                                Text("target ≤ \(maxHR)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                }
            } else {
                Text("Ready")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Distance (optional)")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    NumberStepper(
                        value: $distanceMiles,
                        step: 0.1,
                        range: 0...50,
                        formatter: { String(format: "%.1f mi", $0) }
                    )
                }
                Spacer()
            }

            if startedAt == nil, persistedSet == nil {
                PrimaryButton("Start session", systemImage: "play.fill") {
                    start()
                }
            } else if persistedSet == nil {
                PrimaryButton("Stop & save", systemImage: "stop.fill") {
                    stop()
                }
                SecondaryButton("Cancel") {
                    cancel()
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.accent)
                    Text("Logged")
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Button("Reset") { resetSaved() }
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .onAppear { prime() }
        .onDisappear { observer?.stop(); observer = nil }
    }

    private var profile: UserProfile? { profiles.first }

    private var aggregateHint: LastSessionHint? {
        LastSessionHintProvider.aggregateHint(
            in: sessions,
            excluding: exercise.session?.id ?? UUID(),
            exerciseKey: exercise.exerciseKey,
            kind: .cardioSession
        )
    }

    private var hrColor: Color {
        guard let currentHR, let maxHR = profile?.zone2MaxHR() else {
            return Theme.textPrimary
        }
        let floor = Double(maxHR) - 20
        if currentHR > Double(maxHR) { return .red }
        if currentHR < floor { return .orange }
        return .green
    }

    private func prime() {
        if let existing = (exercise.sets ?? []).first {
            persistedSet = existing
            distanceMiles = existing.distanceMiles ?? 0
        }
    }

    private func start() {
        startedAt = .now
        hrSamples = []
        observer = LiveHRObserver()
        Task {
            await observer?.start { bpm in
                Task { @MainActor in
                    currentHR = bpm
                    hrSamples.append(bpm)
                }
            }
        }
    }

    private func stop() {
        guard let startedAt else { return }
        let elapsed = max(1, Int(Date.now.timeIntervalSince(startedAt)))
        observer?.stop()
        observer = nil
        let set = SetLog(setIndex: 0, weightLb: 0, reps: 0)
        set.durationSec = elapsed
        set.distanceMiles = distanceMiles > 0 ? distanceMiles : nil
        set.heartRateAvg = hrSamples.isEmpty ? nil : Int(hrSamples.reduce(0, +) / Double(hrSamples.count))
        set.setType = .normal
        set.isCompleted = true
        set.exercise = exercise
        context.insert(set)
        if exercise.sets == nil { exercise.sets = [] }
        exercise.sets?.append(set)
        exercise.pickedVariantKey = modality
        exercise.workDurationSec = elapsed
        try? context.save()
        persistedSet = set
        self.startedAt = nil
        onCheckboxToggled(set, true)
    }

    private func cancel() {
        observer?.stop()
        observer = nil
        startedAt = nil
        hrSamples = []
    }

    private func resetSaved() {
        if let set = persistedSet {
            context.delete(set)
            try? context.save()
        }
        persistedSet = nil
        distanceMiles = 0
    }
}
