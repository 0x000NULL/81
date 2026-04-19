import SwiftUI
import SwiftData

struct BibleVersesView: View {
    @State private var selectedTheme: VerseTheme?

    private var verses: [BibleVerse] {
        if let theme = selectedTheme {
            return BibleVerses.byTheme(theme)
        }
        return BibleVerses.all
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.default) {
                themePicker
                ForEach(verses) { verse in
                    VerseCard(verse: verse)
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Verses")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var themePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", active: selectedTheme == nil) {
                    selectedTheme = nil
                }
                ForEach(VerseTheme.allCases, id: \.self) { theme in
                    chip(title: theme.label, active: selectedTheme == theme) {
                        selectedTheme = theme
                    }
                }
            }
        }
    }

    private func chip(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(active ? Theme.accent : Theme.surface)
                .foregroundStyle(active ? Theme.textPrimary : Theme.textSecondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
