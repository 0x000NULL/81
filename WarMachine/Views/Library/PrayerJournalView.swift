import SwiftUI
import SwiftData

struct PrayerJournalView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\PrayerJournalEntry.createdAt, order: .reverse)]) private var entries: [PrayerJournalEntry]
    @State private var searchText = ""
    @State private var showingNew = false
    @State private var dateRange: ClosedRange<Date>?
    @State private var selectedTag: String?
    @State private var showingDateSheet = false

    private var filtered: [PrayerJournalEntry] {
        let q = searchText.lowercased()
        return entries.filter { entry in
            let matchesSearch = q.isEmpty
                || entry.text.lowercased().contains(q)
                || (entry.tag?.lowercased().contains(q) ?? false)
            let matchesRange = dateRange.map { $0.contains(entry.createdAt) } ?? true
            let matchesTag = selectedTag.map { entry.tag == $0 } ?? true
            return matchesSearch && matchesRange && matchesTag
        }
    }

    private var allTags: [String] {
        Array(Set(entries.compactMap { $0.tag })).sorted()
    }

    private var hasActiveFilter: Bool {
        dateRange != nil || selectedTag != nil
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
                if hasActiveFilter {
                    activeFilterChips
                }
                if entries.isEmpty {
                    Card {
                        Text("Write down what you brought to God, and what He brought to you.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                } else if filtered.isEmpty {
                    Card {
                        Text("No entries in this range.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                ForEach(grouped, id: \.0) { month, items in
                    Text("\(month)  ·  \(items.count)")
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
            ToolbarItem(placement: .topBarLeading) {
                filterMenu
            }
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
        .sheet(isPresented: $showingDateSheet) {
            DateRangeFilterSheet(range: $dateRange)
                .preferredColorScheme(.dark)
        }
    }

    private var filterMenu: some View {
        Menu {
            Button {
                showingDateSheet = true
            } label: {
                Label("Filter by date…", systemImage: "calendar")
            }
            Menu {
                Button("All tags") { selectedTag = nil }
                if !allTags.isEmpty { Divider() }
                ForEach(allTags, id: \.self) { tag in
                    Button {
                        selectedTag = tag
                    } label: {
                        if selectedTag == tag {
                            Label(tag, systemImage: "checkmark")
                        } else {
                            Text(tag)
                        }
                    }
                }
            } label: {
                Label("Filter by tag", systemImage: "tag")
            }
            if hasActiveFilter {
                Divider()
                Button(role: .destructive) {
                    dateRange = nil
                    selectedTag = nil
                } label: {
                    Label("Clear filters", systemImage: "xmark.circle")
                }
            }
        } label: {
            Image(systemName: hasActiveFilter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filters")
    }

    @ViewBuilder
    private var activeFilterChips: some View {
        HStack(spacing: 8) {
            if let range = dateRange {
                filterChip(label: Self.formatRange(range), systemImage: "calendar") {
                    dateRange = nil
                }
            }
            if let tag = selectedTag {
                filterChip(label: tag, systemImage: "tag") {
                    selectedTag = nil
                }
            }
            Spacer()
        }
    }

    private func filterChip(label: String, systemImage: String, onClear: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage).font(.caption2)
            Text(label).font(.caption)
            Button(action: onClear) {
                Image(systemName: "xmark.circle.fill").font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(Theme.textSecondary)
        .background(Theme.bg)
        .clipShape(Capsule())
    }

    private static func formatRange(_ range: ClosedRange<Date>) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return "\(df.string(from: range.lowerBound)) – \(df.string(from: range.upperBound))"
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

struct DateRangeFilterSheet: View {
    @Binding var range: ClosedRange<Date>?
    @Environment(\.dismiss) private var dismiss
    @State private var from: Date
    @State private var to: Date

    init(range: Binding<ClosedRange<Date>?>) {
        self._range = range
        let now = Date()
        let lower = range.wrappedValue?.lowerBound ?? Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let upper = range.wrappedValue?.upperBound ?? now
        self._from = State(initialValue: lower)
        self._to = State(initialValue: upper)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Presets")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                    HStack(spacing: 8) {
                        presetButton("Last 7 days") {
                            let now = Date()
                            from = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
                            to = now
                        }
                        presetButton("This month") {
                            let now = Date()
                            let cal = Calendar.current
                            from = cal.dateInterval(of: .month, for: now)?.start ?? now
                            to = now
                        }
                    }
                    Divider().padding(.vertical, 4)
                    DatePicker("From", selection: $from, in: ...to, displayedComponents: .date)
                    DatePicker("To", selection: $to, in: from..., displayedComponents: .date)
                    Spacer(minLength: 16)
                    PrimaryButton("Apply") {
                        let cal = Calendar.current
                        let start = cal.startOfDay(for: from)
                        let end = cal.date(byAdding: DateComponents(day: 1, second: -1),
                                           to: cal.startOfDay(for: to)) ?? to
                        range = start...end
                        dismiss()
                    }
                    SecondaryButton("All time") {
                        range = nil
                        dismiss()
                    }
                    SecondaryButton("Cancel") { dismiss() }
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Date range")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func presetButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundStyle(Theme.textSecondary)
                .background(Theme.bg)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
