import SwiftUI
import SwiftData

struct SetLoggerView: View {
    let exercise: ExerciseLog
    let multiplier: Double
    @Binding var lastWeight: Double
    @Binding var lastReps: Int
    let onLogged: (Int) -> Void

    @Environment(\.modelContext) private var context
    @State private var currentWeight: Double = 0
    @State private var currentReps: Int = 0

    private var nextSetIndex: Int {
        (exercise.sets?.count ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    NumberStepper(value: $currentWeight, step: 5, range: 0...1000)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reps")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    IntegerStepper(value: $currentReps, range: 0...100)
                }
            }
            PrimaryButton("Log set \(nextSetIndex + 1)") {
                logSet()
            }
        }
        .onAppear { primeDefaults() }
        .onChange(of: exercise.id) { primeDefaults() }
    }

    private func primeDefaults() {
        if currentWeight == 0 {
            currentWeight = WeightRounding.round5(exercise.targetWeight * multiplier)
        }
        if currentReps == 0 {
            currentReps = exercise.targetRepsMax
        }
    }

    private func logSet() {
        let idx = nextSetIndex
        let set = SetLog(setIndex: idx, weightLb: currentWeight, reps: currentReps)
        set.exercise = exercise
        context.insert(set)
        if exercise.sets == nil { exercise.sets = [] }
        exercise.sets?.append(set)
        try? context.save()
        lastWeight = currentWeight
        lastReps = currentReps
        onLogged(idx)
    }
}
