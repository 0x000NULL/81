import SwiftUI

/// Edits `UserProfile.availablePlatesLb` as a multi-select over the
/// common plate denominations. The PlateCalculator only uses plates in
/// this list — denominations the user doesn't own stay out.
struct PlateInventoryEditor: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let allPlates: [Double] = [45, 35, 25, 15, 10, 5, 2.5, 1.25]

    var body: some View {
        Form {
            Section {
                ForEach(allPlates, id: \.self) { plate in
                    Toggle(label(for: plate), isOn: Binding(
                        get: { profile.availablePlatesLb.contains(plate) },
                        set: { isOn in
                            var set = Set(profile.availablePlatesLb)
                            if isOn { set.insert(plate) } else { set.remove(plate) }
                            profile.availablePlatesLb = set.sorted(by: >)
                            try? context.save()
                        }
                    ))
                }
            } footer: {
                Text("The plate calculator only uses denominations you own. Defaults: 45, 35, 25, 10, 5, 2.5.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Plate inventory")
    }

    private func label(for plate: Double) -> String {
        if plate.truncatingRemainder(dividingBy: 1) == 0 { return "\(Int(plate)) lb" }
        return String(format: "%.2f lb", plate)
    }
}
