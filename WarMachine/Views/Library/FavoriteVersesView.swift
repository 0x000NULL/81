import SwiftUI
import SwiftData

struct FavoriteVersesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\FavoriteVerse.savedAt, order: .reverse)]) private var favorites: [FavoriteVerse]

    @State private var sortMode: SortMode = .savedDate
    @State private var filterMode: FilterMode = .all

    enum SortMode: String, CaseIterable { case savedDate = "Saved", reference = "Reference", theme = "Theme" }
    enum FilterMode: String, CaseIterable { case all = "All", learning = "Learning", memorized = "Memorized" }

    private var filtered: [FavoriteVerse] {
        switch filterMode {
        case .all: return favorites
        case .learning: return favorites.filter { !$0.isMemorized }
        case .memorized: return favorites.filter { $0.isMemorized }
        }
    }

    private var sorted: [FavoriteVerse] {
        switch sortMode {
        case .savedDate: return filtered.sorted { $0.savedAt > $1.savedAt }
        case .reference: return filtered.sorted { $0.reference < $1.reference }
        case .theme: return filtered.sorted { themeLabel($0) < themeLabel($1) }
        }
    }

    private func themeLabel(_ f: FavoriteVerse) -> String {
        BibleVerses.byReference(f.reference)?.theme.label ?? "Zzz"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.default) {
                Picker("Filter", selection: $filterMode) {
                    ForEach(FilterMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

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
                } else if filtered.isEmpty {
                    Card {
                        Text(filterMode == .memorized
                             ? "No memorized verses yet. Swipe on a favorite to mark it memorized."
                             : "All your favorites are memorized.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                } else {
                    ForEach(sorted) { fav in
                        if let v = BibleVerses.byReference(fav.reference) {
                            VStack(alignment: .leading, spacing: 6) {
                                VerseCard(verse: v)
                                memorizationRow(for: fav)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    fav.isMemorized.toggle()
                                    if fav.isMemorized && fav.lastReviewedAt == nil {
                                        fav.lastReviewedAt = .now
                                    }
                                    try? context.save()
                                } label: {
                                    Label(fav.isMemorized ? "Unmark" : "Memorized",
                                          systemImage: fav.isMemorized ? "circle" : "checkmark.seal")
                                }
                                .tint(Theme.accent)
                            }
                            .swipeActions(edge: .trailing) {
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

    @ViewBuilder
    private func memorizationRow(for fav: FavoriteVerse) -> some View {
        if fav.isMemorized {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill").font(.caption)
                Text("Memorized")
                    .font(.caption.weight(.semibold))
                if let last = fav.lastReviewedAt {
                    Text("· reviewed \(Self.relativeLabel(for: last))")
                        .font(.caption)
                }
                Spacer()
                Button {
                    fav.lastReviewedAt = .now
                    try? context.save()
                } label: {
                    Text("Reviewed")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.bg)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 4)
        }
    }

    private static func relativeLabel(for date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: .now)
    }
}
