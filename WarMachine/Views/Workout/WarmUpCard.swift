import SwiftUI

struct WarmUpCard: View {
    let routine: WarmUpRoutine
    @State private var expanded = false
    @Binding var done: Bool

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Warm-up")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(routine.durationLabel)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                    } label: {
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .accessibilityLabel(expanded ? "Collapse warm-up" : "Show warm-up")
                }

                if expanded {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(routine.steps, id: \.self) { step in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("•")
                                    .foregroundStyle(Theme.textSecondary)
                                Text(step)
                                    .foregroundStyle(Theme.verseBody)
                                    .font(.subheadline)
                            }
                        }
                    }
                    HStack(spacing: 12) {
                        SecondaryButton("Skip") { done = true }
                        PrimaryButton(done ? "Done" : "Warm-up done",
                                      systemImage: done ? "checkmark.circle.fill" : nil) {
                            done = true
                            expanded = false
                        }
                    }
                }
            }
        }
    }
}
