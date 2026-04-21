import SwiftUI
import Charts

/// Renders the two all-time charts for Sunday review. Accepts pre-aggregated
/// stats so the view has no fetch logic — caller bucketizes via
/// `WeeklyStatsEngine.weeklyStats`.
struct SundayReviewChartsSection: View {
    let stats: [WeeklyStats]

    /// Number of weeks visible at once when the dataset is longer than this.
    /// Beyond ~26 weeks the bars/points get too dense without scrolling.
    private let visibleWindow = 12
    private var isScrollable: Bool { stats.count > visibleWindow * 2 }
    /// For the visible-window API we need a length expressed as a time interval
    /// (seconds) when x is a Date — use weeks * 7 days.
    private var visibleSeconds: TimeInterval { Double(visibleWindow) * 7 * 24 * 60 * 60 }
    private var lastMonday: Date? { stats.last?.weekStartDate }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.section) {
            if stats.count < 2 {
                Card {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Trends")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Charts appear after your second full week.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            } else {
                promiseRateCard
                workoutCompletionCard
            }
        }
    }

    private var promiseRateCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Promise rate")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Kept ÷ logged per week")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)

                chart(builder: {
                    Chart(stats, id: \.weekStartDate) { s in
                        LineMark(
                            x: .value("Week", s.weekStartDate),
                            y: .value("Rate", s.promiseRate)
                        )
                        .foregroundStyle(Theme.accent)
                        .interpolationMethod(.catmullRom)
                        PointMark(
                            x: .value("Week", s.weekStartDate),
                            y: .value("Rate", s.promiseRate)
                        )
                        .foregroundStyle(Theme.accent)
                        .symbolSize(20)
                    }
                    .chartYScale(domain: 0...1)
                    .chartYAxis {
                        AxisMarks(values: [0, 0.5, 1]) { value in
                            AxisValueLabel {
                                if let pct = value.as(Double.self) {
                                    Text("\(Int(pct * 100))%")
                                }
                            }
                            AxisGridLine()
                        }
                    }
                })
                .frame(height: 180)
            }
        }
    }

    private var workoutCompletionCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Workouts per week")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Completed sessions, excluding abandoned")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)

                chart(builder: {
                    Chart(stats, id: \.weekStartDate) { s in
                        BarMark(
                            x: .value("Week", s.weekStartDate, unit: .weekOfYear),
                            y: .value("Workouts", s.workoutsCompleted)
                        )
                        .foregroundStyle(Theme.accent)
                    }
                    .chartYScale(domain: 0...7)
                })
                .frame(height: 160)
            }
        }
    }

    @ViewBuilder
    private func chart<Content: View>(@ViewBuilder builder: () -> Content) -> some View {
        if isScrollable, let end = lastMonday {
            let start = end.addingTimeInterval(-visibleSeconds)
            builder()
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: visibleSeconds)
                .chartScrollPosition(initialX: start)
        } else {
            builder()
        }
    }
}
