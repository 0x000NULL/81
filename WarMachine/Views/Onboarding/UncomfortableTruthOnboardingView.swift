import SwiftUI

struct UncomfortableTruthOnboardingView: View {
    let onAcknowledge: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                Text("The Uncomfortable Truth")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)

                Text(UncomfortableTruth.passage)
                    .font(.body)
                    .foregroundStyle(Theme.verseBody)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)

                PrimaryButton("I understand. Begin.", action: onAcknowledge)
                    .padding(.top)
            }
            .padding()
        }
    }
}
