import SwiftUI

struct MeditationsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.default) {
                ForEach(Meditations.all) { m in
                    NavigationLink {
                        MeditationDetailView(meditation: m)
                    } label: {
                        Card {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(m.title)
                                        .font(.headline)
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text(m.durationLabel)
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Text(m.context)
                                    .font(.caption)
                                    .foregroundStyle(Theme.accent)
                                Text(m.description)
                                    .font(.footnote)
                                    .foregroundStyle(Theme.verseBody)
                                    .lineLimit(3)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Meditations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MeditationDetailView: View {
    let meditation: Meditation
    @Environment(\.modelContext) private var context

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(meditation.context)
                            .font(.caption)
                            .foregroundStyle(Theme.accent)
                        Text(meditation.description)
                            .font(.body)
                            .foregroundStyle(Theme.verseBody)
                        Text("Duration: \(meditation.durationLabel)")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        ForEach(Array(meditation.steps.enumerated()), id: \.offset) { idx, step in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("\(idx + 1).")
                                    .foregroundStyle(Theme.textSecondary)
                                Text(step)
                                    .foregroundStyle(Theme.verseBody)
                            }
                        }
                    }
                }

                PrimaryButton("Mark complete", systemImage: "checkmark.circle.fill") {
                    context.insert(MeditationLog(
                        kind: meditation.kind,
                        durationMinutes: meditation.durationRange.lowerBound
                    ))
                    try? context.save()
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(meditation.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
