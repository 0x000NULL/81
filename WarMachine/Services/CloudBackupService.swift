import Foundation
import SwiftData
import OSLog

private let log = Logger(subsystem: "app.81", category: "backup")

/// Defense-in-depth backups for the SwiftData store. Writes a dated
/// JSON snapshot to the app's iCloud Drive ubiquity container at most
/// once per calendar day, retaining the most recent 7 files.
///
/// Live CloudKit sync (Phase C) is convenient but propagates destructive
/// changes across devices. These dated snapshots give the user a roll-
/// back path that lives outside the synced store.
@MainActor
final class CloudBackupService {
    static let shared = CloudBackupService()

    nonisolated static let defaultRetainCount = 7

    private init() {}

    /// Returns the iCloud Drive "Documents" subdirectory inside the
    /// app's ubiquity container, creating it if needed. Nil when
    /// iCloud is not available (signed out, restricted, or sandbox
    /// limitation in tests).
    func backupDirectoryURL() -> URL? {
        guard let containerURL = FileManager.default
            .url(forUbiquityContainerIdentifier: AppModelContainer.cloudKitContainerID) else { return nil }
        let docsURL = containerURL.appendingPathComponent("Documents", isDirectory: true)
        try? FileManager.default.createDirectory(at: docsURL, withIntermediateDirectories: true)
        return docsURL
    }

    /// Writes a dated backup if today's file is missing. Returns the
    /// new file URL, or nil when skipped (already wrote today, no
    /// directory available).
    @discardableResult
    func writeDailyBackupIfNeeded(
        context: ModelContext,
        directory: URL? = nil,
        now: Date = .now,
        retainCount: Int = defaultRetainCount
    ) throws -> URL? {
        let dir: URL
        if let directory {
            dir = directory
        } else if let resolved = backupDirectoryURL() {
            dir = resolved
        } else {
            return nil
        }
        let todayURL = dir.appendingPathComponent(filename(for: now))
        if FileManager.default.fileExists(atPath: todayURL.path) {
            return nil
        }
        let payload = try ExportService.buildPayload(context: context)
        let data = try ExportService.encode(payload)
        try data.write(to: todayURL, options: .atomic)
        pruneOldBackups(in: dir, retainCount: retainCount)
        log.info("Wrote backup: \(todayURL.lastPathComponent)")
        return todayURL
    }

    /// All `backup-YYYY-MM-DD.json` files in the given directory (or
    /// the ubiquity container if nil), sorted newest first.
    func listBackups(in directory: URL? = nil) -> [URL] {
        let dir: URL
        if let directory {
            dir = directory
        } else if let resolved = backupDirectoryURL() {
            dir = resolved
        } else {
            return []
        }
        let files = (try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil
        )) ?? []
        return files
            .filter { $0.lastPathComponent.hasPrefix("backup-") && $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    /// Wipes existing data then re-imports from a dated backup file.
    /// Same semantics as Settings → Import JSON.
    func restore(from url: URL, into context: ModelContext) throws {
        let data = try Data(contentsOf: url)
        let payload = try ExportService.decode(data)
        try ExportService.importPayload(payload, into: context)
    }

    // MARK: - Internals

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone(identifier: "UTC")
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()

    private func filename(for date: Date) -> String {
        "backup-\(Self.dateFormatter.string(from: date)).json"
    }

    private func pruneOldBackups(in dir: URL, retainCount: Int) {
        let files = listBackups(in: dir)
        guard files.count > retainCount else { return }
        for stale in files.dropFirst(retainCount) {
            try? FileManager.default.removeItem(at: stale)
            log.info("Pruned backup: \(stale.lastPathComponent)")
        }
    }
}
