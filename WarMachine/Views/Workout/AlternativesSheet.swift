import SwiftUI

struct AlternativesSheet: View {
    let spec: ExerciseSpec
    let currentChoice: String?
    let onChoose: (String?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(spec.displayName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Pick an alternative if equipment is unavailable or the movement bothers you.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)

                    Button {
                        onChoose(nil); dismiss()
                    } label: {
                        HStack {
                            Text("Original — \(spec.displayName)")
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            if currentChoice == nil {
                                Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                            }
                        }
                        .padding()
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                    }
                    .buttonStyle(.plain)

                    ForEach(spec.alternatives, id: \.self) { alt in
                        Button {
                            onChoose(alt); dismiss()
                        } label: {
                            HStack {
                                Text(alt)
                                    .foregroundStyle(Theme.textPrimary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                if currentChoice == alt {
                                    Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                                }
                            }
                            .padding()
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Alternatives")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
