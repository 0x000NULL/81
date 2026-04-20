import SwiftUI
import SwiftData

struct WarmUpCard: View {
    let routine: WarmUpRoutine
    let session: WorkoutSession
    @Binding var done: Bool
    @Environment(\.modelContext) private var context
    @State private var expanded = false

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Warm-up")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.textPrimary)
                            if done {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        Text(progressLabel)
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
                            stepRow(step: step)
                        }
                    }
                    HStack(spacing: 12) {
                        SecondaryButton("Skip") { skipAll() }
                        PrimaryButton(done ? "Done" : "Warm-up done",
                                      systemImage: done ? "checkmark.circle.fill" : nil) {
                            markDone()
                        }
                    }
                }
            }
        }
        .onAppear { primeLog() }
    }

    private var warmUpLog: WarmUpLog {
        if let existing = session.warmUp { return existing }
        let w = WarmUpLog()
        w.session = session
        context.insert(w)
        session.warmUp = w
        try? context.save()
        return w
    }

    private func primeLog() {
        _ = warmUpLog
        if done == false, session.warmUp?.completedAt != nil {
            done = true
        }
    }

    private var progressLabel: String {
        if let skipped = session.warmUp?.skipped, skipped { return "Skipped · \(routine.durationLabel)" }
        let doneCount = session.warmUp?.completedItemKeys.count ?? 0
        return "\(doneCount)/\(routine.steps.count) · \(routine.durationLabel)"
    }

    private func isStepDone(_ step: String) -> Bool {
        session.warmUp?.completedItemKeys.contains(key(for: step)) ?? false
    }

    private func key(for step: String) -> String {
        "\(routine.dayType.rawValue)::\(step)"
    }

    @ViewBuilder
    private func stepRow(step: String) -> some View {
        Button {
            toggle(step: step)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: isStepDone(step) ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isStepDone(step) ? Theme.accent : Theme.textSecondary)
                Text(step)
                    .foregroundStyle(isStepDone(step) ? Theme.textSecondary : Theme.verseBody)
                    .strikethrough(isStepDone(step), color: Theme.textSecondary)
                    .font(.subheadline)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    private func toggle(step: String) {
        let log = warmUpLog
        let k = key(for: step)
        if let idx = log.completedItemKeys.firstIndex(of: k) {
            log.completedItemKeys.remove(at: idx)
        } else {
            log.completedItemKeys.append(k)
        }
        // Auto-mark-done when every step is checked.
        if log.completedItemKeys.count >= routine.steps.count {
            log.completedAt = .now
            done = true
        } else {
            log.completedAt = nil
            done = false
        }
        try? context.save()
    }

    private func markDone() {
        let log = warmUpLog
        log.completedAt = .now
        log.skipped = false
        done = true
        expanded = false
        try? context.save()
    }

    private func skipAll() {
        let log = warmUpLog
        log.skipped = true
        log.completedAt = .now
        done = true
        expanded = false
        try? context.save()
    }
}
