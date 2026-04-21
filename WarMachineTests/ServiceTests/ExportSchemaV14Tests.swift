import Testing
import Foundation
import SwiftData
@testable import WarMachine

@Suite("Export schema 1.5")
struct ExportSchemaV14Tests {

    private func inMemoryContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV4.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("schema version string is 1.5-identity-weekly-verse")
    func version() {
        #expect(ExportPayload.currentSchemaVersion == "1.5-identity-weekly-verse")
    }

    @MainActor
    @Test("set-level fields round-trip (setType, prKinds, isCompleted, duration, distance)")
    func setRoundTrip() async throws {
        let ctx = try inMemoryContext()
        let session = WorkoutSession(dayType: .pull)
        session.completedAt = .now
        ctx.insert(session)
        let ex = ExerciseLog(
            orderIndex: 1, exerciseKey: "farmers-carry", displayName: "Farmer's carry",
            targetSets: 4, targetRepsMin: 1, targetRepsMax: 1,
            targetWeight: 100, restSeconds: 90
        )
        ex.loggerKind = .distanceLoad
        ex.session = session
        ctx.insert(ex)
        let s = SetLog(setIndex: 0, weightLb: 0, reps: 1)
        s.distanceYards = 40
        s.loadLb = 100
        s.setType = .failure
        s.prKinds = [PRKind.furthestCarryAtLoad.rawValue]
        s.isCompleted = true
        s.exercise = ex
        ctx.insert(s)
        try ctx.save()

        let payload = try ExportService.buildPayload(context: ctx)
        let encoded = try ExportService.encode(payload)
        let decoded = try ExportService.decode(encoded)

        #expect(decoded.schemaVersion == "1.5-identity-weekly-verse")
        #expect(decoded.sets.count == 1)
        let first = decoded.sets[0]
        #expect(first.distanceYards == 40)
        #expect(first.loadLb == 100)
        #expect(first.setType == "failure")
        #expect(first.prKinds == ["furthestCarryAtLoad"])
        #expect(first.isCompleted == true)
    }

    @MainActor
    @Test("profile bar + plate preferences round-trip with safe defaults on 1.3 payloads")
    func profileRoundTrip() async throws {
        let ctx = try inMemoryContext()
        let p = UserProfile()
        p.preferredBarbellLb = 35
        p.availablePlatesLb = [45, 25, 10]
        p.liveGPSRuckEnabled = true
        ctx.insert(p)
        try ctx.save()

        let payload = try ExportService.buildPayload(context: ctx)
        let decoded = try ExportService.decode(try ExportService.encode(payload))

        #expect(decoded.profile?.preferredBarbellLb == 35)
        #expect(decoded.profile?.availablePlatesLb == [45, 25, 10])
        #expect(decoded.profile?.liveGPSRuckEnabled == true)
    }

    @MainActor
    @Test("ExercisePRCache round-trips in the payload")
    func prCacheRoundTrip() async throws {
        let ctx = try inMemoryContext()
        let cache = ExercisePRCache(exerciseKey: "bench-press")
        cache.bestEstimated1RMLb = 215.83
        cache.bestSetVolumeLb = 1350
        cache.setRepsAtWeight([185: 5, 205: 3])
        ctx.insert(cache)
        try ctx.save()

        let payload = try ExportService.buildPayload(context: ctx)
        #expect(payload.prCaches?.count == 1)
        #expect(payload.prCaches?.first?.bestEstimated1RMLb == 215.83)

        let decoded = try ExportService.decode(try ExportService.encode(payload))
        #expect(decoded.prCaches?.first?.bestSetVolumeLb == 1350)
    }

    @MainActor
    @Test("legacy 1.3 payload decodes into V3 defaults (no prCaches, no warmUps)")
    func legacyDecode() async throws {
        // Minimal 1.3 payload hand-crafted so we can prove BC.
        let json = """
        {
          "schemaVersion": "1.3-christian-journal",
          "exportedAt": "2025-10-01T00:00:00Z",
          "profile": null,
          "workouts": [],
          "exercises": [],
          "sets": [],
          "lifts": [],
          "daily": [],
          "gtg": [],
          "rucks": [],
          "sundays": [],
          "baselines": [],
          "books": [],
          "equipment": [],
          "prayers": [],
          "meditations": [],
          "favorites": [],
          "journal": []
        }
        """.data(using: .utf8)!
        let decoded = try ExportService.decode(json)
        #expect(decoded.prCaches == nil)
        #expect(decoded.warmUps == nil)
    }
}
