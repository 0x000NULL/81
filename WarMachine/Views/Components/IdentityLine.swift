import SwiftUI

struct IdentityLine: View {
    let sentence: String

    var body: some View {
        Text(sentence)
            .font(.subheadline.italic())
            .foregroundStyle(Theme.textSecondary)
            .accessibilityLabel("Identity: \(sentence)")
    }
}
