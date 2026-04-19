import SwiftUI

struct LogTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        DailyLogView()
                    } label: {
                        Label("Daily log", systemImage: "sun.max.fill")
                    }
                    NavigationLink {
                        GtgLogView()
                    } label: {
                        Label("GTG pull-ups", systemImage: "figure.strengthtraining.traditional")
                    }
                    NavigationLink {
                        RuckLogView()
                    } label: {
                        Label("Ruck", systemImage: "figure.hiking")
                    }
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Log")
        }
    }
}
