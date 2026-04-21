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
                            guard url.scheme == "warmachine" else { return }
                            switch url.host {
                            case "gtg": deepLink = .gtg
                            case "verse": deepLink = .weeklyVerse
                            default: break
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
        // v1.5: seed identitySentences from legacy single sentence (no-op once
        // the array is populated). Runs per-launch, cheap, idempotent.
        let profiles = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        for profile in profiles { IdentityEngine.seedIfNeeded(profile: profile) }
        try? context.save()
        LoggerKindBackfill.run(context: context)
        _ = try? CloudBackupService.shared.writeDailyBackupIfNeeded(context: context)

        // v1.5: book the identity-review one-shot notification based on current
        // profile state. Re-booked elsewhere when the user marks reviewed.
        if let profile = profiles.first,
           NotificationService.Prefs.bool(NotificationService.Prefs.identityReviewEnabled) {
            let due = IdentityEngine.nextReviewDueAt(profile: profile)
            await NotificationService.shared.scheduleIdentityReview(dueAt: due, enabled: true)
        }
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
