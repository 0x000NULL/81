import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    private var absoluteWeek: Int {
        guard let profile else { return 1 }
        return TodayEngine.currentWeek(startDate: profile.startDate)
    }

    private var currentWeek: Int {
        TrainingPhases.normalizedWeek(absoluteWeek)
    }

    private var currentPhase: TrainingPhase {
        TrainingPhases.phase(forWeek: currentWeek)
    }

    private var cycleNumber: Int {
        max(1, ((absoluteWeek - 1) / 12) + 1)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                headerCard
                weekStrip
                phaseList
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Text("Cycle \(cycleNumber) · Week \(currentWeek)")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Text(currentPhase.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(currentPhase.summary)
                    .font(.footnote)
                    .foregroundStyle(Theme.verseBody)
            }
        }
    }

    private var weekStrip: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 4) {
                    ForEach(1...12, id: \.self) { week in
                        weekCell(week)
                    }
                }
                HStack {
                    legendDot(color: Theme.accent.opacity(0.5), label: "Accumulation")
                    legendDot(color: Theme.textSecondary.opacity(0.4), label: "Deload")
                    Spacer()
                    Image(systemName: "scope")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                    Text("Baseline")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private func weekCell(_ week: Int) -> some View {
        let phase = TrainingPhases.phase(forWeek: week)
        let isCurrent = week == currentWeek
        let isPast = week < currentWeek
        let isBaseline = TrainingPhases.baselineWeeks.contains(week)
        let baseColor: Color = phase.isDeload
            ? Theme.textSecondary.opacity(0.4)
            : Theme.accent.opacity(0.5)
        let fill: Color = isCurrent ? Theme.accent : (isPast ? baseColor : baseColor.opacity(0.35))

        return VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(fill)
                    .frame(height: 28)
                if isBaseline {
                    Image(systemName: "scope")
                        .font(.caption2)
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            Text("\(week)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(isCurrent ? Theme.textPrimary : Theme.textSecondary)
            if isCurrent {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.caption2)
                    .foregroundStyle(Theme.accent)
            } else {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.clear)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 10, height: 10)
            Text(label).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
    }

    private var phaseList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.default) {
            ForEach(TrainingPhases.all) { phase in
                Card {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(phase.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            if phase.range.contains(currentWeek) {
                                Text("You are here")
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Theme.accent.opacity(0.3))
                                    .clipShape(Capsule())
                                    .foregroundStyle(Theme.textPrimary)
                            }
                        }
                        Text(Self.rangeLabel(phase.range))
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        Text(phase.summary)
                            .font(.footnote)
                            .foregroundStyle(Theme.verseBody)
                    }
                }
            }
        }
    }

    private static func rangeLabel(_ range: ClosedRange<Int>) -> String {
        range.lowerBound == range.upperBound
            ? "Week \(range.lowerBound)"
            : "Weeks \(range.lowerBound)–\(range.upperBound)"
    }
}
