import SwiftUI

/// Ellipsis menu for a single set row — lets the user retag the set
/// (warm-up / normal / failure / drop) and edit or delete it.
struct SetTypeMenu: View {
    @Binding var setType: SetType
    let isPersisted: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSkip: () -> Void

    var body: some View {
        Menu {
            Section("Mark as") {
                ForEach(SetType.allCases, id: \.self) { kind in
                    Button {
                        setType = kind
                    } label: {
                        if setType == kind {
                            Label(kind.label, systemImage: "checkmark")
                        } else if let sym = kind.systemImage {
                            Label(kind.label, systemImage: sym)
                        } else {
                            Text(kind.label)
                        }
                    }
                }
            }
            if isPersisted {
                Section {
                    Button("Edit weight / reps…") { onEdit() }
                    Button("Delete set", role: .destructive) { onDelete() }
                }
            } else {
                Section {
                    Button("Skip this set") { onSkip() }
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 32, height: 32)
        }
        .accessibilityLabel("Set options")
    }
}
