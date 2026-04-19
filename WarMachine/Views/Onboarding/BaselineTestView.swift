import SwiftUI

struct BaselineTestView: View {
    @Bindable var state: OnboardingState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Baseline test")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Honest numbers. You'll retest every 4 weeks. Estimates are fine — update later.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Card {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("1-mile run time")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        IntegerStepper(value: $state.baselineOneMile, range: 180...1200, step: 15)
                        Text(Format.duration(seconds: state.baselineOneMile))
                            .foregroundStyle(Theme.textSecondary)
                            .font(.caption)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Max push-ups in 2 min")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        IntegerStepper(value: $state.baselinePushUps, range: 0...200)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Max strict pull-ups")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        IntegerStepper(value: $state.baselinePullUps, range: 0...60)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("2-mile ruck (25 lb) time")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        IntegerStepper(value: $state.baselineRuck, range: 600...3600, step: 30)
                        Text(Format.duration(seconds: state.baselineRuck))
                            .foregroundStyle(Theme.textSecondary)
                            .font(.caption)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Resting HR (morning)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        NumberStepper(value: $state.baselineRestingHR, step: 1, range: 30...120,
                                      formatter: { "\(Int($0)) bpm" })
                    }
                }

                HStack {
                    SecondaryButton("Back") { state.back() }
                    PrimaryButton("Continue") { state.advance() }
                }
                .padding(.top)
            }
            .padding()
        }
    }
}
