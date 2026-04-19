import SwiftUI
import SwiftData

struct RuckLogView: View {
    @Environment(\.modelContext) private var context
    @Query private var sessions: [WorkoutSession]

    @State private var distance: Double = 6
    @State private var weight: Double = 35
    @State private var minutes: Int = 90
    @State private var notes: String = ""
    @State private var pendingGritSessionID: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.default) {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick log")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        row("Distance") {
                            NumberStepper(value: $distance, step: 0.5, range: 0...30,
                                          formatter: { String(format: "%.1f mi", $0) })
                        }
                        row("Weight") {
                            NumberStepper(value: $weight, step: 2.5, range: 0...100,
                                          formatter: { String(format: "%.1f lb", $0) })
                        }
                        row("Duration") {
                            IntegerStepper(value: $minutes, range: 5...480, step: 5)
                        }
                        TextField("Notes", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.roundedBorder)
                        PrimaryButton("Save", systemImage: "checkmark.circle.fill") {
                            save()
                        }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pace target")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("15 min/mi per protocol. Your pace: \(Format.pace(minPerMile: Double(minutes) / max(0.1, distance)))")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Ruck")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: Binding(
            get: { pendingGritSessionID != nil },
            set: { if !$0 { pendingGritSessionID = nil } }
        )) {
            if let id = pendingGritSessionID {
                NavigationStack {
                    GritCircuitView(sessionID: id)
                }
                .preferredColorScheme(.dark)
            }
        }
    }

    private func row<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            content()
        }
    }

    private func save() {
        let log = RuckLog(date: .now,
                          distanceMi: distance,
                          weightLb: weight,
                          durationSeconds: minutes * 60)
        log.notes = notes.isEmpty ? nil : notes
        context.insert(log)
        try? context.save()
        Task {
            try? await HealthKitService.shared.saveWorkout(
                dayType: .grit,
                startDate: Date.now.addingTimeInterval(-Double(minutes * 60)),
                endDate: .now,
                distanceMi: distance
            )
        }
        if shouldOpenGritCircuit() {
            let grit = WorkoutSession(dayType: .grit)
            grit.startedAt = .now
            context.insert(grit)
            try? context.save()
            pendingGritSessionID = grit.id
        }
    }

    /// Auto-hands off to the Grit Circuit when today is a Saturday (.grit) day and no
    /// completed grit circuit session already exists today.
    private func shouldOpenGritCircuit() -> Bool {
        guard TrainingSchedule.dayType(on: .now) == .grit else { return false }
        let cal = Calendar.current
        return !sessions.contains { s in
            guard s.dayType == .grit, let done = s.completedAt else { return false }
            return cal.isDate(done, inSameDayAs: .now)
        }
    }
}
