import SwiftUI
import SwiftData

struct BaselineReviewView: View {
    @Query(sort: [SortDescriptor(\BaselineTest.weekNumber)]) private var tests: [BaselineTest]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                if tests.isEmpty {
                    Card {
                        Text("Baseline tests appear at Weeks 0, 4, 8, and 12.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                } else {
                    tableCard
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Baseline")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var tableCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                header
                Divider().background(Theme.textSecondary.opacity(0.3))
                row("1-mile run") { $0.oneMileRunSeconds.map { Format.duration(seconds: $0) } ?? "—" }
                row("Max push-ups") { $0.maxPushUpsTwoMin.map { "\($0)" } ?? "—" }
                row("Max pull-ups") { $0.maxPullUps.map { "\($0)" } ?? "—" }
                row("2-mi ruck (25 lb)") { $0.twoMileRuckSeconds.map { Format.duration(seconds: $0) } ?? "—" }
                row("Resting HR") { $0.restingHR.map { "\(Int($0)) bpm" } ?? "—" }
                row("Bodyweight") { $0.bodyweightLb.map { Format.weight($0) } ?? "—" }
                row("Waist") { $0.waistInches.map { String(format: "%.1f in", $0) } ?? "—" }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Metric").frame(maxWidth: .infinity, alignment: .leading)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            ForEach(tests) { t in
                Text("W\(t.weekNumber)")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func row(_ label: String, _ format: @escaping (BaselineTest) -> String) -> some View {
        HStack {
            Text(label).frame(maxWidth: .infinity, alignment: .leading)
                .font(.footnote)
                .foregroundStyle(Theme.textPrimary)
            ForEach(tests) { t in
                Text(format(t))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Theme.verseBody)
            }
        }
    }
}
