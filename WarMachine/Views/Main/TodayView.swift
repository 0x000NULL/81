import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @Query private var sessions: [WorkoutSession]
    @Query private var dailyLogs: [DailyLog]
    @Query private var baselineTests: [BaselineTest]
    @Query private var favorites: [FavoriteVerse]
    @Query private var weeklyTargets: [WeeklyVerseTarget]

    @State private var showingSkipSheet = false
    @State private var showingResumeSheet = false
    @State private var showingIdentityEditor = false
    @State private var navigateToWorkout: WorkoutSession?
    @State private var utMilestone: Int?

    private var profile: UserProfile? { profiles.first }

    private var todayDayType: DayType {
        TrainingSchedule.dayType(on: .now)
    }

    private var currentWeek: Int {
        guard let profile else { return 1 }
        return TodayEngine.currentWeek(startDate: profile.startDate)
    }

    private var incompleteWorkout: WorkoutSession? {
        TodayEngine.incompleteWorkout(in: sessions)
    }

    private var todayLog: DailyLog? {
        let today = Calendar.current.startOfDay(for: .now)
        return dailyLogs.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private var returnPolicy: ReturnPolicy {
        guard let profile else { return .continueNormally }
        let completedSessions = sessions.filter { $0.completedAt != nil }
        let last = completedSessions.map { $0.completedAt! }.max()
        return ReturnEngine.evaluate(now: .now, lastCompletedWorkout: last,
                                     recentDailyLogs: dailyLogs, userProfile: profile)
    }

    private var verseOfDay: BibleVerse {
        VerseEngine.themedVerseOfDay(theme: VerseEngine.preferredTheme(for: todayDayType))
    }

    private var memorizationDue: FavoriteVerse? {
        VerseEngine.memorizationReviewDue(favorites: favorites)
    }

    private var currentWeeklyTarget: WeeklyVerseTarget? {
        VerseEngine.currentWeekTarget(targets: weeklyTargets).flatMap { target in
            target.dismissedAt == nil ? target : nil
        }
    }

    private var identitySentence: String {
        guard let profile else { return "" }
        return IdentityEngine.sentenceForToday(profile: profile)
    }

    private var identityReviewDue: Bool {
        guard let profile else { return false }
        return IdentityEngine.reviewDue(profile: profile)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                    headerSection
                    returnPolicyBanner
                    if incompleteWorkout != nil { resumeCard }
                    if let milestone = utMilestone { utBanner(milestone: milestone) }
                    if identityReviewDue { identityRevisitCard }
                    todayCard
                    if let target = currentWeeklyTarget {
                        WeeklyVerseCard(target: target, onSwap: swapWeeklyVerse)
                    }
                    VerseCard(verse: verseOfDay)
                    if let due = memorizationDue { memorizationReviewCard(for: due) }
                    dailyGritCard
                    gtgSummaryCard
                    RecoverySignalsCard()
                    healthSummaryCard
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    StrengthButton(context: .preWorkout)
                }
            }
            .sheet(isPresented: $showingSkipSheet) {
                SkipTodaySheet()
                    .preferredColorScheme(.dark)
            }
            .sheet(isPresented: $showingResumeSheet) {
                if let inc = incompleteWorkout {
                    ResumeWorkoutSheet(session: inc,
                                       onResume: { navigateToWorkout = inc; showingResumeSheet = false },
                                       onDiscard: {
                                           inc.abandoned = true
                                           try? context.save()
                                           showingResumeSheet = false
                                       })
                    .preferredColorScheme(.dark)
                }
            }
            .navigationDestination(item: $navigateToWorkout) { session in
                WorkoutView(sessionID: session.id)
            }
            .sheet(isPresented: $showingIdentityEditor) {
                if let p = profile {
                    IdentitySentencesEditorView(profile: p)
                        .preferredColorScheme(.dark)
                }
            }
        }
        .onAppear {
            computeUTMilestone()
            ensureWeeklyTarget()
        }
    }

    // MARK: Weekly verse

    private func ensureWeeklyTarget() {
        let monday = VerseEngine.weekStart(of: .now)
        // Skip if user already dismissed this week's target.
        if let existing = WeeklyVerseTargetStore.find(weekStartDate: monday, in: context) {
            if existing.reference.isEmpty {
                let pick = VerseEngine.pickWeeklyTarget(favorites: favorites, priorTargets: weeklyTargets)
                existing.reference = pick.reference
                existing.pickedAt = .now
                try? context.save()
            }
            return
        }
        let pick = VerseEngine.pickWeeklyTarget(favorites: favorites, priorTargets: weeklyTargets)
        _ = WeeklyVerseTargetStore.findOrCreate(weekStartDate: monday, reference: pick.reference, in: context)
        try? context.save()
    }

    private func swapWeeklyVerse() {
        guard let current = currentWeeklyTarget else { return }
        // Exclude the current reference from the pick by treating the current
        // target as a "prior" so it's in the 8-week skip list.
        let others = weeklyTargets.filter { $0.id != current.id }
        let pick = VerseEngine.pickWeeklyTarget(favorites: favorites, priorTargets: others + [current])
        current.reference = pick.reference
        current.pickedAt = .now
        current.memorizedAt = nil
        try? context.save()
    }

    // MARK: Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Week \(currentWeek) · Day \(daysSinceStart)")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            if profile != nil, !identitySentence.isEmpty {
                IdentityLine(sentence: identitySentence)
                    .onTapGesture { showingIdentityEditor = true }
            }
        }
    }

    private var identityRevisitCard: some View {
        Card {
            HStack(spacing: 12) {
                Image(systemName: "person.fill.questionmark")
                    .foregroundStyle(Theme.accent)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Identity check-in")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("30 days. Revisit who you say you are.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .onTapGesture { showingIdentityEditor = true }
    }

    private var daysSinceStart: Int {
        guard let profile else { return 1 }
        return max(1, Calendar.current.dateComponents([.day], from: profile.startDate, to: .now).day ?? 1)
    }

    @ViewBuilder
    private var returnPolicyBanner: some View {
        switch returnPolicy {
        case .injuryFlagged(let note):
            Banner(
                systemImage: "exclamationmark.triangle",
                title: "Injury noted.",
                message: (note ?? "See a physio. Work around it. Never train through sharp pain.") + "\nProgression is paused. You can still log."
            )
        case .returningFromIllness:
            Banner(
                systemImage: "arrow.uturn.up",
                title: "Returning from illness.",
                message: "Protocol: rest until 24h symptom-free, then 80% for 2–3 sessions."
            )
        case .restartAt(let pct, let rebuild):
            Banner(
                systemImage: "arrow.counterclockwise",
                title: "Restart at \(Int(pct * 100))%.",
                message: "Rebuild for \(rebuild) week\(rebuild == 1 ? "" : "s"). This isn't failure. It's return."
            )
        case .resumeAtCurrent:
            Banner(
                systemImage: "arrow.right",
                title: "Welcome back.",
                message: "Resume at current weights. Expect a rough first session."
            )
        case .travelOrLifeGap:
            Banner(
                systemImage: "checkmark",
                title: "Welcome back.",
                message: "Resuming at current weights."
            )
        case .continueNormally:
            EmptyView()
        }
    }

    private var resumeCard: some View {
        Banner(
            systemImage: "clock.arrow.circlepath",
            title: "Workout in progress.",
            message: "Resume the session you started earlier today."
        )
        .onTapGesture { showingResumeSheet = true }
    }

    private func utBanner(milestone: Int) -> some View {
        Banner(
            systemImage: "shield.lefthalf.filled",
            title: "Week \(milestone).",
            message: UncomfortableTruth.pullQuote
        )
        .onTapGesture {
            profile?.lastUTMilestoneShown = milestone
            try? context.save()
            utMilestone = nil
        }
    }

    private var todayCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today: \(todayDayType.label)")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(todayDayType.durationLabel)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: symbolForDay)
                        .font(.title)
                        .foregroundStyle(Theme.accent)
                }
                if todayDayType == .rest {
                    Text("Sabbath. Rest because He rested.")
                        .foregroundStyle(Theme.textSecondary)
                        .font(.footnote)
                } else {
                    PrimaryButton("Start Workout", systemImage: "play.fill") {
                        startWorkout()
                    }
                    SecondaryButton("Skip today", systemImage: "forward.fill") {
                        showingSkipSheet = true
                    }
                }
            }
        }
    }

    private var symbolForDay: String {
        switch todayDayType {
        case .legs, .push, .pull: return "figure.strengthtraining.traditional"
        case .intervals: return "figure.run"
        case .zone2: return "figure.run"
        case .grit: return "figure.hiking"
        case .rest: return "moon.fill"
        }
    }

    private func memorizationReviewCard(for fav: FavoriteVerse) -> some View {
        let verse = BibleVerses.byReference(fav.reference)
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                    Text("Memorization review")
                        .font(.caption.weight(.semibold))
                    Spacer()
                }
                .foregroundStyle(Theme.textSecondary)

                Text(fav.reference)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                if let v = verse {
                    Text(v.text)
                        .font(.footnote)
                        .foregroundStyle(Theme.verseBody)
                }
                Button {
                    fav.lastReviewedAt = .now
                    try? context.save()
                } label: {
                    Text("Reviewed")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.bg)
                        .clipShape(Capsule())
                        .foregroundStyle(Theme.textPrimary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var dailyGritCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Daily Grit")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                if let log = todayLog {
                    GritRow(label: "Morning prayer", done: log.morningPrayerPrayed)
                    GritRow(label: log.promise.map { "Promise: \($0)" } ?? "Promise: (not set)", done: log.promise != nil)
                    GritRow(label: log.hardThingText.map { "Hard thing: \($0)" } ?? "Hard thing: (not chosen)", done: log.hardThingText != nil)
                    GritRow(label: "Evening prayer", done: log.eveningPrayerPrayed)
                } else {
                    NavigationLink {
                        DailyLogView()
                    } label: {
                        Text("Open today's log")
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
        }
    }

    private var gtgSummaryCard: some View {
        let snap = GtgWidgetSnapshot.load()
        return Card {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GTG pull-ups")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(snap.count) / \(snap.target) today")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                NavigationLink("Log") { GtgLogView() }
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    private var healthSummaryCard: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resting HR")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Text(Format.heartRate(todayLog?.restingHR))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sleep")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Text(todayLog?.sleepHours.map { String(format: "%.1f h", $0) } ?? "—")
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
    }

    // MARK: Actions

    private func startWorkout() {
        if let existing = incompleteWorkout {
            navigateToWorkout = existing
            return
        }
        let session = WorkoutSession(dayType: todayDayType)
        session.startedAt = .now
        context.insert(session)
        try? context.save()
        navigateToWorkout = session
    }

    private func computeUTMilestone() {
        guard let profile else { return }
        utMilestone = TodayEngine.uncomfortableTruthMilestoneDue(
            now: .now,
            startDate: profile.startDate,
            lastShownMilestone: profile.lastUTMilestoneShown
        )
    }
}

private struct GritRow: View {
    let label: String
    let done: Bool
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? Theme.accent : Theme.textSecondary)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(done ? Theme.textSecondary : Theme.textPrimary)
            Spacer()
        }
    }
}
