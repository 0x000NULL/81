import SwiftUI

struct HardThingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                ForEach(HardThingCategory.allCases, id: \.self) { cat in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(cat.label)
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        ForEach(HardThings.byCategory(cat)) { ht in
                            Card {
                                Text(ht.text)
                                    .foregroundStyle(Theme.textPrimary)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Hard Things")
        .navigationBarTitleDisplayMode(.inline)
    }
}
