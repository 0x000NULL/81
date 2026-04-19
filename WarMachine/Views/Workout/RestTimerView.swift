import SwiftUI

struct RestTimerView: View {
    let duration: Int
    @Bindable var timer = RestTimerService.shared
    let onSkip: () -> Void
    @State private var tickCount = 0

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "hourglass")
                        .foregroundStyle(Theme.accent)
                    Text("Rest")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text(remainingLabel)
                        .font(.title2.monospacedDigit())
                        .foregroundStyle(Theme.textPrimary)
                }
                ProgressView(value: progress)
                    .tint(Theme.accent)
                SecondaryButton("Skip rest", systemImage: "forward.fill", action: onSkip)
            }
        }
        .onReceive(Foundation.Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            timer.tick()
            tickCount &+= 1
        }
    }

    private var remainingLabel: String {
        Format.duration(seconds: timer.remainingSeconds)
    }

    private var progress: Double {
        guard duration > 0 else { return 0 }
        let elapsed = Double(duration - timer.remainingSeconds)
        return min(1, max(0, elapsed / Double(duration)))
    }
}
