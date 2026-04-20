import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    @State private var morningHour: Int = 6
    @State private var morningMinute: Int = 45
    @State private var eveningHour: Int = 21
    @State private var eveningMinute: Int = 0
    @State private var workoutHour: Int = 18

    @State private var showingReset = false
    @State private var showingExporter: URL?
    @State private var showingImporter = false
    @State private var showingAbout = false
    @State private var dataError: String?
    @State private var birthDate: Date = Date()
    @State private var birthDateSet: Bool = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications") {
                    HStack {
                        Text("Morning")
                        Spacer()
                        Picker("", selection: $morningHour) {
                            ForEach(4..<12) { Text("\($0):").tag($0) }
                        }.labelsHidden()
                        Picker("", selection: $morningMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) {
                                Text(String(format: "%02d", $0)).tag($0)
                            }
                        }.labelsHidden()
                    }
                    HStack {
                        Text("Workout")
                        Spacer()
                        Picker("", selection: $workoutHour) {
                            ForEach(12..<22) { Text("\($0):00").tag($0) }
                        }.labelsHidden()
                    }
                    HStack {
                        Text("Evening")
                        Spacer()
                        Picker("", selection: $eveningHour) {
                            ForEach(17..<24) { Text("\($0):").tag($0) }
                        }.labelsHidden()
                        Picker("", selection: $eveningMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) {
                                Text(String(format: "%02d", $0)).tag($0)
                            }
                        }.labelsHidden()
                    }
                    Button("Reschedule") {
                        saveTimes()
                    }
                }

                Section("Birthday") {
                    Toggle("Set birthday", isOn: $birthDateSet)
                        .onChange(of: birthDateSet) { _, isOn in
                            profile?.birthDate = isOn ? birthDate : nil
                            try? context.save()
                        }
                    if birthDateSet {
                        DatePicker("Birthday",
                                   selection: $birthDate,
                                   in: ...Date(),
                                   displayedComponents: .date)
                            .onChange(of: birthDate) { _, newVal in
                                profile?.birthDate = newVal
                                try? context.save()
                            }
                        if let age = profile?.ageYears() {
                            Text("Age: \(age) · Zone 2 target ≤ \(180 - age) bpm")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    } else {
                        Text("Required for the Thursday Zone 2 target (180 − age).")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Section("Workout") {
                    workoutSection
                }

                Section("State") {
                    if let p = profile {
                        Text("Bodyweight: \(Format.weight(p.bodyweightLb))")
                        Text("Level: \(p.level.label)")
                        Text("Start date: \(p.startDate.formatted(date: .abbreviated, time: .omitted))")
                        if p.injuryFlag {
                            Button("Clear injury flag") {
                                p.injuryFlag = false
                                p.injuryNote = nil
                                try? context.save()
                            }
                            .foregroundStyle(Theme.destructive)
                        }
                        if p.rebuildModeRemainingSessions > 0 {
                            Button("Clear rebuild mode (\(p.rebuildModeRemainingSessions) left)") {
                                p.rebuildModeRemainingSessions = 0
                                try? context.save()
                            }
                        }
                    }
                }

                Section("Data") {
                    Button("Export JSON") {
                        exportData()
                    }
                    Button("Import JSON") {
                        showingImporter = true
                    }
                }

                ICloudSyncSection()

                Section("About") {
                    Button("The Uncomfortable Truth") {
                        showingAbout = true
                    }
                    Label("81 — War Machine Protocol", systemImage: "shield.lefthalf.filled")
                        .foregroundStyle(Theme.textSecondary)
                }

                Section {
                    Button("Reset all data", role: .destructive) {
                        showingReset = true
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .onAppear {
                if let p = profile {
                    morningHour = p.morningReminderHour
                    morningMinute = p.morningReminderMinute
                    eveningHour = p.eveningReminderHour
                    eveningMinute = p.eveningReminderMinute
                    workoutHour = p.workoutReminderHour
                    if let dob = p.birthDate {
                        birthDate = dob
                        birthDateSet = true
                    }
                }
            }
            .confirmationDialog("Reset everything?", isPresented: $showingReset, titleVisibility: .visible) {
                Button("Delete all and re-onboard", role: .destructive) {
                    resetAll()
                }
            }
            .fileExporter(
                isPresented: Binding(get: { showingExporter != nil },
                                     set: { if !$0 { showingExporter = nil } }),
                document: showingExporter.map { JSONDoc(url: $0) },
                contentType: .json,
                defaultFilename: "81-export"
            ) { _ in }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json]
            ) { result in
                if case .success(let url) = result {
                    importData(from: url)
                }
            }
            .sheet(isPresented: $showingAbout) {
                AboutUncomfortableTruthView()
                    .preferredColorScheme(.dark)
            }
            .alert(
                "Data error",
                isPresented: Binding(get: { dataError != nil },
                                     set: { if !$0 { dataError = nil } })
            ) {
                Button("OK", role: .cancel) { dataError = nil }
            } message: {
                Text(dataError ?? "")
            }
        }
    }

    @ViewBuilder
    private var workoutSection: some View {
        if let p = profile {
            HStack {
                Text("Bar weight")
                Spacer()
                Picker("", selection: Binding(
                    get: { p.preferredBarbellLb },
                    set: { newVal in
                        p.preferredBarbellLb = newVal
                        try? context.save()
                    }
                )) {
                    Text("45 lb").tag(45.0)
                    Text("35 lb (women's)").tag(35.0)
                    Text("55 lb (trap)").tag(55.0)
                    Text("25 lb (EZ)").tag(25.0)
                }
                .labelsHidden()
            }
            NavigationLink {
                PlateInventoryEditor(profile: p)
            } label: {
                HStack {
                    Text("Plate inventory")
                    Spacer()
                    Text(p.availablePlatesLb.map { $0.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int($0))" : String(format: "%.1f", $0) }.joined(separator: ", "))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Toggle("Live GPS ruck (beta)", isOn: Binding(
                get: { p.liveGPSRuckEnabled },
                set: { newVal in
                    p.liveGPSRuckEnabled = newVal
                    try? context.save()
                }
            ))
            Button("Reset PR cache") {
                resetPRCache()
            }
            .foregroundStyle(Theme.textSecondary)
        }
    }

    private func resetPRCache() {
        try? context.delete(model: ExercisePRCache.self)
        try? context.save()
    }

    private func saveTimes() {
        guard let profile else { return }
        profile.morningReminderHour = morningHour
        profile.morningReminderMinute = morningMinute
        profile.eveningReminderHour = eveningHour
        profile.eveningReminderMinute = eveningMinute
        profile.workoutReminderHour = workoutHour
        try? context.save()
        Task {
            await NotificationService.shared.scheduleAllRecurring(
                morningHour: morningHour, morningMinute: morningMinute,
                workoutHour: workoutHour,
                eveningHour: eveningHour, eveningMinute: eveningMinute
            )
        }
    }

    private func exportData() {
        do {
            let payload = try ExportService.buildPayload(context: context)
            let url = try ExportService.writeToTempFile(payload)
            showingExporter = url
        } catch {
            dataError = "Export failed: \(error.localizedDescription)"
        }
    }

    private func importData(from url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                dataError = "Couldn't access the selected file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            let data = try Data(contentsOf: url)
            let payload = try ExportService.decode(data)
            try ExportService.importPayload(payload, into: context)
        } catch {
            dataError = "Import failed: \(error.localizedDescription)"
        }
    }

    private func resetAll() {
        try? context.delete(model: UserProfile.self)
        try? context.delete(model: WorkoutSession.self)
        try? context.delete(model: ExerciseLog.self)
        try? context.delete(model: SetLog.self)
        try? context.delete(model: LiftProgression.self)
        try? context.delete(model: DailyLog.self)
        try? context.delete(model: GtgLog.self)
        try? context.delete(model: RuckLog.self)
        try? context.delete(model: SundayReview.self)
        try? context.delete(model: BaselineTest.self)
        try? context.delete(model: BookProgress.self)
        try? context.delete(model: EquipmentItem.self)
        try? context.delete(model: PrayerLog.self)
        try? context.delete(model: MeditationLog.self)
        try? context.delete(model: FavoriteVerse.self)
        try? context.delete(model: PrayerJournalEntry.self)
        try? context.delete(model: WarmUpLog.self)
        try? context.delete(model: ExercisePRCache.self)
        try? context.save()
        Task { await NotificationService.shared.cancelAll() }
    }
}

struct AboutUncomfortableTruthView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                    Text(UncomfortableTruth.passage)
                        .font(.body)
                        .foregroundStyle(Theme.verseBody)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("The Uncomfortable Truth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct JSONDoc: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let url: URL?

    init(url: URL) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {
        self.url = nil
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url else { return FileWrapper(regularFileWithContents: Data()) }
        return try FileWrapper(url: url, options: .immediate)
    }
}
