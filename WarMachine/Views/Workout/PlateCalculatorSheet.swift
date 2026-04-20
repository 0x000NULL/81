import SwiftUI
import SwiftData

/// Modal that shows the plate breakdown for the current target weight
/// and lets the user swap the bar (45 / 35 / 55 / 25 / custom) or open
/// Settings for the plate inventory. Writes the bar preference back to
/// `UserProfile.preferredBarbellLb`.
struct PlateCalculatorSheet: View {
    @Binding var targetLb: Double
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    @State private var localTarget: Double = 0

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                targetRow
                barRow
                plateStackView
                if let nearest = result.nearestBelow, let above = result.nearestAbove, !result.exact {
                    inexactNotice(below: nearest, above: above)
                }
                Spacer()
                PrimaryButton("Apply") {
                    targetLb = localTarget
                    dismiss()
                }
            }
            .padding()
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Plates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { localTarget = targetLb }
        }
    }

    private var profile: UserProfile? { profiles.first }
    private var barLb: Double { profile?.preferredBarbellLb ?? 45 }
    private var plates: [Double] { profile?.availablePlatesLb ?? PlateCalculator.defaultPlates }

    private var result: PlateCalculator.Result {
        PlateCalculator.compute(targetLb: localTarget, barLb: barLb, plates: plates)
    }

    @ViewBuilder
    private var targetRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Target")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(Int(localTarget))")
                    .font(.system(size: 52, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
                Text("lb")
                    .font(.title3)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
            }
            NumberStepper(value: $localTarget, step: 5, range: 0...1000)
        }
    }

    @ViewBuilder
    private var barRow: some View {
        HStack(spacing: 8) {
            Text("Bar")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Menu {
                ForEach([45.0, 35.0, 55.0, 25.0], id: \.self) { w in
                    Button("\(Int(w)) lb") { setBar(w) }
                }
            } label: {
                HStack(spacing: 6) {
                    Text("\(Int(barLb)) lb")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.surface)
                .clipShape(Capsule())
            }
            Spacer()
            Text("\(Int(result.achievedLb)) lb loaded")
                .font(.caption.monospacedDigit())
                .foregroundStyle(result.exact ? Theme.accent : Theme.textSecondary)
        }
    }

    @ViewBuilder
    private var plateStackView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Per side")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            if result.perSide.isEmpty {
                Text("Bar only")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                HStack(spacing: 6) {
                    ForEach(Array(result.perSide.enumerated()), id: \.offset) { _, plate in
                        plateChip(weight: plate)
                    }
                    Spacer()
                }
            }
        }
    }

    private func plateChip(weight: Double) -> some View {
        let label = weight.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(weight))"
            : String(format: "%.1f", weight)
        return Text(label)
            .font(.subheadline.weight(.bold).monospacedDigit())
            .frame(minWidth: 40)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Theme.accent.opacity(0.25))
            .foregroundStyle(Theme.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    @ViewBuilder
    private func inexactNotice(below: Double, above: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Can't make exactly. Closest:")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 12) {
                Button("\(Int(below)) (↓)") { localTarget = below }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Button("\(Int(above)) (↑)") { localTarget = above }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    private func setBar(_ lb: Double) {
        profile?.preferredBarbellLb = lb
        try? context.save()
    }
}
