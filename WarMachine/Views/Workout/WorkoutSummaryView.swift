import SwiftUI
import SwiftData

struct WorkoutSummaryView: View {
    let session: WorkoutSession
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Query private var lifts: [LiftProgression]

    @State private var difficulty: Double = 6
    @State private var notes: String = ""
    @State private var showingPostPrayer = false
    @State private var progressionLines: [String] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                    sessionStatsCard
                    targetsBreakdownCard
                    prCalloutCard
                    difficultyCard
                    notesCard
                    if !progressionLines.isEmpty { progressionCard }
                    PrimaryButton("Finish and pray", systemImage: "checkmark.circle.fill") {
                        finish()
                    }
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Done")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { evaluateProgression() }
            .sheet(isPresented: $showingPostPrayer) {
                PostWorkoutPrayerSheet(onPrayed: {
                    session.postPrayed = true
                    try? context.save()
                    onDone()
                })
                .onDisappear { onDone() }
            }
        }
    }

    // MARK: - Stat cards

    private var sessionStatsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Session")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                statRow("Duration", Format.duration(seconds: elapsedSec))
                statRow("Sets completed", "\(completedSetsCount)")
                if totalTonnage > 0 {
                    statRow("Tonnage", "\(Int(totalTonnage)) lb")
                }
                if let mi = totalCardioMiles, mi > 0 {
                    statRow("Cardio distance", String(format: "%.2f mi", mi))
                }
                if totalHoldSec > 0 {
                    statRow("Hold time", "\(totalHoldSec)s")
                }
                if let hr = avgHeartRate {
                    statRow("Avg HR", "\(hr) bpm")
                }
            }
        }
    }

    @ViewBuilder
    private var targetsBreakdownCard: some View {
        if !(session.exercises ?? []).isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's work")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    ForEach((session.exercises ?? []).sorted(by: { $0.orderIndex < $1.orderIndex })) { ex in
                        targetHitRow(ex: ex)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var prCalloutCard: some View {
        let pairs = prCallouts
        if !pairs.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("New PRs")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(pairs.count)")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accent)
                            .foregroundStyle(Theme.bg)
                            .clipShape(Capsule())
                    }
                    ForEach(pairs, id: \.line) { pair in
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("•")
                                .foregroundStyle(Theme.textSecondary)
                            Text(pair.line)
                                .font(.footnote)
                                .foregroundStyle(Theme.verseBody)
                        }
                    }
                }
            }
        }
    }

    private var difficultyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("How hard was it? (1–10)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Slider(value: $difficulty, in: 1...10, step: 1)
                    .tint(Theme.accent)
                Text("\(Int(difficulty))")
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
            }
        }
    }

    private var notesCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                TextField("Form, mood, anything", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var progressionCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Progression")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                ForEach(progressionLines, id: \.self) { line in
                    Text(line)
                        .font(.footnote)
                        .foregroundStyle(Theme.verseBody)
                }
            }
        }
    }

    // MARK: - Row builders

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
        }
    }

    @ViewBuilder
    private func targetHitRow(ex: ExerciseLog) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: allTargetsHit(ex: ex) ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(allTargetsHit(ex: ex) ? Theme.accent : Theme.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(ex.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(setsSummary(ex: ex))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: - Computed stats

    private var elapsedSec: Int {
        let start = session.startedAt ?? session.date
        let end = session.completedAt ?? .now
        let gross = Int(end.timeIntervalSince(start))
        let pairs = session.pauseIntervals.chunked(into: 2)
        var paused = 0
        for p in pairs where p.count == 2 {
            paused += Int(p[1].timeIntervalSince(p[0]))
        }
        return max(0, gross - paused)
    }

    private var completedSetsCount: Int {
        (session.exercises ?? []).reduce(0) { acc, ex in
            acc + (ex.sets ?? []).filter { $0.isCompleted && $0.setType != .warmup }.count
        }
    }

    private var totalTonnage: Double {
        (session.exercises ?? []).reduce(0.0) { acc, ex in
            guard ex.loggerKind == .weightReps || ex.loggerKind == .bodyweightReps else { return acc }
            return (ex.sets ?? []).reduce(acc) { a2, s in
                guard s.setType.countsTowardTonnage else { return a2 }
                return a2 + s.weightLb * Double(s.reps)
            }
        }
    }

    private var totalCardioMiles: Double? {
        let mi = (session.exercises ?? []).flatMap { $0.sets ?? [] }
            .compactMap { $0.distanceMiles }
            .reduce(0.0, +)
        return mi > 0 ? mi : nil
    }

    private var totalHoldSec: Int {
        (session.exercises ?? [])
            .filter { $0.loggerKind == .durationHold }
            .flatMap { $0.sets ?? [] }
            .compactMap { $0.durationSec }
            .reduce(0, +)
    }

    private var avgHeartRate: Int? {
        let hrs = (session.exercises ?? []).flatMap { $0.sets ?? [] }
            .compactMap { $0.heartRateAvg }
        guard !hrs.isEmpty else { return nil }
        return hrs.reduce(0, +) / hrs.count
    }

    private func allTargetsHit(ex: ExerciseLog) -> Bool {
        let done = (ex.sets ?? []).filter { $0.isCompleted && $0.setType != .warmup }
        switch ex.loggerKind {
        case .weightReps, .bodyweightReps:
            return done.count >= ex.targetSets && done.allSatisfy { $0.reps >= ex.targetRepsMin }
        case .distanceLoad:
            return done.count >= ex.targetSets
        case .durationHold:
            return done.count >= ex.targetSets
        case .cardioIntervals, .jumpRopeFinisher:
            return done.count >= max(1, ex.targetSets)
        case .cardioSession, .ruck:
            return !done.isEmpty
        }
    }

    private func setsSummary(ex: ExerciseLog) -> String {
        let done = (ex.sets ?? []).filter { $0.isCompleted && $0.setType != .warmup }
        switch ex.loggerKind {
        case .weightReps, .bodyweightReps:
            let parts = done.map { "\(Int($0.weightLb))×\($0.reps)" }
            if parts.isEmpty { return "no sets logged" }
            return parts.joined(separator: ", ")
        case .distanceLoad:
            return done.map { "\($0.distanceYards ?? 0)y @ \(Int($0.loadLb ?? 0))" }.joined(separator: ", ")
        case .durationHold:
            return done.map { "\($0.durationSec ?? 0)s" }.joined(separator: ", ")
        case .cardioIntervals, .jumpRopeFinisher:
            let total = done.compactMap { $0.durationSec }.reduce(0, +)
            return "\(done.count) rounds · \(Format.duration(seconds: total))"
        case .cardioSession:
            if let set = done.first, let secs = set.durationSec {
                return Format.duration(seconds: secs)
            }
            return "no session logged"
        case .ruck:
            if let set = done.first,
               let mi = set.distanceMiles,
               let secs = set.durationSec,
               let load = set.loadLb {
                let pace = Double(secs) / 60.0 / max(mi, 0.1)
                return String(format: "%.1f mi · %@ · %d lb",
                              mi, Format.pace(minPerMile: pace), Int(load))
            }
            return "no ruck logged"
        }
    }

    private var prCallouts: [(line: String, exerciseKey: String)] {
        var out: [(String, String)] = []
        for ex in (session.exercises ?? []) {
            for s in (ex.sets ?? []) where !s.prKinds.isEmpty {
                let kinds = s.prKinds.compactMap { PRKind(rawValue: $0)?.label }
                let label = kinds.joined(separator: "/")
                out.append(("\(ex.displayName) — \(label)", ex.exerciseKey))
            }
        }
        return out.map { (line: $0.0, exerciseKey: $0.1) }
    }

    // MARK: - Actions

    private func evaluateProgression() {
        var lines: [String] = []
        for ex in session.exercises ?? [] {
            guard ex.loggerKind == .weightReps || ex.loggerKind == .bodyweightReps else { continue }
            let isMain = StartingWeights.allLiftKeys.first { $0.key == ex.exerciseKey }?.isMain ?? false
            let isLower = ["back-squat", "deadlift", "romanian-deadlift", "leg-press", "walking-lunge-db"].contains(ex.exerciseKey)
            let priorTop = lifts.first { $0.liftKey == ex.exerciseKey }?.consecutiveTopSessions ?? 0
            let current = lifts.first { $0.liftKey == ex.exerciseKey }?.currentWeightLb ?? ex.targetWeight
            let eval = ProgressionEngine.evaluate(
                liftKey: ex.exerciseKey,
                isMainLift: isMain,
                isLowerBody: isLower,
                currentWeight: current,
                thisSessionSets: ex.sets ?? [],
                targetTopReps: ex.targetRepsMax,
                priorConsecutiveTopSessions: priorTop
            )
            if eval.shouldProgress {
                lines.append("\(ex.displayName): +\(Int(eval.suggestedNewWeight - current)) → \(Int(eval.suggestedNewWeight)) lb.")
            }
        }
        progressionLines = lines
    }

    private func finish() {
        session.completedAt = .now
        session.difficulty = Int(difficulty)
        session.notes = notes.isEmpty ? nil : notes
        session.totalTonnageLb = totalTonnage
        applyProgressionUpdates()
        decrementRebuildMode()
        try? context.save()
        writeHKWorkout()
        showingPostPrayer = true
    }

    private func applyProgressionUpdates() {
        for ex in session.exercises ?? [] {
            guard ex.loggerKind == .weightReps || ex.loggerKind == .bodyweightReps else { continue }
            let isMain = StartingWeights.allLiftKeys.first { $0.key == ex.exerciseKey }?.isMain ?? false
            let isLower = ["back-squat", "deadlift", "romanian-deadlift", "leg-press", "walking-lunge-db"].contains(ex.exerciseKey)
            let lift = lifts.first { $0.liftKey == ex.exerciseKey }
            let current = lift?.currentWeightLb ?? ex.targetWeight
            let priorTop = lift?.consecutiveTopSessions ?? 0
            let eval = ProgressionEngine.evaluate(
                liftKey: ex.exerciseKey,
                isMainLift: isMain,
                isLowerBody: isLower,
                currentWeight: current,
                thisSessionSets: ex.sets ?? [],
                targetTopReps: ex.targetRepsMax,
                priorConsecutiveTopSessions: priorTop
            )
            if let lift {
                lift.lastEvaluatedAt = .now
                if eval.shouldProgress {
                    lift.currentWeightLb = eval.suggestedNewWeight
                    lift.consecutiveTopSessions = 0
                } else if ProgressionEngine.hitTopOfRange(sets: ex.sets ?? [], targetTopReps: ex.targetRepsMax) {
                    lift.consecutiveTopSessions += 1
                } else {
                    lift.consecutiveTopSessions = 0
                }
            }
        }
    }

    private func decrementRebuildMode() {
        guard let profile = profiles.first else { return }
        if profile.rebuildModeRemainingSessions > 0 {
            profile.rebuildModeRemainingSessions -= 1
            session.appliedRebuildDiscount = true
        }
    }

    private func writeHKWorkout() {
        let start = session.startedAt ?? session.date
        let end = session.completedAt ?? .now
        let distance = totalCardioMiles
        let hr = avgHeartRate.map(Double.init)
        let dayType = session.dayType
        Task {
            try? await HealthKitService.shared.saveWorkout(
                dayType: dayType,
                startDate: start,
                endDate: end,
                distanceMi: distance,
                activeEnergyKcal: nil,
                avgHR: hr
            )
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
