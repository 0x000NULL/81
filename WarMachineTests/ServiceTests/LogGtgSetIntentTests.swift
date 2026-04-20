import Testing
import Foundation
import SwiftData
@testable import WarMachine

@Suite("LogGtgSetIntent")
@MainActor
struct LogGtgSetIntentTests {

    private func inMemoryContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("first set of the day creates today's GtgLog with the given reps")
    func createsLogOnFirstCall() throws {
        let ctx = try inMemoryContext()

        let result = try LogGtgSetIntent.logSet(reps: 5, in: ctx)

        #expect(result.totalReps == 5)
        #expect(result.setsCompleted == 1)
        #expect(result.target == 30)

        let logs = try ctx.fetch(FetchDescriptor<GtgLog>())
        #expect(logs.count == 1)
        #expect(logs.first?.totalReps == 5)
        #expect(logs.first?.setsCompleted == 1)
        #expect(Calendar.current.isDateInToday(logs.first?.date ?? .distantPast))
    }

    @Test("second set on the same day accumulates without a duplicate row")
    func secondSetAccumulates() throws {
        let ctx = try inMemoryContext()

        _ = try LogGtgSetIntent.logSet(reps: 5, in: ctx)
        let result = try LogGtgSetIntent.logSet(reps: 8, in: ctx)

        #expect(result.totalReps == 13)
        #expect(result.setsCompleted == 2)

        let logs = try ctx.fetch(FetchDescriptor<GtgLog>())
        #expect(logs.count == 1)
        #expect(logs.first?.totalReps == 13)
        #expect(logs.first?.setsCompleted == 2)
    }

    @Test("preserves a pre-existing target on today's log")
    func preservesExistingTarget() throws {
        let ctx = try inMemoryContext()
        let existing = GtgLog(date: .now, target: 50)
        ctx.insert(existing)
        try ctx.save()

        let result = try LogGtgSetIntent.logSet(reps: 4, in: ctx)

        #expect(result.target == 50)
        #expect(result.totalReps == 4)
        #expect(result.setsCompleted == 1)
    }
}
