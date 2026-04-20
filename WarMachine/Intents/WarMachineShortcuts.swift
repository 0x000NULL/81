import AppIntents

struct WarMachineShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogGtgSetIntent(),
            phrases: [
                "Log a GTG set in \(.applicationName)",
                "Log pull-ups in \(.applicationName)",
                "Add a GTG set to \(.applicationName)",
            ],
            shortTitle: "Log GTG Set",
            systemImageName: "figure.strengthtraining.traditional"
        )
    }
}
