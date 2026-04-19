import SwiftUI
import SwiftData

struct EquipmentView: View {
    @Environment(\.modelContext) private var context
    @Query private var items: [EquipmentItem]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                Text("Must-have")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                ForEach(items.filter { $0.isMustHave }) { item in
                    itemRow(item)
                }
                Text("Nice-to-have")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top)
                ForEach(items.filter { !$0.isMustHave }) { item in
                    itemRow(item)
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Equipment")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func itemRow(_ item: EquipmentItem) -> some View {
        Card {
            HStack(alignment: .top) {
                Button {
                    item.owned.toggle()
                    try? context.save()
                } label: {
                    Image(systemName: item.owned ? "checkmark.square.fill" : "square")
                        .foregroundStyle(item.owned ? Theme.accent : Theme.textSecondary)
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        if let cost = item.approxCost {
                            Text(cost)
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    if let note = item.note {
                        Text(note)
                            .font(.footnote)
                            .foregroundStyle(Theme.verseBody)
                    }
                }
            }
        }
    }
}
