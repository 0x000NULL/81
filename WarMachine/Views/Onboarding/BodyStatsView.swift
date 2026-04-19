import SwiftUI

struct BodyStatsView: View {
    @Bindable var state: OnboardingState

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.section) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Body stats")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Sets your starting weights. You'll re-measure every 4 weeks.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Bodyweight")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                NumberStepper(value: $state.bodyweightLb, step: 1, range: 90...400)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Waist (navel)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                NumberStepper(value: $state.waistInches, step: 0.5, range: 20...70,
                              formatter: { String(format: "%.1f in", $0) })
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
