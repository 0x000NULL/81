import SwiftUI

struct WelcomeView: View {
    @Bindable var state: OnboardingState

    var body: some View {
        VStack(spacing: Theme.Spacing.section) {
            Spacer()
            VStack(spacing: 12) {
                Text("81")
                    .font(.system(size: 96, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Train like 81. Pray like a son.")
                    .font(.title3)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Text("The War Machine Protocol.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Six training days a week. Scripture, prayer, and Sabbath woven through every one.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            PrimaryButton("Begin") { state.advance() }
        }
        .padding()
    }
}
