import SwiftUI

struct ScriptsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.default) {
                ForEach(Scripts.all) { script in
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(script.situation.uppercased())
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                            Text(script.script)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Theme.textPrimary)
                            if let v = BibleVerses.byReference(script.anchorReference) {
                                Divider().background(Theme.textSecondary.opacity(0.3))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(v.reference + " · NIV")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(v.text)
                                        .font(.footnote)
                                        .foregroundStyle(Theme.verseBody)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Scripts")
        .navigationBarTitleDisplayMode(.inline)
    }
}
