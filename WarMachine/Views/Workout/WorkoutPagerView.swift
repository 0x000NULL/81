import SwiftUI
import SwiftData

/// Walkthrough pager replacing the scrolling exercise list. Page layout:
///   0              — warm-up (+ travel mode toggle, pre-workout banner)
///   1 … N          — one exercise each
///   N + 1          — finish / summary gate
///
/// Uses `TabView(selection:)` with `.page(indexDisplayMode: .never)` so
/// swipes move between exercises while taps on inputs/buttons absorb the
/// gesture naturally.
struct WorkoutPagerView: View {
    let session: WorkoutSession
    let exercises: [ExerciseLog]
    let specsByKey: [String: ExerciseSpec]
    let weightMultiplier: Double
    let restTimerDuration: Int?
    @Binding var warmUpDone: Bool
    let modeBanner: AnyView?
    let onStartRest: (Int) -> Void
    let onSkipRest: () -> Void
    let onTravelToggle: (Bool) -> Void
    let onFinishTapped: () -> Void

    @Environment(\.modelContext) private var context
    @State private var selection: Int = 0
    @State private var showingOverview = false
    @State private var isPaused: Bool = false
    @State private var confirmingEmptyFinish = false

    var body: some View {
        VStack(spacing: 0) {
            WorkoutProgressBar(
                sessionStartedAt: session.startedAt,
                pauseIntervals: session.pauseIntervals,
                isPaused: isPaused,
                currentIndex: selection,
                totalPages: totalPages,
                completedFlags: completedFlags,
                onPauseToggle: togglePause,
                onOpenOverview: { showingOverview = true },
                onFinish: requestFinish
            )
            TabView(selection: $selection) {
                warmUpPage.tag(0)
                ForEach(Array(exercises.enumerated()), id: \.element.id) { idx, ex in
                    exercisePage(ex).tag(idx + 1)
                }
                WorkoutFinishPage(session: session, onFinishTapped: requestFinish)
                    .tag(exercises.count + 1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showingOverview) {
            WorkoutOverviewSheet(
                warmUpCompleted: warmUpDone,
                exercises: exercises,
                exerciseCompleted: Array(completedFlags.dropFirst().dropLast()),
                currentIndex: selection,
                onJump: { idx in
                    selection = max(0, min(idx, totalPages - 1))
                }
            )
            .preferredColorScheme(.dark)
        }
        .onAppear {
            isPaused = session.liveDurationModeRaw == "paused"
        }
        .confirmationDialog(
            "Finish with no sets logged?",
            isPresented: $confirmingEmptyFinish,
            titleVisibility: .visible
        ) {
            Button("Finish anyway") { onFinishTapped() }
            Button("Keep training", role: .cancel) {}
        } message: {
            Text("No working sets are recorded for this session. Finishing will mark it complete with zero volume.")
        }
    }

    private var hasLoggedAnySet: Bool {
        for ex in exercises {
            if (ex.sets ?? []).contains(where: { $0.isCompleted && $0.setType != .warmup }) {
                return true
            }
        }
        return false
    }

    private func requestFinish() {
        if hasLoggedAnySet {
            onFinishTapped()
        } else {
            confirmingEmptyFinish = true
        }
    }

    private var totalPages: Int { exercises.count + 2 }

    private var completedFlags: [Bool] {
        var out: [Bool] = [warmUpDone]
        for ex in exercises {
            let sets = ex.sets ?? []
            let normalDone = sets.filter { $0.isCompleted && $0.setType != .warmup }.count
            out.append(normalDone >= ex.targetSets)
        }
        out.append(false) // finish page never "complete" until tapped
        return out
    }

    // MARK: - Pages

    @ViewBuilder
    private var warmUpPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.default) {
                if let banner = modeBanner { banner }
                WarmUpCard(routine: WarmUps.of(session.dayType), session: session, done: $warmUpDone)
                travelModeCard
                if let duration = restTimerDuration {
                    RestTimerView(duration: duration, onSkip: onSkipRest)
                }
                Text("Swipe left to begin.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func exercisePage(_ exerciseLog: ExerciseLog) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.default) {
                ExerciseCardView(
                    exercise: exerciseLog,
                    spec: specsByKey[exerciseLog.exerciseKey],
                    weightMultiplier: weightMultiplier,
                    onStartRest: { _ in onStartRest(exerciseLog.restSeconds) }
                )
                if let duration = restTimerDuration {
                    RestTimerView(duration: duration, onSkip: onSkipRest)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var travelModeCard: some View {
        Card {
            HStack {
                Image(systemName: "airplane")
                    .foregroundStyle(session.isTravelMode ? Theme.accent : Theme.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Travel Mode")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Swaps every exercise to its bodyweight alternative.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { session.isTravelMode },
                    set: { newVal in onTravelToggle(newVal) }
                ))
                .labelsHidden()
            }
        }
    }

    private func togglePause() {
        session.pauseIntervals.append(.now)
        isPaused.toggle()
        session.liveDurationModeRaw = isPaused ? "paused" : "active"
        try? context.save()
    }
}
