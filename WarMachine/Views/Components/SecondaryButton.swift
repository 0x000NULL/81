import SwiftUI

struct SecondaryButton: View {
    let title: String
    let systemImage: String?
    let isDestructive: Bool
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isDestructive = isDestructive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(isDestructive ? Theme.destructive : Theme.textPrimary)
            .background(Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(Theme.textSecondary.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
    }
}
