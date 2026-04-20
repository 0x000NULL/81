import Testing
import Foundation
import SwiftData
@testable import WarMachine

/// V2 → V3 migration round-trip using in-memory stores.
@Suite("SchemaV3 migration")
struct SchemaV3MigrationTests {

    @Test("V3 container opens on a fresh store and new models are registered")
    func freshV3Container() throws {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: WarMachineMigrationPlan.self,
            configurations: [config]
        )
        let ctx = ModelContext(container)

        // Confirm new models are persistable.
        let warmUp = WarmUpLog()
        warmUp.completedItemKeys = ["row-5min"]
        ctx.insert(warmUp)
        let cache = ExercisePRCache(exerciseKey: "bench-press")
        cache.bestEstimated1RMLb = 215
        ctx.insert(cache)
        try ctx.save()

        let warmUps = try ctx.fetch(FetchDescriptor<WarmUpLog>())
        #expect(warmUps.count == 1)
        #expect(warmUps.first?.completedItemKeys == ["row-5min"])

        let caches = try ctx.fetch(FetchDescriptor<ExercisePRCache>())
        #expect(caches.count == 1)
        #expect(caches.first?.bestEstimated1RMLb == 215)
    }

    @Test("SetLog V3 fields default cleanly")
    func setLogDefaults() throws {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let ctx = ModelContext(container)

        let set = SetLog(setIndex: 0, weightLb: 185, reps: 5)
        ctx.insert(set)
        try ctx.save()

        #expect(set.setType == .normal)
        #expect(set.prKinds == [])
        #expect(set.isCompleted == true)
        #expect(set.durationSec == nil)
        #expect(set.rpe == nil)
        #expect(set.cutRestShort == false)
    }

    @Test("ExerciseLog defaults to weightReps LoggerKind")
    func exerciseLogDefault() throws {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let ctx = ModelContext(container)

        let ex = ExerciseLog(
            orderIndex: 1,
            exerciseKey: "back-squat",
            displayName: "Back squat",
            targetSets: 4, targetRepsMin: 4, targetRepsMax: 6,
            targetWeight: 225, restSeconds: 180
        )
        ctx.insert(ex)
        try ctx.save()

        #expect(ex.loggerKind == .weightReps)
        #expect(ex.pickedVariantKey == nil)
        #expect(ex.workDurationSec == nil)
    }

    @Test("UserProfile gets default barbell + plate inventory")
    func userProfileDefaults() throws {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let ctx = ModelContext(container)

        let profile = UserProfile()
        ctx.insert(profile)
        try ctx.save()

        #expect(profile.preferredBarbellLb == 45.0)
        #expect(profile.availablePlatesLb == [45, 35, 25, 10, 5, 2.5])
    }

    @Test("WorkoutSession gains pause-interval and tonnage cache fields")
    func sessionV3Fields() throws {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let ctx = ModelContext(container)

        let session = WorkoutSession(dayType: .legs)
        ctx.insert(session)
        try ctx.save()

        #expect(session.pauseIntervals.isEmpty)
        #expect(session.totalTonnageLb == nil)
        #expect(session.liveDurationModeRaw == "active")
        #expect(session.warmUp == nil)
    }

    @Test("LoggerKindBackfill reclassifies legacy rows by exerciseKey")
    func backfillReclassifies() throws {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let ctx = ModelContext(container)

        // Simulate legacy V2 rows that migrated into V3 with default kind.
        let sidePlank = ExerciseLog(
            orderIndex: 3, exerciseKey: "side-plank", displayName: "Side plank",
            targetSets: 3, targetRepsMin: 30, targetRepsMax: 30,
            targetWeight: 0, restSeconds: 30
        )
        let ruck = ExerciseLog(
            orderIndex: 1, exerciseKey: "long-ruck", displayName: "Long ruck",
            targetSets: 1, targetRepsMin: 6, targetRepsMax: 10,
            targetWeight: 0, restSeconds: 0
        )
        let squat = ExerciseLog(
            orderIndex: 1, exerciseKey: "back-squat", displayName: "Back squat",
            targetSets: 4, targetRepsMin: 4, targetRepsMax: 6,
            targetWeight: 225, restSeconds: 180
        )
        ctx.insert(sidePlank)
        ctx.insert(ruck)
        ctx.insert(squat)
        try ctx.save()

        // Both start as the default .weightReps.
        #expect(sidePlank.loggerKind == .weightReps)
        #expect(ruck.loggerKind == .weightReps)
        #expect(squat.loggerKind == .weightReps)

        LoggerKindBackfill.run(context: ctx)

        #expect(sidePlank.loggerKind == .durationHold)
        #expect(ruck.loggerKind == .ruck)
        #expect(squat.loggerKind == .weightReps)  // unchanged — correct
    }
}
