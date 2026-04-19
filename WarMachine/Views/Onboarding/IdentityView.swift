import SwiftUI

struct IdentityView: View {
    @Bindable var state: OnboardingState

    private let suggestions = [
        "I am a son of God who does the work.",
        "I am a warrior in His service.",
        "I am a temple of the Holy Spirit — I steward this body.",
        "I am crucified with Christ; He lives in me."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.section) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Identity sentence")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("One sentence. Same one for at least 30 days. This is who you are, not who you want to be.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Suggestions")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                ForEach(suggestions, id: \.self) { s in
                    Button { state.identitySentence = s } label: {
                        HStack {
                            Text(s)
                                .foregroundStyle(Theme.textPrimary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if state.identitySentence == s {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .padding()
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Or write your own")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                TextField("I am…", text: $state.identitySentence, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                    .foregroundStyle(Theme.textPrimary)
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
