import SwiftUI
import SwiftData

struct GritCircuitView: View {
    let sessionID: UUID

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var sessions: [WorkoutSession]
    @Query private var profiles: [UserProfile]

    @State private var progress: [String: Int] = [:]
    @State private var tappedTile: GritCircuit.Tile?
    @State private var entryAmount: Int = 10
    @State private var alternatives: [String: String] = [:]
    @State private var hrSamples: [Double] = []
    @State private var hrObserver: LiveHRObserver?

    private var session: WorkoutSession? { sessions.first { $0.id == sessionID } }
    private var profile: UserProfile? { profiles.first }

    private var tiles: [GritCircuit.Tile] {
        guard let profile else { return [] }
        let week = TodayEngine.currentWeek(startDate: profile.startDate)
        return GritCircuit.tiles(for: profile.level, weekNumber: week)
    }

    private var allComplete: Bool {
        !tiles.isEmpty && tiles.allSatisfy { (progress[$0.key] ?? 0) >= $0.defaultTarget }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.default) {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grit Circuit")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Break as needed. Finish the work.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                ForEach(tiles) { tile in
                    tileRow(tile)
                }
                PrimaryButton("Finish", systemImage: "checkmark.circle.fill", isEnabled: allComplete) {
                    finish()
                }
                .padding(.top)
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Circuit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { StrengthButton(context: .struggling) }
        }
        .sheet(item: $tappedTile) { tile in
            tileSheet(tile)
                .preferredColorScheme(.dark)
        }
        .onAppear { startHRObserver() }
        .onDisappear { hrObserver?.stop(); hrObserver = nil }
    }

    private func startHRObserver() {
        guard hrObserver == nil else { return }
        let obs = LiveHRObserver()
        hrObserver = obs
        Task {
            await obs.start { bpm in
                Task { @MainActor in hrSamples.append(bpm) }
            }
        }
    }

    private func tileRow(_ tile: GritCircuit.Tile) -> some View {
        let done = progress[tile.key] ?? 0
        let complete = done >= tile.defaultTarget
        let alt = alternatives[tile.key]
        let display = alt ?? tile.displayName
        return Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(display)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(done)/\(tile.defaultTarget) \(tile.unit)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                    ProgressView(value: min(1, Double(done) / Double(max(1, tile.defaultTarget))))
                        .tint(Theme.accent)
                }
                Spacer()
                Image(systemName: complete ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(complete ? Theme.accent : Theme.textPrimary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                entryAmount = min(10, max(1, tile.defaultTarget - done))
                tappedTile = tile
            }
        }
    }

    private func tileSheet(_ tile: GritCircuit.Tile) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How many \(tile.unit)?")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Subtracts from remaining.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
                IntegerStepper(value: $entryAmount, range: 1...500)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Alternatives")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                    ForEach(tile.alternatives, id: \.self) { alt in
                        Button {
                            alternatives[tile.key] = alt
                        } label: {
                            HStack {
                                Text(alt)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                if alternatives[tile.key] == alt {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                            .padding(8)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
                PrimaryButton("Log") {
                    progress[tile.key, default: 0] += entryAmount
                    tappedTile = nil
                }
                SecondaryButton("Cancel") { tappedTile = nil }
            }
            .padding()
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(tile.displayName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func finish() {
        guard let session else { return }
        let end = Date.now
        session.completedAt = end
        try? context.save()

        hrObserver?.stop()
        hrObserver = nil

        let start = session.startedAt ?? session.date
        let durationSec = max(0, end.timeIntervalSince(start))
        let avgHR: Double? = hrSamples.isEmpty
            ? nil
            : hrSamples.reduce(0, +) / Double(hrSamples.count)
        let kcal = estimatedKcal(bodyweightLb: profile?.bodyweightLb, durationSec: durationSec)

        Task {
            try? await HealthKitService.shared.saveWorkout(
                dayType: .grit,
                startDate: start,
                endDate: end,
                distanceMi: nil,
                activeEnergyKcal: kcal,
                avgHR: avgHR
            )
        }
        dismiss()
    }

    /// MET-based kcal heuristic. Circuit calisthenics sit around
    /// 8 METs; formula is `kcal = METs × kg × hours`.
    private func estimatedKcal(bodyweightLb: Double?, durationSec: TimeInterval) -> Double? {
        guard let lb = bodyweightLb, lb > 0, durationSec > 0 else { return nil }
        let kg = lb / 2.20462
        let hours = durationSec / 3600
        let mets = 8.0
        return mets * kg * hours
    }
}
