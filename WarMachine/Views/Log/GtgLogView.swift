import SwiftUI
import SwiftData
import WidgetKit

struct GtgLogView: View {
    @Environment(\.modelContext) private var context
    @Query private var logs: [GtgLog]
    @State private var reps: Int = 5
    @State private var target: Int = 30

    private var today: Date { Calendar.current.startOfDay(for: .now) }
    private var log: GtgLog {
        let resolved = GtgLogStore.findOrCreate(date: today, in: context)
        try? context.save()
        return resolved
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.default) {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("GTG Pull-ups")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        Text("Never to failure. 3–5 reps per set, 5–8 sets through the day.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                        HStack {
                            Text("\(log.totalReps)")
                                .font(.system(size: 64, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("of \(log.target)")
                                .font(.headline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        ProgressView(value: min(1, Double(log.totalReps) / Double(max(1, log.target))))
                            .tint(Theme.accent)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Log a set")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        IntegerStepper(value: $reps, range: 1...20)
                        PrimaryButton("Log \(reps) reps", systemImage: "plus.circle.fill") {
                            log.totalReps += reps
                            log.setsCompleted += 1
                            try? context.save()
                            persistSnapshot()
                        }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily target")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        IntegerStepper(value: Binding(
                            get: { log.target },
                            set: { log.target = $0; try? context.save(); persistSnapshot() }
                        ), range: 10...100, step: 5)
                    }
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("GTG")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { persistSnapshot() }
    }

    private func persistSnapshot() {
        let snap = GtgWidgetSnapshot(date: .now, count: log.totalReps, target: log.target)
        snap.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
