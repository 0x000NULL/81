import SwiftUI
import SwiftData
import UIKit

struct ICloudSyncSection: View {
    @Environment(\.modelContext) private var context
    @AppStorage(AppModelContainer.cloudSyncEnabledKey) private var syncEnabled: Bool = true
    @State private var requiresRestart: Bool = false
    @State private var showingBackups: Bool = false
    private let status = CloudKitStatusService.shared

    var body: some View {
        Section("iCloud Sync") {
            HStack {
                Label("Status", systemImage: statusIcon)
                Spacer()
                Text(status.accountStatus.label)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            if let last = status.lastSyncDate {
                HStack {
                    Text("Last \(status.lastEventDescription?.lowercased() ?? "sync")")
                    Spacer()
                    Text(last.formatted(.relative(presentation: .numeric)))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Toggle("Sync via iCloud", isOn: $syncEnabled)
                .onChange(of: syncEnabled) { _, _ in
                    requiresRestart = true
                }

            if requiresRestart {
                Text("Quit and reopen 81 to apply this change.")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
            }

            if status.accountStatus == .noAccount {
                Button("Open iCloud settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)
            }

            Button("Backups…") { showingBackups = true }

            Text("Workouts, daily logs, prayer journal, and PR cache sync to your private iCloud database. Daily JSON snapshots are also written to iCloud Drive (last 7 retained) so you can roll back if a destructive change syncs across devices.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .task { await status.refreshAccountStatus() }
        .sheet(isPresented: $showingBackups) {
            BackupsListSheet(context: context)
        }
    }

    private var statusIcon: String {
        switch status.accountStatus {
        case .available: "icloud.fill"
        case .noAccount, .restricted, .unavailable: "icloud.slash"
        case .unknown: "icloud"
        }
    }
}

private struct BackupsListSheet: View {
    let context: ModelContext
    @Environment(\.dismiss) private var dismiss
    @State private var files: [URL] = []
    @State private var pendingRestore: URL?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if files.isEmpty {
                    ContentUnavailableView(
                        "No backups yet",
                        systemImage: "icloud.slash",
                        description: Text("Backups appear here after the app foregrounds at least once with iCloud Drive available.")
                    )
                } else {
                    List(files, id: \.self) { url in
                        Button {
                            pendingRestore = url
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(url.lastPathComponent)
                                    .font(.body.monospacedDigit())
                                if let size = fileSize(url) {
                                    Text(size)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("iCloud Backups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { files = CloudBackupService.shared.listBackups() }
            .confirmationDialog(
                "Restore from this backup? Existing data will be replaced.",
                isPresented: Binding(
                    get: { pendingRestore != nil },
                    set: { if !$0 { pendingRestore = nil } }
                ),
                titleVisibility: .visible,
                presenting: pendingRestore
            ) { url in
                Button("Restore", role: .destructive) { restore(url) }
                Button("Cancel", role: .cancel) {}
            }
            .alert(
                "Restore failed",
                isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(error ?? "")
            }
        }
    }

    private func restore(_ url: URL) {
        do {
            try CloudBackupService.shared.restore(from: url, into: context)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func fileSize(_ url: URL) -> String? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let bytes = attrs[.size] as? Int else { return nil }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
