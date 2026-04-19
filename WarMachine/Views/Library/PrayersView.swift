import SwiftUI

struct PrayersView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.default) {
                ForEach(Prayers.all) { prayer in
                    PrayerCard(prayer: prayer)
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Prayers")
        .navigationBarTitleDisplayMode(.inline)
    }
}
