import SwiftUI
import SwiftData

struct BooksView: View {
    @Query private var progress: [BookProgress]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                Text("Christian")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                ForEach(Books.christian) { book in
                    bookRow(book)
                }
                Text("Secular")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top)
                ForEach(Books.secular) { book in
                    bookRow(book)
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Books")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bookRow(_ book: Book) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(book.author)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Text(book.why)
                    .font(.footnote)
                    .foregroundStyle(Theme.verseBody)
            }
        }
    }
}
