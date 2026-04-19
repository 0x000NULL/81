import SwiftUI
import SwiftData
import Charts

struct ProgressTabView: View {
    @Query(sort: [SortDescriptor(\BaselineTest.date)]) private var baselines: [BaselineTest]
    @Query(sort: [SortDescriptor(\RuckLog.date)]) private var rucks: [RuckLog]
    @Query private var lifts: [LiftProgression]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                    NavigationLink {
                        TimelineView()
                    } label: {
                        Card {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Timeline")
                                        .foregroundStyle(Theme.textPrimary)
                                    Text("12-week phases · You are here")
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    mainLiftsCard
                    ruckPaceCard
                    baselineCard
                    NavigationLink {
                        BaselineReviewView()
                    } label: {
                        Card {
                            HStack {
                                Text("Baseline comparison")
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    NavigationLink {
                        SundayReviewView()
                    } label: {
                        Card {
                            HStack {
                                Text("Sunday review")
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Progress")
        }
    }

    private var mainLiftsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Main lifts")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                ForEach(lifts.filter { $0.isMainLift }) { lift in
                    HStack {
                        Text(lift.displayName).foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text(Format.weight(lift.currentWeightLb))
                            .foregroundStyle(Theme.textPrimary)
                            .font(.body.monospacedDigit())
                    }
                }
            }
        }
    }

    private var ruckPaceCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ruck pace")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                if rucks.isEmpty {
                    Text("No rucks logged yet.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Chart(rucks) { r in
                        LineMark(
                            x: .value("Date", r.date),
                            y: .value("Pace", r.paceMinPerMile)
                        )
                        .foregroundStyle(Theme.accent)
                    }
                    .frame(height: 160)
                }
            }
        }
    }

    private var baselineCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Baseline tests")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                if baselines.isEmpty {
                    Text("Complete your first at week 0.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Chart(baselines) { b in
                        if let pushUps = b.maxPushUpsTwoMin {
                            LineMark(
                                x: .value("Week", b.weekNumber),
                                y: .value("Push-ups", pushUps)
                            )
                            .foregroundStyle(Theme.accent)
                        }
                    }
                    .frame(height: 160)
                }
            }
        }
    }
}
