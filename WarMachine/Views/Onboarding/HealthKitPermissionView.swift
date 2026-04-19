import SwiftUI

struct HealthKitPermissionView: View {
    @Bindable var state: OnboardingState
    @State private var isRequesting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.section) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Health access")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("81 reads your resting heart rate, sleep, HRV, and bodyweight to track recovery and autoregulate training. Workouts you complete are saved to Apple Health.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 12) {
                Row(symbol: "heart", label: "Resting heart rate + HRV")
                Row(symbol: "bed.double.fill", label: "Sleep (asleep core, REM, deep)")
                Row(symbol: "figure.walk", label: "Bodyweight")
                Row(symbol: "figure.strengthtraining.traditional", label: "Workouts (write)")
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Theme.destructive)
            }

            Spacer()
            HStack {
                SecondaryButton("Skip") { state.advance() }
                PrimaryButton(isRequesting ? "Requesting…" : "Grant access") {
                    Task { await request() }
                }
            }
        }
        .padding()
        .task {
            if let bw = try? await HealthKitService.shared.latestBodyweightLb(), bw > 80 {
                state.bodyweightLb = bw
            }
        }
    }

    private func request() async {
        isRequesting = true
        do {
            try await HealthKitService.shared.requestAuthorization()
            if let bw = try? await HealthKitService.shared.latestBodyweightLb(), bw > 80 {
                state.bodyweightLb = bw
            }
            state.advance()
        } catch {
            errorMessage = "Couldn't request Health access. You can continue without it."
        }
        isRequesting = false
    }
}

private struct Row: View {
    let symbol: String
    let label: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
            Text(label)
                .foregroundStyle(Theme.textPrimary)
        }
    }
}
