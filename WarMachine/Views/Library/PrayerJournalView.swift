import SwiftUI
import SwiftData

struct PrayerJournalView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\PrayerJournalEntry.createdAt, order: .reverse)]) private var entries: [PrayerJournalEntry]
    @State private var searchText = ""
    @State private var showingNew = false

    private var filtered: [PrayerJournalEntry] {
        if searchText.isEmpty { return entries }
        let q = searchText.lowercased()
        return entries.filter {
            $0.text.lowercased().contains(q)
            || ($0.tag?.lowercased().contains(q) ?? false)
        }
    }

    private var grouped: [(String, [PrayerJournalEntry])] {
        let df = DateFormatter()
        df.dateFormat = "LLLL yyyy"
        let groups = Dictionary(grouping: filtered) { df.string(from: $0.createdAt) }
        return groups.sorted { lhs, rhs in
            (lhs.value.first?.createdAt ?? .distantPast) > (rhs.value.first?.createdAt ?? .distantPast)
        }.map { ($0.key, $0.value) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.default) {
                if entries.isEmpty {
                    Card {
                        Text("Write down what you brought to God, and what He brought to you.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                ForEach(grouped, id: \.0) { month, items in
                    Text(month)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.top, 8)
                    ForEach(items) { entry in
                        NavigationLink {
                            PrayerJournalEntryView(entryID: entry.id)
                        } label: {
                            entryRow(entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .searchable(text: $searchText)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Prayer Journal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNew = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New entry")
            }
        }
        .sheet(isPresented: $showingNew) {
            NewJournalEntrySheet()
                .preferredColorScheme(.dark)
        }
    }

    private func entryRow(_ entry: PrayerJournalEntry) -> some View {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return Card {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(df.string(from: entry.createdAt))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                    if let tag = entry.tag {
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.bg)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                }
                Text(entry.text)
                    .font(.subheadline)
                    .foregroundStyle(Theme.verseBody)
                    .lineLimit(3)
            }
        }
    }
}

struct NewJournalEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var text = ""
    @State private var tag = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Write something honest.", text: $text, axis: .vertical)
                    .lineLimit(6...20)
                    .textFieldStyle(.roundedBorder)
                TextField("Tag (optional)", text: $tag)
                    .textFieldStyle(.roundedBorder)
                Spacer()
                PrimaryButton("Save", isEnabled: !text.isEmpty) {
                    let entry = PrayerJournalEntry(text: text, tag: tag.isEmpty ? nil : tag)
                    context.insert(entry)
                    try? context.save()
                    dismiss()
                }
                SecondaryButton("Cancel") { dismiss() }
            }
            .padding()
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("New entry")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PrayerJournalEntryView: View {
    let entryID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var entries: [PrayerJournalEntry]
    @State private var text = ""
    @State private var tag = ""
    @State private var showingDelete = false

    private var entry: PrayerJournalEntry? { entries.first { $0.id == entryID } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let entry {
                    Text(entry.createdAt.formatted(date: .long, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    TextField("Entry", text: $text, axis: .vertical)
                        .lineLimit(6...30)
                        .textFieldStyle(.roundedBorder)
                    TextField("Tag (optional)", text: $tag)
                        .textFieldStyle(.roundedBorder)
                    PrimaryButton("Save") {
                        entry.text = text
                        entry.tag = tag.isEmpty ? nil : tag
                        try? context.save()
                        dismiss()
                    }
                    SecondaryButton("Delete", isDestructive: true) {
                        showingDelete = true
                    }
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Entry")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            text = entry?.text ?? ""
            tag = entry?.tag ?? ""
        }
        .confirmationDialog("Delete this entry?", isPresented: $showingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let entry { context.delete(entry) }
                try? context.save()
                dismiss()
            }
        }
    }
}
