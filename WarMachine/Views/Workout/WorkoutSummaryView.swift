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

                    if !progressionLines.isEmpty {
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

    private func evaluateProgression() {
        var lines: [String] = []
        for ex in session.exercises ?? [] {
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
        applyProgressionUpdates()
        decrementRebuildMode()
        try? context.save()
        writeHKWorkout()
        showingPostPrayer = true
    }

    private func applyProgressionUpdates() {
        for ex in session.exercises ?? [] {
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
        Task {
            try? await HealthKitService.shared.saveWorkout(
                dayType: session.dayType,
                startDate: start,
                endDate: end
            )
        }
    }
}
