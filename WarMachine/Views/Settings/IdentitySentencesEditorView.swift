import SwiftUI
import SwiftData

/// Lets the user curate their list of identity sentences. Reorderable,
/// deletable, and appendable. Changes write straight through SwiftData
/// via the @Bindable profile.
struct IdentitySentencesEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile

    @State private var newSentence: String = ""
    /// Shown on dismiss so the 30-day cadence rebooks.
    var onReviewed: (() -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if profile.identitySentences.isEmpty {
                        Text("You haven't added any identity sentences yet. Start with the one you chose at onboarding.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        ForEach(profile.identitySentences.indices, id: \.self) { idx in
                            sentenceRow(idx: idx)
                        }
                        .onDelete { indices in
                            profile.identitySentences.remove(atOffsets: indices)
                            try? context.save()
                        }
                        .onMove { from, to in
                            profile.identitySentences.move(fromOffsets: from, toOffset: to)
                            try? context.save()
                        }
                    }
                } header: {
                    Text("Your identity sentences")
                } footer: {
                    Text("One is shown each day, rotating deterministically. You'll be prompted every 30 days to revisit this list.")
                }

                Section("Add new") {
                    TextField("I am…", text: $newSentence, axis: .vertical)
                        .lineLimit(2...4)
                    Button("Add") {
                        let trimmed = newSentence.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        profile.identitySentences.append(trimmed)
                        newSentence = ""
                        try? context.save()
                    }
                    .disabled(newSentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section {
                    Button("Mark reviewed") {
                        IdentityEngine.markReviewed(profile: profile)
                        try? context.save()
                        onReviewed?()
                        rescheduleNotification()
                        dismiss()
                    }
                    if let last = profile.lastIdentityReviewedAt {
                        Text("Last reviewed: \(last.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                } footer: {
                    Text("Tapping \"Mark reviewed\" resets the 30-day cadence.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Identity sentences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                EditButton()
            }
        }
    }

    @ViewBuilder
    private func sentenceRow(idx: Int) -> some View {
        TextField("I am…", text: Binding(
            get: { profile.identitySentences[idx] },
            set: { newVal in
                profile.identitySentences[idx] = newVal
                try? context.save()
            }
        ), axis: .vertical)
            .lineLimit(1...4)
    }

    private func rescheduleNotification() {
        let due = IdentityEngine.nextReviewDueAt(profile: profile)
        let enabled = NotificationService.Prefs.bool(NotificationService.Prefs.identityReviewEnabled)
        Task { await NotificationService.shared.scheduleIdentityReview(dueAt: due, enabled: enabled) }
    }
}
