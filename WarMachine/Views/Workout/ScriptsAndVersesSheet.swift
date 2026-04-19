import SwiftUI

struct ScriptsAndVersesSheet: View {
    let context: ScriptContext

    @Environment(\.dismiss) private var dismiss
    @State private var spotlighted: TalkScript?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.default) {
                    if let s = spotlighted {
                        Card {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(s.situation.uppercased())
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                                Text(s.script)
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let v = BibleVerses.byReference(s.anchorReference) {
                                    Divider().background(Theme.textSecondary.opacity(0.3))
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(v.reference)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Theme.textPrimary)
                                        Text(v.text)
                                            .font(.body)
                                            .foregroundStyle(Theme.verseBody)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }

                    PrimaryButton("Give me one", systemImage: "shield.lefthalf.filled") {
                        spotlighted = Scripts.pick(for: context)
                    }

                    Text("All scripts")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.top, Theme.Spacing.default)

                    ForEach(Scripts.all) { script in
                        Card {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(script.situation)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Theme.textSecondary)
                                Text(script.script)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(script.anchorReference + " · NIV")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .onTapGesture { spotlighted = script }
                    }
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Today's strength")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
    }
}
