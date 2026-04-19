import SwiftUI

struct PreWorkoutPrayerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onPrayed: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.default) {
                    PrayerCard(prayer: Prayers.preWorkout,
                               onPrayed: {
                                   onPrayed()
                                   dismiss()
                               },
                               onSkip: { dismiss() })
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Before you lift")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PostWorkoutPrayerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onPrayed: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.default) {
                    PrayerCard(prayer: Prayers.postWorkout,
                               onPrayed: {
                                   onPrayed()
                                   dismiss()
                               },
                               onSkip: { dismiss() })
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Work done")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
