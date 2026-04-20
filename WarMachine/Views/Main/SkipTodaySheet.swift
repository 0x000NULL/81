import SwiftUI
import SwiftData

struct SkipTodaySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @Query private var logs: [DailyLog]

    @State private var selected: SkipReason?
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Skip today?")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("This is a log, not a judgment. Be honest.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    VStack(spacing: 10) {
                        ForEach(SkipReason.allCases, id: \.self) { reason in
                            Button { selected = reason } label: {
                                HStack {
                                    Image(systemName: selected == reason ? "largecircle.fill.circle" : "circle")
                                        .foregroundStyle(selected == reason ? Theme.accent : Theme.textSecondary)
                                    Text(reason.label)
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                }
                                .padding()
                                .background(Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note (optional)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                        TextField("What's going on?", text: $note, axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        SecondaryButton("Cancel") { dismiss() }
                        PrimaryButton("Save", isEnabled: selected != nil) { save() }
                    }
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Skip today")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func save() {
        guard let selected else { return }
        let today = Calendar.current.startOfDay(for: .now)
        let log = DailyLogStore.findOrCreate(date: today, in: context)
        log.skippedReason = selected
        log.skippedNote = note.isEmpty ? nil : note

        if selected == .injured, let profile = profiles.first {
            profile.injuryFlag = true
            if !note.isEmpty { profile.injuryNote = note }
        }

        try? context.save()
        dismiss()
    }
}
