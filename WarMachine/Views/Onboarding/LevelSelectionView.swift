import SwiftUI

struct LevelSelectionView: View {
    @Bindable var state: OnboardingState

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.section) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Experience level")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("This sets your starting weights, volume, and Saturday ruck load.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            VStack(spacing: 12) {
                ForEach(TrainingLevel.allCases, id: \.self) { level in
                    LevelRow(level: level, selected: state.level == level) {
                        state.level = level
                    }
                }
            }
            Spacer()
            HStack {
                SecondaryButton("Back") { state.back() }
                PrimaryButton("Continue") { state.advance() }
            }
        }
        .padding()
    }
}

private struct LevelRow: View {
    let level: TrainingLevel
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.label)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(description)
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding()
            .background(Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(selected ? Theme.accent : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
        .buttonStyle(.plain)
    }

    private var description: String {
        switch level {
        case .beginner: return "< 6 months consistent. 4 days first 4 weeks. 3 sets mains. Light ruck."
        case .intermediate: return "6 months – 2 years. Full program. 6–8 mi ruck at 35 lb."
        case .advanced: return "2+ years. Full program. 12 mi ruck at 45–50 lb. Extra Zone 2 Sunday."
        }
    }
}
