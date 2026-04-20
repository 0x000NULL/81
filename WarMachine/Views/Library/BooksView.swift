import SwiftUI
import SwiftData

struct BooksView: View {
    @Environment(\.modelContext) private var context
    @Query private var progressRows: [BookProgress]
    @State private var editing: Book?

    private func progress(for book: Book) -> BookProgress? {
        progressRows.first { $0.title == book.title }
    }

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
        .sheet(item: $editing) { book in
            BookProgressEditSheet(book: book, existing: progress(for: book))
                .preferredColorScheme(.dark)
        }
    }

    private func bookRow(_ book: Book) -> some View {
        let p = progress(for: book)
        return Button {
            editing = book
        } label: {
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
                    if let p {
                        progressBlock(p)
                            .padding(.top, 4)
                    } else {
                        statusChip("Not started")
                            .padding(.top, 4)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func progressBlock(_ p: BookProgress) -> some View {
        if p.completed {
            statusChip("Finished")
        } else if p.totalPages > 0 {
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: Double(min(p.currentPage, p.totalPages)),
                             total: Double(max(p.totalPages, 1)))
                    .tint(Theme.textPrimary)
                HStack {
                    statusChip(p.started ? "Reading" : "Saved")
                    Spacer()
                    Text("\(p.currentPage) / \(p.totalPages) pages")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        } else if p.totalChapters > 0 {
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: Double(min(p.currentChapter, p.totalChapters)),
                             total: Double(max(p.totalChapters, 1)))
                    .tint(Theme.textPrimary)
                HStack {
                    statusChip(p.started ? "Reading" : "Saved")
                    Spacer()
                    Text("Ch. \(p.currentChapter) / \(p.totalChapters)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        } else {
            statusChip(p.started ? "Reading" : "Saved")
        }
    }

    private func statusChip(_ label: String) -> some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(Theme.textSecondary)
            .background(Theme.bg)
            .clipShape(Capsule())
    }
}

struct BookProgressEditSheet: View {
    let book: Book
    let existing: BookProgress?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var started: Bool = false
    @State private var completed: Bool = false
    @State private var currentPage: Int = 0
    @State private var totalPages: Int = 0
    @State private var currentChapter: Int = 0
    @State private var totalChapters: Int = 0
    @State private var notes: String = ""
    @State private var showingDelete: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(book.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(book.author)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)

                    Toggle("Started", isOn: $started)
                        .onChange(of: started) { _, new in if !new { completed = false } }
                    Toggle("Finished", isOn: $completed)
                        .onChange(of: completed) { _, new in if new { started = true } }

                    Divider().padding(.vertical, 4)

                    Text("Pages").font(.caption.weight(.semibold)).foregroundStyle(Theme.textSecondary)
                    HStack {
                        Text("Current").foregroundStyle(Theme.textPrimary)
                        Spacer()
                        IntegerStepper(value: $currentPage, range: 0...9999, step: 1)
                    }
                    HStack {
                        Text("Total").foregroundStyle(Theme.textPrimary)
                        Spacer()
                        IntegerStepper(value: $totalPages, range: 0...9999, step: 10)
                    }

                    Divider().padding(.vertical, 4)

                    Text("Chapters").font(.caption.weight(.semibold)).foregroundStyle(Theme.textSecondary)
                    HStack {
                        Text("Current").foregroundStyle(Theme.textPrimary)
                        Spacer()
                        IntegerStepper(value: $currentChapter, range: 0...999, step: 1)
                    }
                    HStack {
                        Text("Total").foregroundStyle(Theme.textPrimary)
                        Spacer()
                        IntegerStepper(value: $totalChapters, range: 0...999, step: 1)
                    }

                    Divider().padding(.vertical, 4)

                    Text("Notes").font(.caption.weight(.semibold)).foregroundStyle(Theme.textSecondary)
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                        .textFieldStyle(.roundedBorder)

                    Spacer(minLength: 16)

                    PrimaryButton("Save") { save() }
                    if existing != nil {
                        SecondaryButton("Clear progress", isDestructive: true) {
                            showingDelete = true
                        }
                    }
                    SecondaryButton("Cancel") { dismiss() }
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Reading progress")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Clear progress for this book?",
                                isPresented: $showingDelete,
                                titleVisibility: .visible) {
                Button("Clear", role: .destructive) {
                    if let existing { context.delete(existing) }
                    try? context.save()
                    dismiss()
                }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard let e = existing else { return }
        started = e.started
        completed = e.completed
        currentPage = e.currentPage
        totalPages = e.totalPages
        currentChapter = e.currentChapter
        totalChapters = e.totalChapters
        notes = e.notes ?? ""
    }

    private func save() {
        let bp = BookProgressStore.findOrCreate(
            title: book.title,
            author: book.author,
            isChristian: book.isChristian,
            in: context
        )
        bp.started = started || completed
        bp.completed = completed
        bp.currentPage = currentPage
        bp.totalPages = totalPages
        bp.currentChapter = currentChapter
        bp.totalChapters = totalChapters
        bp.notes = notes.isEmpty ? nil : notes
        let now = Date()
        if bp.started && bp.startedAt == nil { bp.startedAt = now }
        if bp.completed && bp.completedAt == nil { bp.completedAt = now }
        bp.lastReadAt = now
        try? context.save()
        dismiss()
    }
}
