import Foundation

struct TrainingPhase: Identifiable, Hashable, Sendable {
    let range: ClosedRange<Int>      // 1-based week numbers within a 12-week cycle
    let name: String
    let summary: String
    let isDeload: Bool

    var id: Int { range.lowerBound }
}

enum TrainingPhases {

    /// The four phases of a 12-week cycle. Anchors match the engine logic:
    /// deloads at weeks 6 and 12, baselines at 0/4/8/12.
    static let all: [TrainingPhase] = [
        TrainingPhase(
            range: 1...5,
            name: "Accumulation — Block 1",
            summary: "Build volume off the starting weights. Main lifts autoregulate up; accessories stay consistent. Baseline re-tested at week 4.",
            isDeload: false
        ),
        TrainingPhase(
            range: 6...6,
            name: "Deload",
            summary: "Weights drop to 60%. Keep the groove; let the body catch up.",
            isDeload: true
        ),
        TrainingPhase(
            range: 7...11,
            name: "Accumulation — Block 2",
            summary: "Return to autoregulated progression. Baseline re-tested at week 8.",
            isDeload: false
        ),
        TrainingPhase(
            range: 12...12,
            name: "Deload + Final Baseline",
            summary: "Second deload. Re-run the baseline test to close the 12-week cycle.",
            isDeload: true
        )
    ]

    /// Weeks that carry a baseline test.
    static let baselineWeeks: Set<Int> = [4, 8, 12]

    /// Phase containing the given week, wrapping past week 12 so cycles keep working.
    static func phase(forWeek week: Int) -> TrainingPhase {
        let normalized = normalizedWeek(week)
        return all.first { $0.range.contains(normalized) } ?? all[0]
    }

    /// Maps arbitrary week numbers back into the 1...12 cycle.
    static func normalizedWeek(_ week: Int) -> Int {
        guard week > 0 else { return 1 }
        let mod = ((week - 1) % 12) + 1
        return mod
    }
}
