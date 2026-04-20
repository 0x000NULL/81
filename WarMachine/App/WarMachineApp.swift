import SwiftUI
import SwiftData

@main
struct WarMachineApp: App {
    let container: ModelContainer = AppModelContainer.shared.container
    @State private var deepLink: DeepLink?

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .preferredColorScheme(.dark)
                .task { await onLaunch() }
                .environment(\.deepLink, deepLink)
                .onOpenURL { url in
                    if url.scheme == "warmachine", url.host == "gtg" {
                        deepLink = .gtg
                    }
                }
        }
        .modelContainer(container)
    }

    @MainActor
    private func onLaunch() async {
        let context = ModelContext(container)
        let sessions = (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        TodayEngine.cleanupStaleSessions(sessions)
        try? context.save()
        LoggerKindBackfill.run(context: context)
    }
}
