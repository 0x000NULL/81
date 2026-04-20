import SwiftUI

/// Header strip for the walkthrough pager: session elapsed clock,
/// current page indicator, and a filled segment bar showing how many
/// exercises have at least one completed set.
struct WorkoutProgressBar: View {
    let sessionStartedAt: Date?
    let pauseIntervals: [Date]
    let isPaused: Bool
    let currentIndex: Int
    let totalPages: Int
    let completedFlags: [Bool]
    let onPauseToggle: () -> Void
    let onOpenOverview: () -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                elapsedLabel
                Spacer()
                Button(action: onPauseToggle) {
                    Image(systemName: isPaused ? "play.circle" : "pause.circle")
                        .font(.title3)
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPaused ? "Resume session" : "Pause session")
                Button(action: onOpenOverview) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.title3)
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Overview")
                Button(action: onFinish) {
                    Image(systemName: "flag.checkered")
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Finish workout")
            }
            segmentBar
            progressLabel
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Theme.bg)
    }

    @ViewBuilder
    private var elapsedLabel: some View {
        if let startedAt = sessionStartedAt {
            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                Text(Format.duration(seconds: elapsedSec(now: context.date, start: startedAt)))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
            }
        } else {
            Text("—")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func elapsedSec(now: Date, start: Date) -> Int {
        let gross = Int(now.timeIntervalSince(start))
        let pairs = pauseIntervals.chunked(into: 2)
        var paused = 0
        for p in pairs where p.count == 2 {
            paused += Int(p[1].timeIntervalSince(p[0]))
        }
        if isPaused, let last = pauseIntervals.last {
            paused += Int(now.timeIntervalSince(last))
        }
        return max(0, gross - paused)
    }

    @ViewBuilder
    private var segmentBar: some View {
        GeometryReader { geom in
            let count = max(1, totalPages)
            let gap: CGFloat = 4
            let segWidth = (geom.size.width - gap * CGFloat(count - 1)) / CGFloat(count)
            HStack(spacing: gap) {
                ForEach(0..<count, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(fillColor(for: i))
                        .frame(width: segWidth, height: 6)
                }
            }
        }
        .frame(height: 6)
    }

    private func fillColor(for index: Int) -> Color {
        if index < completedFlags.count, completedFlags[index] { return Theme.accent }
        if index == currentIndex { return Theme.textSecondary.opacity(0.8) }
        return Theme.surface
    }

    private var progressLabel: some View {
        HStack {
            Text("Exercise \(min(currentIndex + 1, totalPages)) of \(totalPages)")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
