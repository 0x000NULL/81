import SwiftUI
import SwiftData

struct DailyLogView: View {
    @Environment(\.modelContext) private var context
    @Query private var logs: [DailyLog]

    @State private var showingMorningPrayer = false
    @State private var showingEveningPrayer = false
    @State private var showingJournalPrompt = false

    private var today: Date { Calendar.current.startOfDay(for: .now) }
    private var log: DailyLog {
        let resolved = DailyLogStore.findOrCreate(date: today, in: context)
        try? context.save()
        return resolved
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                Text("Morning")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)

                morningPrayerCard
                verseCard
                promiseCard
                hardThingCard

                Text("Evening")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top)

                threeQuestionsCard
                examenCard
                eveningPrayerCard
                healthCard
                journalPromptCard
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Log")
        .sheet(isPresented: $showingMorningPrayer) {
            prayerSheet(Prayers.morning, onPrayed: {
                log.morningPrayerPrayed = true
                context.insert(PrayerLog(kind: .morning, linkedDate: today))
                try? context.save()
            })
        }
        .sheet(isPresented: $showingEveningPrayer) {
            prayerSheet(Prayers.evening, onPrayed: {
                log.eveningPrayerPrayed = true
                context.insert(PrayerLog(kind: .evening, linkedDate: today))
                try? context.save()
                if log.linkedJournalEntryID == nil {
                    showingJournalPrompt = true
                }
            })
        }
        .sheet(isPresented: $showingJournalPrompt) {
            JournalPromptSheet(onSaved: { id in
                log.linkedJournalEntryID = id
                try? context.save()
            })
            .preferredColorScheme(.dark)
        }
    }

    private var morningPrayerCard: some View {
        Card {
            HStack {
                Image(systemName: log.morningPrayerPrayed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(log.morningPrayerPrayed ? Theme.accent : Theme.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Morning prayer")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Lamentations 3:22–23 · NIV")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button("Open") { showingMorningPrayer = true }
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    private var verseCard: some View {
        VerseCard(verse: VerseEngine.verseOfDay())
            .onAppear {
                log.verseOfDayReference = VerseEngine.verseOfDay().reference
                try? context.save()
            }
    }

    private var promiseCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's promise")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                TextField("I will do X at Y time", text: Binding(
                    get: { log.promise ?? "" },
                    set: { log.promise = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                .lineLimit(2...3)
                .textFieldStyle(.roundedBorder)
                .onSubmit { try? context.save() }
            }
        }
    }

    private var hardThingCard: some View {
        NavigationLink {
            HardThingPickerView(selected: Binding(
                get: { (log.hardThingCategory, log.hardThingText) },
                set: { pair in
                    log.hardThingCategory = pair.0
                    log.hardThingText = pair.1
                    try? context.save()
                }
            ))
        } label: {
            Card {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hard thing")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(log.hardThingText ?? "Pick one. It has to be chosen and uncomfortable.")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var threeQuestionsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Three questions")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Toggle(isOn: Binding(
                    get: { log.promiseKept ?? false },
                    set: { log.promiseKept = $0; try? context.save() }
                )) {
                    Text("I kept my promise")
                        .foregroundStyle(Theme.textPrimary)
                }
                TextField("Where I broke", text: Binding(
                    get: { log.whereIBroke ?? "" },
                    set: { log.whereIBroke = $0.isEmpty ? nil : $0 }
                ), axis: .vertical).lineLimit(2...3).textFieldStyle(.roundedBorder)
                TextField("What triggered it", text: Binding(
                    get: { log.triggerNote ?? "" },
                    set: { log.triggerNote = $0.isEmpty ? nil : $0 }
                ), axis: .vertical).lineLimit(2...3).textFieldStyle(.roundedBorder)
            }
        }
    }

    private var examenCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Examen")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Walk back through the day with God.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                TextField("Notes", text: Binding(
                    get: { log.examenNotes ?? "" },
                    set: { log.examenNotes = $0.isEmpty ? nil : $0 }
                ), axis: .vertical).lineLimit(3...6).textFieldStyle(.roundedBorder)
            }
        }
    }

    private var eveningPrayerCard: some View {
        Card {
            HStack {
                Image(systemName: log.eveningPrayerPrayed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(log.eveningPrayerPrayed ? Theme.accent : Theme.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Evening prayer")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Psalm 127:2 · NIV")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button("Open") { showingEveningPrayer = true }
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    private var healthCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Body")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                HStack {
                    Text("Sleep")
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(log.sleepHours.map { String(format: "%.1f h", $0) } ?? "—")
                        .foregroundStyle(Theme.textPrimary)
                }
                HStack {
                    Text("Resting HR")
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(Format.heartRate(log.restingHR))
                        .foregroundStyle(Theme.textPrimary)
                }
                HStack {
                    Text("Energy (1–10)")
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    IntegerStepper(value: Binding(
                        get: { log.energy ?? 5 },
                        set: { log.energy = $0; try? context.save() }
                    ), range: 1...10)
                }
                SecondaryButton("Refresh from Health") {
                    Task { await refreshHealth() }
                }
            }
        }
    }

    private var journalPromptCard: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prayer journal")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(log.linkedJournalEntryID != nil ? "Entry saved for today." : "Add a note for today.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button(log.linkedJournalEntryID != nil ? "Edit" : "Add") {
                    showingJournalPrompt = true
                }
                .foregroundStyle(Theme.accent)
            }
        }
    }

    private func prayerSheet(_ prayer: Prayer, onPrayed: @escaping () -> Void) -> some View {
        NavigationStack {
            ScrollView {
                PrayerCard(prayer: prayer,
                           onPrayed: {
                               onPrayed()
                           },
                           onSkip: {})
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(prayer.title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }

    private func refreshHealth() async {
        if let hr = try? await HealthKitService.shared.latestRestingHR() {
            log.restingHR = hr
        }
        if let sleep = try? await HealthKitService.shared.lastNightSleepSeconds() {
            log.sleepHours = sleep / 3600
        }
        try? context.save()
    }
}

private struct JournalPromptSheet: View {
    let onSaved: (UUID) -> Void
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
                    let entry = PrayerJournalEntry(
                        text: text,
                        tag: tag.isEmpty ? nil : tag,
                        linkedFromDailyLog: true
                    )
                    context.insert(entry)
                    try? context.save()
                    onSaved(entry.id)
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

struct HardThingPickerView: View {
    @Binding var selected: (HardThingCategory?, String?)
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                ForEach(HardThingCategory.allCases, id: \.self) { cat in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(cat.label)
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        ForEach(HardThings.byCategory(cat)) { ht in
                            Button {
                                selected = (cat, ht.text)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(ht.text)
                                        .foregroundStyle(Theme.textPrimary)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    if selected.1 == ht.text {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Theme.accent)
                                    }
                                }
                                .padding()
                                .background(Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Hard thing")
        .navigationBarTitleDisplayMode(.inline)
    }
}
