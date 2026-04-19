import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }

            LogTabView()
                .tabItem {
                    Label("Log", systemImage: "square.and.pencil")
                }

            LibraryTabView()
                .tabItem {
                    Label("Library", systemImage: "text.book.closed.fill")
                }

            ProgressTabView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(Theme.accent)
    }
}
