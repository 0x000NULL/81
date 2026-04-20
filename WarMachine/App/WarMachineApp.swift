import SwiftUI
import SwiftData

@main
struct WarMachineApp: App {
    let container: ModelContainer = AppModelContainer.shared.container
    let launchError: String? = AppModelContainer.shared.launchError
    @State private var deepLink: DeepLink?

    var body: some Scene {
        WindowGroup {
            Group {
                if let launchError {
                    LaunchErrorView(message: launchError)
                } else {
                    AppRouter()
                        .task { await onLaunch() }
                        .environment(\.deepLink, deepLink)
                        .onOpenURL { url in
                            if url.scheme == "warmachine", url.host == "gtg" {
                                deepLink = .gtg
                            }
                        }
                }
            }
            .preferredColorScheme(.dark)
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

private struct LaunchErrorView: View {
    let message: String
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Launch error")
                    .font(.title2.bold())
                Text("The SwiftData store failed to open. Copy this message and send it — it names the exact attribute/relationship to fix.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button(copied ? "Copied" : "Copy error") {
                    UIPasteboard.general.string = message
                    copied = true
                }
                .buttonStyle(.borderedProminent)
                Text(message)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(8)
            }
            .padding()
        }
    }
}
