import Testing
import Foundation
import SwiftData
@testable import WarMachine

@Suite("WeeklyVerseTargetStore")
@MainActor
struct WeeklyVerseTargetStoreTests {

    private func inMemoryContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV4.self)
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        return ModelContext(container)
    }

    @Test("findOrCreate inserts a new row when none exists for the week")
    func creates() throws {
        let ctx = try inMemoryContext()
        let monday = VerseEngine.weekStart(of: .now)
        let target = WeeklyVerseTargetStore.findOrCreate(
            weekStartDate: monday, reference: "Psalm 144:1", in: ctx
        )
        try ctx.save()
        #expect(target.reference == "Psalm 144:1")
        #expect(try ctx.fetch(FetchDescriptor<WeeklyVerseTarget>()).count == 1)
    }

    @Test("findOrCreate returns the canonical row and deletes siblings on collision")
    func mergesCollision() throws {
        let ctx = try inMemoryContext()
        let monday = VerseEngine.weekStart(of: .now)
        let early = Date(timeIntervalSince1970: 1_700_000_000)
        let late = Date(timeIntervalSince1970: 1_700_000_500)

        let a = WeeklyVerseTarget(weekStartDate: monday, reference: "Psalm 144:1")
        a.pickedAt = late
        let b = WeeklyVerseTarget(weekStartDate: monday, reference: "")
        b.pickedAt = early
        b.memorizedAt = late
        ctx.insert(a); ctx.insert(b)
        try ctx.save()

        let resolved = WeeklyVerseTargetStore.findOrCreate(
            weekStartDate: monday, reference: "Romans 8:37", in: ctx
        )
        try ctx.save()

        // Earliest pickedAt wins; non-empty reference wins; memorizedAt propagates.
        #expect(resolved.pickedAt == early)
        #expect(resolved.reference == "Psalm 144:1")
        #expect(resolved.memorizedAt == late)
        #expect(try ctx.fetch(FetchDescriptor<WeeklyVerseTarget>()).count == 1)
    }

    @Test("find returns nil when no row exists for the week")
    func findMissing() throws {
        let ctx = try inMemoryContext()
        let monday = VerseEngine.weekStart(of: .now)
        #expect(WeeklyVerseTargetStore.find(weekStartDate: monday, in: ctx) == nil)
    }

    @Test("find returns the existing row without creating a new one")
    func findExisting() throws {
        let ctx = try inMemoryContext()
        let monday = VerseEngine.weekStart(of: .now)
        let t = WeeklyVerseTarget(weekStartDate: monday, reference: "Isaiah 40:31")
        ctx.insert(t)
        try ctx.save()
        let found = WeeklyVerseTargetStore.find(weekStartDate: monday, in: ctx)
        #expect(found?.reference == "Isaiah 40:31")
        #expect(try ctx.fetch(FetchDescriptor<WeeklyVerseTarget>()).count == 1)
    }
}
