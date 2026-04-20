import SwiftUI
import SwiftData

/// Saturday long ruck. Manual-entry v1: Start → live elapsed + HR →
/// Stop. Distance and load are editable steppers. Persists one
/// aggregate SetLog with `distanceMiles`, `loadLb`, `durationSec`,
/// `heartRateAvg`, and pace derived in Format.setSummary.
///
/// For continuity with the existing Progress charts, the companion
/// `RuckLog` is also written by the workout-completion path (handled in
/// Phase 6 summary updates).
struct RuckLogger: View {
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
    @State private var distanceMiles: Double = 8
    @State private var loadLb: Double = 40
    @State private var persistedSet: SetLog?
    @State private var locationService: LocationService?
    @State private var gpsDistanceMiles: Double = 0
    @State private var gpsActive: Bool = false
    @State private var gpsAuthDenied: Bool = false

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

            elapsedAndPaceRow

            if gpsAuthDenied {
                Text("Location access is off — entering distance manually. Enable in iOS Settings → Privacy → Location Services.")
                    .font(.caption)
                    .foregroundStyle(Theme.destructive)
            }

            inputsRow

            if startedAt == nil, persistedSet == nil {
                PrimaryButton("Start ruck", systemImage: "play.fill") {
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
        .onDisappear {
            observer?.stop()
            observer = nil
            locationService?.stopTracking()
            locationService = nil
            gpsActive = false
        }
    }

    @ViewBuilder
    private var elapsedAndPaceRow: some View {
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
                            .foregroundStyle(Theme.textPrimary)
                        if distanceMiles > 0, elapsed > 0 {
                            let pace = Double(elapsed) / 60.0 / distanceMiles
                            Text(Format.pace(minPerMile: pace))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(paceColor(pace: pace))
                        }
                    }
                }
            }
        } else {
            Text("Ready")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    @ViewBuilder
    private var inputsRow: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    if gpsActive {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.accent)
                    }
                }
                if gpsActive {
                    Text(String(format: "%.2f mi", distanceMiles))
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(Theme.textPrimary)
                } else {
                    NumberStepper(
                        value: $distanceMiles,
                        step: 0.1,
                        range: 0...30,
                        formatter: { String(format: "%.1f mi", $0) }
                    )
                }
            }
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text("Load")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                NumberStepper(value: $loadLb, step: 5, range: 0...100)
            }
        }
    }

    private var useGPS: Bool {
        profiles.first?.liveGPSRuckEnabled ?? false
    }

    private var aggregateHint: LastSessionHint? {
        LastSessionHintProvider.aggregateHint(
            in: sessions,
            excluding: exercise.session?.id ?? UUID(),
            exerciseKey: exercise.exerciseKey,
            kind: .ruck
        )
    }

    private func paceColor(pace: Double) -> Color {
        if pace <= 15.0 { return .green }
        if pace <= 17.0 { return .orange }
        return .red
    }

    private func prime() {
        if let existing = (exercise.sets ?? []).first {
            persistedSet = existing
            distanceMiles = existing.distanceMiles ?? distanceMiles
            loadLb = existing.loadLb ?? loadLb
        } else if let hint = aggregateHint {
            if let mi = hint.distanceMiles { distanceMiles = mi }
            if let load = hint.loadLb { loadLb = load }
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
        if useGPS {
            let svc = LocationService()
            svc.requestWhenInUse()
            // Give iOS a moment to surface the prompt response.
            let status = svc.authorizationStatus
            let isGranted = status == .authorizedWhenInUse || status == .authorizedAlways
            let isUndetermined = status == .notDetermined
            if !isGranted && !isUndetermined {
                // Denied or restricted. Leave the manual stepper in place.
                gpsAuthDenied = true
                return
            }
            locationService = svc
            gpsActive = true
            gpsAuthDenied = false
            gpsDistanceMiles = 0
            distanceMiles = 0
            svc.startTracking()
            Task { @MainActor in
                for await mi in svc.distanceStream {
                    gpsDistanceMiles = mi
                    distanceMiles = mi
                }
            }
        }
    }

    private func stop() {
        guard let startedAt else { return }
        let elapsed = max(1, Int(Date.now.timeIntervalSince(startedAt)))
        observer?.stop()
        observer = nil
        locationService?.stopTracking()
        locationService = nil
        gpsActive = false

        let set = SetLog(setIndex: 0, weightLb: 0, reps: 0)
        set.durationSec = elapsed
        set.distanceMiles = distanceMiles
        set.loadLb = loadLb
        set.heartRateAvg = hrSamples.isEmpty ? nil : Int(hrSamples.reduce(0, +) / Double(hrSamples.count))
        set.setType = .normal
        set.isCompleted = true
        set.exercise = exercise
        context.insert(set)
        if exercise.sets == nil { exercise.sets = [] }
        exercise.sets?.append(set)
        exercise.workDurationSec = elapsed
        try? context.save()
        persistedSet = set
        self.startedAt = nil
        onCheckboxToggled(set, true)
    }

    private func cancel() {
        observer?.stop()
        observer = nil
        locationService?.stopTracking()
        locationService = nil
        gpsActive = false
        gpsAuthDenied = false
        startedAt = nil
        hrSamples = []
    }

    private func resetSaved() {
        if let set = persistedSet {
            context.delete(set)
            try? context.save()
        }
        persistedSet = nil
    }
}
