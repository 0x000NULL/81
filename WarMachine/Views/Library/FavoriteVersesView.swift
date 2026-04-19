import SwiftUI
import SwiftData

struct FavoriteVersesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\FavoriteVerse.savedAt, order: .reverse)]) private var favorites: [FavoriteVerse]

    @State private var sortMode: SortMode = .savedDate

    enum SortMode: String, CaseIterable { case savedDate = "Saved", reference = "Reference", theme = "Theme" }

    private var sorted: [FavoriteVerse] {
        switch sortMode {
        case .savedDate: return favorites.sorted { $0.savedAt > $1.savedAt }
        case .reference: return favorites.sorted { $0.reference < $1.reference }
        case .theme: return favorites.sorted { themeLabel($0) < themeLabel($1) }
        }
    }

    private func themeLabel(_ f: FavoriteVerse) -> String {
        BibleVerses.byReference(f.reference)?.theme.label ?? "Zzz"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.default) {
                Picker("Sort", selection: $sortMode) {
                    ForEach(SortMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if favorites.isEmpty {
                    Card {
                        Text("No favorites yet. Tap the heart on any verse to save it.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                } else {
                    ForEach(sorted) { fav in
                        if let v = BibleVerses.byReference(fav.reference) {
                            VerseCard(verse: v)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        context.delete(fav)
                                        try? context.save()
                                    } label: {
                                        Label("Unfavorite", systemImage: "heart.slash")
                                    }
                                }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
    }
}
