import SwiftUI
import SwiftData

/// Modal list of every page in the walkthrough (warm-up, each exercise,
/// finish), with completion state and tap-to-jump. The caller passes
/// the current page index and a jump handler that sets the pager's
/// selection.
struct WorkoutOverviewSheet: View {
    let warmUpCompleted: Bool
    let exercises: [ExerciseLog]
    let exerciseCompleted: [Bool]
    let currentIndex: Int
    let onJump: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    overviewRow(
                        index: 0,
                        title: "Warm-up",
                        subtitle: warmUpCompleted ? "Complete" : "Pending",
                        complete: warmUpCompleted,
                        current: currentIndex == 0
                    )
                }
                Section("Exercises") {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { idx, ex in
                        overviewRow(
                            index: idx + 1,
                            title: ex.displayName,
                            subtitle: subtitle(for: ex, done: exerciseCompleted[safe: idx] ?? false),
                            complete: exerciseCompleted[safe: idx] ?? false,
                            current: currentIndex == idx + 1
                        )
                    }
                }
                Section {
                    overviewRow(
                        index: exercises.count + 1,
                        title: "Finish workout",
                        subtitle: "Summary, prayer, HealthKit export",
                        complete: false,
                        current: currentIndex == exercises.count + 1
                    )
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Session overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func overviewRow(index: Int,
                             title: String,
                             subtitle: String,
                             complete: Bool,
                             current: Bool) -> some View {
        Button {
            onJump(index)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(complete ? Theme.accent : Theme.textSecondary, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if complete {
                        Image(systemName: "checkmark")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Theme.accent)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(current ? .semibold : .regular))
                        .foregroundStyle(Theme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if current {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func subtitle(for ex: ExerciseLog, done: Bool) -> String {
        let sets = ex.sets ?? []
        let normalDone = sets.filter { $0.isCompleted && $0.setType != .warmup }.count
        let target = ex.targetSets
        if done { return "\(normalDone)/\(target) sets complete" }
        if normalDone == 0 { return "Not started" }
        return "\(normalDone)/\(target) sets"
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        (index >= 0 && index < count) ? self[index] : nil
    }
}
