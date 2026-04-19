import SwiftUI
import SwiftData

struct ExerciseCardView: View {
    let exercise: ExerciseLog
    let spec: ExerciseSpec?
    let weightMultiplier: Double
    let onStartRest: (Int) -> Void
    @Environment(\.modelContext) private var context
    @State private var showingAlternatives = false
    @State private var lastWeight: Double = 0
    @State private var lastReps: Int = 0
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

                SetLoggerView(
                    exercise: exercise,
                    multiplier: weightMultiplier,
                    lastWeight: $lastWeight,
                    lastReps: $lastReps,
                    onLogged: { setIndex in
                        onStartRest(setIndex)
                    }
                )

                if let sets = exercise.sets?.sorted(by: { $0.setIndex < $1.setIndex }), !sets.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(sets) { s in
                            HStack {
                                Text("Set \(s.setIndex + 1): \(Int(s.weightLb)) lb × \(s.reps)")
                                    .foregroundStyle(Theme.textPrimary)
                                    .font(.subheadline.monospacedDigit())
                                Spacer()
                                Button {
                                    editingSet = s
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
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

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.displayName)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                if let spec { Text(spec.setsText)
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
            Text("Target: \(Int(adjusted)) lb × \(exercise.targetRepsMin)–\(exercise.targetRepsMax)")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text("\(exercise.restSeconds)s rest")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

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
                    IntegerStepper(value: $reps, range: 0...100)
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
