import SwiftUI
import SwiftData

struct WorkoutView: View {
    let sessionID: UUID
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var sessions: [WorkoutSession]
    @Query private var profiles: [UserProfile]

    @State private var warmUpDone = false
    @State private var showingPreWorkoutPrayer = false
    @State private var showingSummary = false
    @State private var restTimerDuration: Int?
    @State private var pendingGritSessionID: UUID?

    private var session: WorkoutSession? {
        sessions.first { $0.id == sessionID }
    }

    private var profile: UserProfile? { profiles.first }

    private var specsForDay: [ExerciseSpec] {
        guard let session else { return [] }
        return Exercises.forDay(session.dayType)
    }

    private var specsByKey: [String: ExerciseSpec] {
        Dictionary(uniqueKeysWithValues: specsForDay.map { ($0.key, $0) })
    }

    private var weightMultiplier: Double {
        guard let profile, let session else { return 1 }
        let week = TodayEngine.currentWeek(startDate: profile.startDate, now: session.date)
        return DeloadEngine.weightMultiplier(
            weekNumber: week,
            rebuildModeActive: profile.rebuildModeRemainingSessions > 0,
            returnRestartPercent: nil
        )
    }

    var body: some View {
        Group {
            if let session {
                WorkoutPagerView(
                    session: session,
                    exercises: exercises(for: session),
                    specsByKey: specsByKey,
                    weightMultiplier: weightMultiplier,
                    restTimerDuration: restTimerDuration,
                    warmUpDone: $warmUpDone,
                    modeBanner: modeBannerView,
                    onStartRest: startRest,
                    onSkipRest: skipRest,
                    onTravelToggle: { newVal in applyTravelToggle(session: session, enabled: newVal) },
                    onFinishTapped: { showingSummary = true }
                )
            } else {
                Color.clear
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(session?.dayType.label ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                StrengthButton(context: .midWorkout)
            }
        }
        .onAppear { configureOnFirstOpen() }
        .sheet(isPresented: $showingPreWorkoutPrayer) {
            PreWorkoutPrayerSheet(onPrayed: {
                session?.prePrayed = true
                try? context.save()
            })
        }
        .sheet(isPresented: $showingSummary) {
            if let session {
                WorkoutSummaryView(session: session, onDone: {
                    showingSummary = false
                    if session.dayType == .grit, shouldOpenGritCircuit() {
                        let grit = WorkoutSession(dayType: .grit)
                        grit.startedAt = .now
                        context.insert(grit)
                        try? context.save()
                        pendingGritSessionID = grit.id
                    } else {
                        dismiss()
                    }
                })
                .preferredColorScheme(.dark)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { pendingGritSessionID != nil },
            set: { if !$0 {
                pendingGritSessionID = nil
                dismiss()
            } }
        )) {
            if let id = pendingGritSessionID {
                NavigationStack {
                    GritCircuitView(sessionID: id)
                }
                .preferredColorScheme(.dark)
            }
        }
    }

    /// True when we should auto-present the Grit Circuit after the ruck:
    /// today is Saturday (.grit) and no completed grit circuit exists yet today
    /// besides the session we just completed.
    private func shouldOpenGritCircuit() -> Bool {
        guard TrainingSchedule.dayType(on: .now) == .grit else { return false }
        let cal = Calendar.current
        let others = sessions.filter { $0.id != sessionID }
        return !others.contains { s in
            guard s.dayType == .grit, let done = s.completedAt else { return false }
            return cal.isDate(done, inSameDayAs: .now)
        }
    }

    private var modeBannerView: AnyView? {
        guard weightMultiplier < 1 else { return nil }
        return AnyView(
            Banner(
                systemImage: "arrow.down.circle",
                title: modeTitle,
                message: modeMessage
            )
        )
    }

    private var modeTitle: String {
        guard let profile else { return "Reduced weights." }
        if profile.rebuildModeRemainingSessions > 0 { return "Rebuild mode." }
        return "Deload week."
    }

    private var modeMessage: String {
        guard let profile else { return "Weights scaled." }
        if profile.rebuildModeRemainingSessions > 0 {
            return "80% weights for \(profile.rebuildModeRemainingSessions) more session\(profile.rebuildModeRemainingSessions == 1 ? "" : "s")."
        }
        return "Working weights cut 40%. Same movements."
    }

    private func applyTravelToggle(session: WorkoutSession, enabled: Bool) {
        session.isTravelMode = enabled
        applyTravelMode(session: session, enabled: enabled)
        try? context.save()
    }

    private func configureOnFirstOpen() {
        guard let session else { return }
        if session.startedAt == nil {
            session.startedAt = .now
        }
        if (session.exercises?.isEmpty ?? true) {
            seedExercises(for: session)
        }
        if !session.prePrayed && !(session.exercises?.isEmpty ?? true) {
            showingPreWorkoutPrayer = true
        }
    }

    private func exercises(for session: WorkoutSession) -> [ExerciseLog] {
        (session.exercises ?? []).sorted(by: { $0.orderIndex < $1.orderIndex })
    }

    private func seedExercises(for session: WorkoutSession) {
        guard let profile else { return }
        let specs = Exercises.forDay(session.dayType)
        for spec in specs {
            let baseWeight = StartingWeights.weight(for: spec.key, level: profile.level, bodyweight: profile.bodyweightLb)
            let log = ExerciseLog(
                orderIndex: spec.orderIndex,
                exerciseKey: spec.key,
                displayName: session.isTravelMode ? (spec.travelAlternative ?? spec.displayName) : spec.displayName,
                targetSets: spec.targetSets,
                targetRepsMin: spec.targetRepsMin,
                targetRepsMax: spec.targetRepsMax,
                targetWeight: baseWeight,
                restSeconds: spec.restSeconds
            )
            log.session = session
            log.loggerKind = spec.loggerKind
            log.alternativeChosen = session.isTravelMode ? spec.travelAlternative : nil
            log.isSwappedForTravel = session.isTravelMode
            context.insert(log)
            if session.exercises == nil { session.exercises = [] }
            session.exercises?.append(log)
        }
        try? context.save()
    }

    private func applyTravelMode(session: WorkoutSession, enabled: Bool) {
        let specs = Exercises.forDay(session.dayType)
        for ex in session.exercises ?? [] {
            guard let spec = specs.first(where: { $0.key == ex.exerciseKey }) else { continue }
            if enabled, let alt = spec.travelAlternative {
                ex.alternativeChosen = alt
                ex.displayName = alt
                ex.isSwappedForTravel = true
            } else {
                ex.alternativeChosen = nil
                ex.displayName = spec.displayName
                ex.isSwappedForTravel = false
            }
        }
    }

    private func startRest(seconds: Int) {
        guard seconds > 0 else { return }
        restTimerDuration = seconds
        Task {
            await RestTimerService.shared.start(exerciseLogID: UUID(), setIndex: 0, duration: seconds)
        }
    }

    private func skipRest() {
        RestTimerService.shared.skip()
        restTimerDuration = nil
    }
}
