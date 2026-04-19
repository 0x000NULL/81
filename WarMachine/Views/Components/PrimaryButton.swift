import SwiftUI

struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let isEnabled: Bool
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(Theme.textPrimary)
            .background(isEnabled ? Theme.accent : Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .disabled(!isEnabled)
    }
}
