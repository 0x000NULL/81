import SwiftUI
import SwiftData

struct VerseCard: View {
    let verse: BibleVerse
    let showNIVTag: Bool
    let allowFavorite: Bool

    @Environment(\.modelContext) private var context
    @Query private var favorites: [FavoriteVerse]

    init(verse: BibleVerse, showNIVTag: Bool = true, allowFavorite: Bool = true) {
        self.verse = verse
        self.showNIVTag = showNIVTag
        self.allowFavorite = allowFavorite
    }

    private var isFavorited: Bool {
        favorites.contains { $0.reference == verse.reference }
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(verse.reference)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    if showNIVTag {
                        Text("NIV")
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.bg)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                    if allowFavorite {
                        Button {
                            toggleFavorite()
                        } label: {
                            Image(systemName: isFavorited ? "heart.fill" : "heart")
                                .foregroundStyle(isFavorited ? Theme.accent : Theme.textSecondary)
                        }
                        .accessibilityLabel(isFavorited ? "Unfavorite" : "Favorite")
                        .buttonStyle(.plain)
                    }
                }
                Text(verse.text)
                    .font(.body)
                    .foregroundStyle(Theme.verseBody)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(verse.reference). \(verse.text). NIV.")
    }

    private func toggleFavorite() {
        if let existing = favorites.first(where: { $0.reference == verse.reference }) {
            context.delete(existing)
        } else {
            context.insert(FavoriteVerse(reference: verse.reference))
        }
        try? context.save()
    }
}
