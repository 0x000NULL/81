import SwiftUI

struct PrayerCard: View {
    let prayer: Prayer
    let onPrayed: (() -> Void)?
    let onSkip: (() -> Void)?

    init(prayer: Prayer, onPrayed: (() -> Void)? = nil, onSkip: (() -> Void)? = nil) {
        self.prayer = prayer
        self.onPrayed = onPrayed
        self.onSkip = onSkip
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(prayer.title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    if let anchor = prayer.anchorReference {
                        Text(anchor)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Text(prayer.body)
                    .font(.body)
                    .foregroundStyle(Theme.verseBody)
                    .fixedSize(horizontal: false, vertical: true)

                if onPrayed != nil || onSkip != nil {
                    HStack(spacing: 12) {
                        if let onPrayed {
                            PrimaryButton("Prayed", systemImage: "checkmark.circle.fill", action: onPrayed)
                        }
                        if let onSkip {
                            SecondaryButton("Skip", action: onSkip)
                        }
                    }
                }
            }
        }
    }
}
