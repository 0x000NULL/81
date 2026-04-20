import Testing
import Foundation
import SwiftData
@testable import WarMachine

@Suite("LastSessionHintProvider")
struct LastSessionHintProviderTests {

    private func inMemoryContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func makeCompletedSession(ctx: ModelContext,
                                      exerciseKey: String,
                                      setPairs: [(weight: Double, reps: Int)],
                                      completedAt: Date) -> WorkoutSession {
        let session = WorkoutSession(dayType: .legs)
        session.completedAt = completedAt
        ctx.insert(session)
        let ex = ExerciseLog(
            orderIndex: 1, exerciseKey: exerciseKey, displayName: exerciseKey,
            targetSets: setPairs.count,
            targetRepsMin: setPairs.first?.reps ?? 5,
            targetRepsMax: setPairs.first?.reps ?? 5,
            targetWeight: setPairs.first?.weight ?? 0,
            restSeconds: 120
        )
        ex.session = session
        ctx.insert(ex)
        for (i, pair) in setPairs.enumerated() {
            let set = SetLog(setIndex: i, weightLb: pair.weight, reps: pair.reps)
            set.exercise = ex
            ctx.insert(set)
        }
        try? ctx.save()
        return session
    }

    @Test("no prior sessions returns nil")
    func noPrior() throws {
        let ctx = try inMemoryContext()
        let sessions = try ctx.fetch(FetchDescriptor<WorkoutSession>())
        let hint = LastSessionHintProvider.perSetHint(
            in: sessions,
            excluding: UUID(),
            exerciseKey: "back-squat",
            setIndex: 0,
            kind: .weightReps
        )
        #expect(hint == nil)
    }

    @Test("finds matching set in last completed session")
    func basic() throws {
        let ctx = try inMemoryContext()
        _ = makeCompletedSession(
            ctx: ctx,
            exerciseKey: "back-squat",
            setPairs: [(185, 5), (185, 5), (185, 4), (185, 4)],
            completedAt: .now
        )
        let sessions = try ctx.fetch(FetchDescriptor<WorkoutSession>())
        let hint = LastSessionHintProvider.perSetHint(
            in: sessions,
            excluding: UUID(),
            exerciseKey: "back-squat",
            setIndex: 2,
            kind: .weightReps
        )
        #expect(hint?.weightLb == 185)
        #expect(hint?.reps == 4)
    }

    @Test("most recent completed session wins")
    func mostRecentWins() throws {
        let ctx = try inMemoryContext()
        let older = Date.now.addingTimeInterval(-7 * 86_400)
        _ = makeCompletedSession(
            ctx: ctx, exerciseKey: "bench-press",
            setPairs: [(135, 8), (135, 8)], completedAt: older
        )
        _ = makeCompletedSession(
            ctx: ctx, exerciseKey: "bench-press",
            setPairs: [(145, 6), (145, 6)], completedAt: .now
        )
        let sessions = try ctx.fetch(FetchDescriptor<WorkoutSession>())
        let hint = LastSessionHintProvider.perSetHint(
            in: sessions,
            excluding: UUID(),
            exerciseKey: "bench-press",
            setIndex: 0,
            kind: .weightReps
        )
        #expect(hint?.weightLb == 145)
        #expect(hint?.reps == 6)
    }

    @Test("excluded session is never returned")
    func excludesSelf() throws {
        let ctx = try inMemoryContext()
        let s = makeCompletedSession(
            ctx: ctx, exerciseKey: "deadlift",
            setPairs: [(315, 3)], completedAt: .now
        )
        let sessions = try ctx.fetch(FetchDescriptor<WorkoutSession>())
        let hint = LastSessionHintProvider.perSetHint(
            in: sessions,
            excluding: s.id,
            exerciseKey: "deadlift",
            setIndex: 0,
            kind: .weightReps
        )
        #expect(hint == nil)
    }

    @Test("set index out of range returns nil")
    func outOfRange() throws {
        let ctx = try inMemoryContext()
        _ = makeCompletedSession(
            ctx: ctx, exerciseKey: "back-squat",
            setPairs: [(185, 5), (185, 5)], completedAt: .now
        )
        let sessions = try ctx.fetch(FetchDescriptor<WorkoutSession>())
        let hint = LastSessionHintProvider.perSetHint(
            in: sessions,
            excluding: UUID(),
            exerciseKey: "back-squat",
            setIndex: 5,
            kind: .weightReps
        )
        #expect(hint == nil)
    }
}
