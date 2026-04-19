import SwiftUI
import SwiftData

@Observable
@MainActor
final class OnboardingState {
    enum Step: Int, CaseIterable { case welcome, level, healthKit, bodyStats, identity, baseline, uncomfortableTruth }

    var step: Step = .welcome
    var level: TrainingLevel = .intermediate
    var bodyweightLb: Double = 180
    var waistInches: Double = 34
    var identitySentence: String = "I am a son of God who does the work."
    var baselineOneMile: Int = 480
    var baselinePushUps: Int = 30
    var baselinePullUps: Int = 5
    var baselineRuck: Int = 1800
    var baselineRestingHR: Double = 60

    func advance() {
        if let next = Step(rawValue: step.rawValue + 1) {
            step = next
        }
    }

    func back() {
        if let prev = Step(rawValue: step.rawValue - 1) {
            step = prev
        }
    }
}

struct OnboardingCoordinator: View {
    @State private var state = OnboardingState()
    @Environment(\.modelContext) private var context
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            switch state.step {
            case .welcome:
                WelcomeView(state: state)
            case .level:
                LevelSelectionView(state: state)
            case .healthKit:
                HealthKitPermissionView(state: state)
            case .bodyStats:
                BodyStatsView(state: state)
            case .identity:
                IdentityView(state: state)
            case .baseline:
                BaselineTestView(state: state)
            case .uncomfortableTruth:
                UncomfortableTruthOnboardingView {
                    completeOnboarding()
                }
            }
        }
    }

    private func completeOnboarding() {
        let profile = UserProfile()
        profile.level = state.level
        profile.bodyweightLb = state.bodyweightLb
        profile.waistInches = state.waistInches
        profile.identitySentence = state.identitySentence
        profile.startDate = .now
        context.insert(profile)

        let baseline = BaselineTest(date: .now, weekNumber: 0)
        baseline.oneMileRunSeconds = state.baselineOneMile
        baseline.maxPushUpsTwoMin = state.baselinePushUps
        baseline.maxPullUps = state.baselinePullUps
        baseline.twoMileRuckSeconds = state.baselineRuck
        baseline.twoMileRuckWeightLb = 25
        baseline.restingHR = state.baselineRestingHR
        baseline.bodyweightLb = state.bodyweightLb
        baseline.waistInches = state.waistInches
        context.insert(baseline)

        for lift in StartingWeights.allLiftKeys {
            let w = StartingWeights.weight(for: lift.key, level: state.level, bodyweight: state.bodyweightLb)
            let lp = LiftProgression(liftKey: lift.key, displayName: lift.name,
                                     currentWeightLb: w, isMainLift: lift.isMain)
            context.insert(lp)
        }

        for spec in Equipment.all {
            let item = EquipmentItem(name: spec.name, isMustHave: spec.isMustHave,
                                     approxCost: spec.approxCost, note: spec.note)
            context.insert(item)
        }

        for book in Books.all {
            let bp = BookProgress(title: book.title, author: book.author, isChristian: book.isChristian)
            context.insert(bp)
        }

        try? context.save()

        Task {
            await NotificationService.shared.scheduleAllRecurring(
                morningHour: profile.morningReminderHour,
                morningMinute: profile.morningReminderMinute,
                workoutHour: profile.workoutReminderHour,
                eveningHour: profile.eveningReminderHour,
                eveningMinute: profile.eveningReminderMinute
            )
        }

        onComplete()
    }
}
