import SwiftUI

struct ResumeWorkoutSheet: View {
    let session: WorkoutSession
    let onResume: () -> Void
    let onDiscard: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Workout in progress")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(startedLabel)
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(session.dayType.label)
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(session.exercises?.count ?? 0) exercises started")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
                PrimaryButton("Resume", systemImage: "play.fill", action: onResume)
                SecondaryButton("Discard", isDestructive: true, action: onDiscard)
            }
            .padding()
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Resume?")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var startedLabel: String {
        guard let started = session.startedAt else { return "Started today." }
        let seconds = Int(Date.now.timeIntervalSince(started))
        let mins = max(1, seconds / 60)
        if mins > 60 {
            return "Started \(mins / 60)h \(mins % 60)m ago."
        }
        return "Started \(mins) min ago."
    }
}
