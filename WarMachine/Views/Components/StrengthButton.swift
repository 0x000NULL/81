import SwiftUI

struct StrengthButton: View {
    @State private var showingSheet = false
    let context: ScriptContext

    init(context: ScriptContext = .preWorkout) {
        self.context = context
    }

    var body: some View {
        Button {
            showingSheet = true
        } label: {
            Image(systemName: "shield.lefthalf.filled")
                .font(.title3)
                .foregroundStyle(Theme.accent)
        }
        .accessibilityLabel("Today's strength")
        .sheet(isPresented: $showingSheet) {
            ScriptsAndVersesSheet(context: context)
                .preferredColorScheme(.dark)
        }
    }
}
