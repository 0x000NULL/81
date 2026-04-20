import Testing
import Foundation
import SwiftData
@testable import WarMachine

/// CloudBackupService writes dated JSON snapshots to a directory and
/// retains the most recent 7. Tests use an injected temp directory so
/// they do not require an iCloud account or sandbox container.
@Suite("CloudBackupService")
@MainActor
struct CloudBackupServiceTests {

    private func tempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("backup-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func cleanup(_ dir: URL) {
        try? FileManager.default.removeItem(at: dir)
    }

    private func inMemoryContextWithSeed() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV4.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let ctx = ModelContext(container)
        let p = UserProfile()
        p.bodyweightLb = 195
        p.identitySentence = "I am a son of God."
        ctx.insert(p)
        ctx.insert(GtgLog(date: .now, target: 30))
        try ctx.save()
        return ctx
    }

    @Test("writeDailyBackupIfNeeded writes one file the first time")
    func writesOnce() throws {
        let dir = tempDir(); defer { cleanup(dir) }
        let ctx = try inMemoryContextWithSeed()

        let url = try CloudBackupService.shared.writeDailyBackupIfNeeded(
            context: ctx, directory: dir, now: .now
        )
        #expect(url != nil)
        #expect(CloudBackupService.shared.listBackups(in: dir).count == 1)
    }

    @Test("writeDailyBackupIfNeeded is a no-op when today's file exists")
    func skipsSameDay() throws {
        let dir = tempDir(); defer { cleanup(dir) }
        let ctx = try inMemoryContextWithSeed()
        let now = Date()

        _ = try CloudBackupService.shared.writeDailyBackupIfNeeded(
            context: ctx, directory: dir, now: now
        )
        let second = try CloudBackupService.shared.writeDailyBackupIfNeeded(
            context: ctx, directory: dir, now: now
        )

        #expect(second == nil)
        #expect(CloudBackupService.shared.listBackups(in: dir).count == 1)
    }

    @Test("writeDailyBackupIfNeeded writes a new file on a different day")
    func writesPerDay() throws {
        let dir = tempDir(); defer { cleanup(dir) }
        let ctx = try inMemoryContextWithSeed()

        let day1 = Date(timeIntervalSince1970: 1_700_000_000)
        let day2 = day1.addingTimeInterval(60 * 60 * 24)

        _ = try CloudBackupService.shared.writeDailyBackupIfNeeded(context: ctx, directory: dir, now: day1)
        _ = try CloudBackupService.shared.writeDailyBackupIfNeeded(context: ctx, directory: dir, now: day2)

        let listed = CloudBackupService.shared.listBackups(in: dir)
        #expect(listed.count == 2)
        #expect(listed.first?.lastPathComponent.contains("2023-11-15") == true) // newest first
    }

    @Test("prunes to retainCount when more than that many files exist")
    func prunesOldBackups() throws {
        let dir = tempDir(); defer { cleanup(dir) }
        let ctx = try inMemoryContextWithSeed()
        let base = Date(timeIntervalSince1970: 1_700_000_000)

        for i in 0..<10 {
            let day = base.addingTimeInterval(TimeInterval(i) * 60 * 60 * 24)
            _ = try CloudBackupService.shared.writeDailyBackupIfNeeded(
                context: ctx, directory: dir, now: day, retainCount: 7
            )
        }

        let listed = CloudBackupService.shared.listBackups(in: dir)
        #expect(listed.count == 7)
    }

    @Test("restore round-trips through ExportService")
    func restoreRoundTrip() throws {
        let dir = tempDir(); defer { cleanup(dir) }
        let originalCtx = try inMemoryContextWithSeed()

        guard let backup = try CloudBackupService.shared.writeDailyBackupIfNeeded(
            context: originalCtx, directory: dir
        ) else {
            Issue.record("expected backup file"); return
        }

        let schema = Schema(versionedSchema: SchemaV4.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let restoredCtx = ModelContext(container)

        try CloudBackupService.shared.restore(from: backup, into: restoredCtx)

        let profiles = try restoredCtx.fetch(FetchDescriptor<UserProfile>())
        #expect(profiles.count == 1)
        #expect(profiles.first?.bodyweightLb == 195)

        let gtgs = try restoredCtx.fetch(FetchDescriptor<GtgLog>())
        #expect(gtgs.count == 1)
    }
}
