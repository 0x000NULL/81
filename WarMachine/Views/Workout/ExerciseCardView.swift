import SwiftUI
import SwiftData

struct ExerciseCardView: View {
    let exercise: ExerciseLog
    let spec: ExerciseSpec?
    let weightMultiplier: Double
    let onStartRest: (Int) -> Void
    @Environment(\.modelContext) private var context
    @State private var showingAlternatives = false
    @State private var editingSet: SetLog?

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                header

                if let note = exercise.alternativeChosen {
                    Text("Swap: \(note)")
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                }

                targetLine

                logger
            }
        }
        .sheet(isPresented: $showingAlternatives) {
            if let spec {
                AlternativesSheet(spec: spec, currentChoice: exercise.alternativeChosen) { choice in
                    exercise.alternativeChosen = choice
                    try? context.save()
                }
                .preferredColorScheme(.dark)
            }
        }
        .sheet(item: $editingSet) { set in
            SetEditSheet(set: set) { try? context.save() }
                .preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    private var logger: some View {
        switch exercise.loggerKind {
        case .weightReps, .bodyweightReps:
            SetLoggerView(
                exercise: exercise,
                spec: spec,
                multiplier: weightMultiplier,
                onCheckboxToggled: handleCheckbox,
                onRequestEdit: { editingSet = $0 }
            )
        case .durationHold:
            DurationHoldLogger(
                exercise: exercise,
                spec: spec,
                onCheckboxToggled: handleCheckbox,
                onRequestEdit: { editingSet = $0 }
            )
        case .distanceLoad:
            DistanceRepsLogger(
                exercise: exercise,
                spec: spec,
                onCheckboxToggled: handleCheckbox,
                onRequestEdit: { editingSet = $0 }
            )
        case .cardioIntervals:
            CardioIntervalLogger(
                exercise: exercise,
                spec: spec,
                onCheckboxToggled: handleCheckbox
            )
        case .jumpRopeFinisher:
            JumpRopeFinisherLogger(
                exercise: exercise,
                spec: spec,
                onCheckboxToggled: handleCheckbox
            )
        case .cardioSession:
            CardioSessionLogger(
                exercise: exercise,
                spec: spec,
                onCheckboxToggled: handleCheckbox
            )
        case .ruck:
            RuckLogger(
                exercise: exercise,
                spec: spec,
                onCheckboxToggled: handleCheckbox
            )
        }
    }

    private func handleCheckbox(_ set: SetLog, checked: Bool) {
        guard checked else { return }
        PRDetectorBridge.detectAndPersist(
            set: set,
            exerciseKey: exercise.exerciseKey,
            loggerKind: exercise.loggerKind,
            context: context
        )
        onStartRest(set.setIndex)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.displayName)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                if let spec {
                    Text(spec.setsText)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            Button { showingAlternatives = true } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Alternatives")
        }
    }

    private var targetLine: some View {
        let adjusted = exercise.targetWeight * weightMultiplier
        return HStack {
            Text(targetText(adjustedWeight: adjusted))
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            if exercise.restSeconds > 0 {
                Text("\(exercise.restSeconds)s rest")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func targetText(adjustedWeight: Double) -> String {
        switch exercise.loggerKind {
        case .weightReps:
            return "Target: \(Int(adjustedWeight)) lb × \(exercise.targetRepsMin)–\(exercise.targetRepsMax)"
        case .bodyweightReps:
            return "Target: \(exercise.targetRepsMin)–\(exercise.targetRepsMax) reps"
        case .distanceLoad:
            return "Target: \(exercise.targetSets) rounds"
        case .durationHold:
            return "Target: \(exercise.targetRepsMin)s hold"
        case .cardioIntervals, .cardioSession, .jumpRopeFinisher:
            return spec?.setsText ?? ""
        case .ruck:
            return "Target: \(exercise.targetRepsMin)–\(exercise.targetRepsMax) mi"
        }
    }
}

// MARK: - SetEditSheet

struct SetEditSheet: View {
    let set: SetLog
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var weight: Double = 0
    @State private var reps: Int = 0
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weight")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    NumberStepper(value: $weight, step: 5, range: 0...1000)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reps")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    IntegerStepper(value: $reps, range: 0...200)
                }
                Spacer()
                PrimaryButton("Save") {
                    set.weightLb = weight
                    set.reps = reps
                    onSave()
                    dismiss()
                }
                SecondaryButton("Delete", isDestructive: true) {
                    showDeleteConfirm = true
                }
            }
            .padding()
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Edit set")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Delete this set?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    context.delete(set)
                    onSave()
                    dismiss()
                }
            }
            .onAppear {
                weight = set.weightLb
                reps = set.reps
            }
        }
    }
}

