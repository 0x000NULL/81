import SwiftUI

struct Banner: View {
    let systemImage: String?
    let title: String
    let message: String?
    let tint: Color

    init(systemImage: String? = nil,
         title: String,
         message: String? = nil,
         tint: Color = Theme.accent) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.tint = tint
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .padding(.top, 2)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
        }
        .padding(Theme.Spacing.default)
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(tint.opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}
