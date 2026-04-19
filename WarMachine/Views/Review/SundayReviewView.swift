import SwiftUI
import SwiftData

struct SundayReviewView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var reviews: [SundayReview]
    @Query private var sessions: [WorkoutSession]
    @Query private var daily: [DailyLog]
    @Query private var prayers: [PrayerLog]
    @Query private var meditations: [MeditationLog]

    @State private var pattern = ""
    @State private var win = ""
    @State private var focus = ""
    @State private var whereGod = ""

    private var weekStart: Date {
        let cal = Calendar.current
        var comp = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)
        comp.weekday = 2 // Monday
        return cal.date(from: comp) ?? Calendar.current.startOfDay(for: .now)
    }

    private var review: SundayReview {
        if let existing = reviews.first(where: {
            Calendar.current.isDate($0.weekStartDate, equalTo: weekStart, toGranularity: .weekOfYear)
        }) { return existing }
        let new = SundayReview(weekStartDate: weekStart)
        context.insert(new)
        try? context.save()
        return new
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                PrayerCard(prayer: Prayers.sabbath, onPrayed: {
                    review.sabbathPrayerPrayed = true
                    context.insert(PrayerLog(kind: .sabbath))
                    try? context.save()
                })

                if let v = BibleVerses.byReference("Mark 2:27") {
                    VerseCard(verse: v)
                }

                statsCard

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        promptField("Pattern — what did broken promises have in common?", text: $pattern)
                        promptField("Win of the week — one specific moment you pushed through.", text: $win)
                        promptField("Next week's one focus.", text: $focus)
                        promptField("Where did I see God this week?", text: $whereGod)
                    }
                }

                PrimaryButton("Lock this week", systemImage: "lock.fill") {
                    save()
                    dismiss()
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Sunday")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            pattern = review.pattern ?? ""
            win = review.win ?? ""
            focus = review.nextWeekFocus ?? ""
            whereGod = review.whereIsawGod ?? ""
            computeStats()
        }
    }

    private func promptField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            TextField("", text: text, axis: .vertical)
                .lineLimit(2...5)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var statsCard: some View {
        let cal = Calendar.current
        let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        let weekSessions = sessions.filter { $0.completedAt != nil && $0.date >= weekStart && $0.date < weekEnd }
        let weekDaily = daily.filter { $0.date >= weekStart && $0.date < weekEnd }
        let weekPrayers = prayers.filter { $0.prayedAt >= weekStart && $0.prayedAt < weekEnd }
        let weekMeds = meditations.filter { $0.completedAt >= weekStart && $0.completedAt < weekEnd }
        let promisesKept = weekDaily.filter { $0.promiseKept == true }.count
        let hardsDone = weekDaily.filter { $0.hardThingText != nil }.count

        return Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("This week")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                statRow("Workouts", "\(weekSessions.count)/6")
                statRow("Promises kept", "\(promisesKept)/7")
                statRow("Hard things", "\(hardsDone)/7")
                statRow("Prayers prayed", "\(weekPrayers.count)")
                statRow("Meditations", "\(weekMeds.count)")
            }
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value).foregroundStyle(Theme.textPrimary).font(.body.monospacedDigit())
        }
    }

    private func computeStats() {
        let cal = Calendar.current
        let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        review.workoutsCompleted = sessions.filter { $0.completedAt != nil && $0.date >= weekStart && $0.date < weekEnd }.count
        let weekDaily = daily.filter { $0.date >= weekStart && $0.date < weekEnd }
        review.promisesKept = weekDaily.filter { $0.promiseKept == true }.count
        review.hardThingsDone = weekDaily.filter { $0.hardThingText != nil }.count
        review.prayersPrayed = prayers.filter { $0.prayedAt >= weekStart && $0.prayedAt < weekEnd }.count
        review.meditationsLogged = meditations.filter { $0.completedAt >= weekStart && $0.completedAt < weekEnd }.count
    }

    private func save() {
        review.pattern = pattern.isEmpty ? nil : pattern
        review.win = win.isEmpty ? nil : win
        review.nextWeekFocus = focus.isEmpty ? nil : focus
        review.whereIsawGod = whereGod.isEmpty ? nil : whereGod
        try? context.save()
    }
}
