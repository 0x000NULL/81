import SwiftUI
import SwiftData

/// Home-screen card for the week's memorization target. Lives above the
/// themed daily VerseCard when a target exists for the current week.
struct WeeklyVerseCard: View {
    @Environment(\.modelContext) private var context
    let target: WeeklyVerseTarget
    let onSwap: () -> Void

    private var verse: BibleVerse? { BibleVerses.byReference(target.reference) }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                    Text("This week's verse")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    if target.memorizedAt != nil {
                        Label("Memorized", systemImage: "checkmark.seal.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .foregroundStyle(Theme.textSecondary)

                Text(target.reference)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                if let v = verse {
                    Text(v.text)
                        .font(.body)
                        .foregroundStyle(Theme.verseBody)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if target.memorizedAt == nil {
                    HStack(spacing: 10) {
                        Button {
                            target.memorizedAt = .now
                            try? context.save()
                        } label: {
                            Text("Memorized")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Theme.accent)
                                .foregroundStyle(Theme.textPrimary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button(action: onSwap) {
                            Text("Swap")
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Theme.bg)
                                .foregroundStyle(Theme.textPrimary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            target.dismissedAt = .now
                            try? context.save()
                        } label: {
                            Text("Dismiss")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
