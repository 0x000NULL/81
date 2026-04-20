import SwiftUI

/// Terminal page of the walkthrough. Shows session totals at a glance
/// and exposes the big "Finish workout" CTA that presents the existing
/// summary sheet.
struct WorkoutFinishPage: View {
    let session: WorkoutSession
    let onFinishTapped: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.default) {
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ready to wrap?")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        statRow(label: "Exercises", value: "\(session.exercises?.count ?? 0)")
                        statRow(label: "Sets completed", value: "\(completedSetsCount)")
                        statRow(label: "Tonnage", value: "\(Int(liveTonnage)) lb")
                        if let mi = totalCardioMiles, mi > 0 {
                            statRow(label: "Cardio distance", value: String(format: "%.2f mi", mi))
                        }
                        if totalHoldSec > 0 {
                            statRow(label: "Hold time", value: "\(totalHoldSec)s")
                        }
                    }
                }
                PrimaryButton("Finish workout", systemImage: "checkmark.circle.fill") {
                    onFinishTapped()
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private var completedSetsCount: Int {
        (session.exercises ?? []).reduce(0) { acc, ex in
            acc + (ex.sets ?? []).filter { $0.isCompleted && $0.setType != .warmup }.count
        }
    }

    private var liveTonnage: Double {
        (session.exercises ?? []).reduce(0.0) { acc, ex in
            let kind = ex.loggerKind
            guard kind == .weightReps || kind == .bodyweightReps else { return acc }
            return (ex.sets ?? []).reduce(acc) { a2, s in
                guard s.setType.countsTowardTonnage else { return a2 }
                return a2 + s.weightLb * Double(s.reps)
            }
        }
    }

    private var totalCardioMiles: Double? {
        let mi = (session.exercises ?? []).flatMap { $0.sets ?? [] }
            .compactMap { $0.distanceMiles }
            .reduce(0, +)
        return mi > 0 ? mi : nil
    }

    private var totalHoldSec: Int {
        (session.exercises ?? [])
            .filter { $0.loggerKind == .durationHold }
            .flatMap { $0.sets ?? [] }
            .compactMap { $0.durationSec }
            .reduce(0, +)
    }

    private func statRow(label: String, value: String) -> some View {
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
}
