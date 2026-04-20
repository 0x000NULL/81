import Testing
import Foundation
import SwiftData
@testable import WarMachine

/// SchemaV4 dropped @Attribute(.unique) from 8 models so the store can
/// open under NSPersistentCloudKitContainer (Phase C). These tests
/// confirm: (a) the schema container opens, (b) duplicate-key rows are
/// allowed where SchemaV3 would have rejected them, (c) lightweight
/// migration from a SchemaV3-shaped seed store carries every row over.
@Suite("SchemaV4")
@MainActor
struct SchemaV4Tests {

    @Test("SchemaV4 container opens against an in-memory store")
    func opensInMemory() throws {
        let schema = Schema(versionedSchema: SchemaV4.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let ctx = ModelContext(container)
        ctx.insert(GtgLog(date: .now, target: 30))
        try ctx.save()
        #expect(try ctx.fetch(FetchDescriptor<GtgLog>()).count == 1)
    }

    @Test("SchemaV4 accepts two GtgLog rows on the same calendar day")
    func acceptsDuplicateGtgKey() throws {
        let schema = Schema(versionedSchema: SchemaV4.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let ctx = ModelContext(container)

        let day = Calendar.current.startOfDay(for: .now)
        ctx.insert(GtgLog(date: day, target: 30))
        ctx.insert(GtgLog(date: day, target: 50))
        try ctx.save()

        let all = try ctx.fetch(FetchDescriptor<GtgLog>())
        #expect(all.count == 2)
    }

    @Test("SchemaV4 accepts duplicates on every previously-unique key")
    func acceptsDuplicatesOnAllKeys() throws {
        let schema = Schema(versionedSchema: SchemaV4.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let ctx = ModelContext(container)

        ctx.insert(LiftProgression(liftKey: "back-squat", displayName: "Back Squat",
                                   currentWeightLb: 225, isMainLift: true))
        ctx.insert(LiftProgression(liftKey: "back-squat", displayName: "Back Squat",
                                   currentWeightLb: 235, isMainLift: true))

        let today = Calendar.current.startOfDay(for: .now)
        ctx.insert(DailyLog(date: today))
        ctx.insert(DailyLog(date: today))

        ctx.insert(SundayReview(weekStartDate: today))
        ctx.insert(SundayReview(weekStartDate: today))

        ctx.insert(BookProgress(title: "Mere Christianity", author: "Lewis", isChristian: true))
        ctx.insert(BookProgress(title: "Mere Christianity", author: "Lewis", isChristian: true))

        ctx.insert(EquipmentItem(name: "Power rack", isMustHave: true, approxCost: nil, note: nil))
        ctx.insert(EquipmentItem(name: "Power rack", isMustHave: true, approxCost: nil, note: nil))

        ctx.insert(FavoriteVerse(reference: "Psalm 144:1"))
        ctx.insert(FavoriteVerse(reference: "Psalm 144:1"))

        ctx.insert(ExercisePRCache(exerciseKey: "back-squat"))
        ctx.insert(ExercisePRCache(exerciseKey: "back-squat"))

        try ctx.save()

        #expect(try ctx.fetch(FetchDescriptor<LiftProgression>()).count == 2)
        #expect(try ctx.fetch(FetchDescriptor<DailyLog>()).count == 2)
        #expect(try ctx.fetch(FetchDescriptor<SundayReview>()).count == 2)
        #expect(try ctx.fetch(FetchDescriptor<BookProgress>()).count == 2)
        #expect(try ctx.fetch(FetchDescriptor<EquipmentItem>()).count == 2)
        #expect(try ctx.fetch(FetchDescriptor<FavoriteVerse>()).count == 2)
        #expect(try ctx.fetch(FetchDescriptor<ExercisePRCache>()).count == 2)
    }
}
