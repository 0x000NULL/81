import Testing
import Foundation
import SwiftData
@testable import WarMachine

/// Each Store helper takes responsibility for the uniqueness invariant
/// that previously lived in `@Attribute(.unique)`. CloudKit can deliver
/// two rows with the same logical key after a sync collision, so each
/// `findOrCreate` must merge duplicates inline and return one survivor.
@Suite("Store dedupe")
@MainActor
struct StoreDedupeTests {

    private func inMemoryContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV4.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    // MARK: GtgLogStore

    @Test("GtgLogStore sums duplicate rows additively")
    func gtgLogDedupeSums() throws {
        let ctx = try inMemoryContext()
        let day = Calendar.current.startOfDay(for: .now)
        let a = GtgLog(date: day, target: 30); a.totalReps = 5; a.setsCompleted = 1
        let b = GtgLog(date: day, target: 40); b.totalReps = 8; b.setsCompleted = 2
        ctx.insert(a); ctx.insert(b)
        try ctx.save()

        let resolved = GtgLogStore.findOrCreate(date: day, in: ctx)
        try ctx.save()

        #expect(resolved.totalReps == 13)
        #expect(resolved.setsCompleted == 3)
        #expect(resolved.target == 40)

        let all = try ctx.fetch(FetchDescriptor<GtgLog>())
        #expect(all.count == 1)
    }

    @Test("GtgLogStore creates a fresh row when none exists")
    func gtgLogCreates() throws {
        let ctx = try inMemoryContext()
        let resolved = GtgLogStore.findOrCreate(date: .now, in: ctx)
        try ctx.save()
        #expect(resolved.totalReps == 0)
        #expect(resolved.target == 30)
    }

    // MARK: DailyLogStore

    @Test("DailyLogStore merges duplicate days, ORs booleans, prefers non-empty text")
    func dailyLogDedupe() throws {
        let ctx = try inMemoryContext()
        let day = Calendar.current.startOfDay(for: .now)
        let a = DailyLog(date: day)
        a.morningPrayerPrayed = true
        a.promise = "today: ship"
        a.restingHR = 58
        let b = DailyLog(date: day)
        b.eveningPrayerPrayed = true
        b.promise = ""
        b.examenNotes = "felt steady"
        b.sleepHours = 7.5
        ctx.insert(a); ctx.insert(b)
        try ctx.save()

        let resolved = DailyLogStore.findOrCreate(date: day, in: ctx)
        try ctx.save()

        #expect(resolved.morningPrayerPrayed == true)
        #expect(resolved.eveningPrayerPrayed == true)
        #expect(resolved.promise == "today: ship")
        #expect(resolved.examenNotes == "felt steady")
        #expect(resolved.restingHR == 58)
        #expect(resolved.sleepHours == 7.5)

        let all = try ctx.fetch(FetchDescriptor<DailyLog>())
        #expect(all.count == 1)
    }

    // MARK: SundayReviewStore

    @Test("SundayReviewStore merges journal text, OR prayed flag, MAX stat counts")
    func sundayReviewDedupe() throws {
        let ctx = try inMemoryContext()
        let week = Calendar.current.startOfDay(for: .now)
        let a = SundayReview(weekStartDate: week)
        a.win = "PR'd squat"
        a.workoutsCompleted = 3
        a.sabbathPrayerPrayed = true
        let b = SundayReview(weekStartDate: week)
        b.pattern = "skipped Wed"
        b.workoutsCompleted = 4
        b.promisesKept = 6
        ctx.insert(a); ctx.insert(b)
        try ctx.save()

        let resolved = SundayReviewStore.findOrCreate(weekStartDate: week, in: ctx)
        try ctx.save()

        #expect(resolved.win == "PR'd squat")
        #expect(resolved.pattern == "skipped Wed")
        #expect(resolved.workoutsCompleted == 4)
        #expect(resolved.promisesKept == 6)
        #expect(resolved.sabbathPrayerPrayed == true)

        let all = try ctx.fetch(FetchDescriptor<SundayReview>())
        #expect(all.count == 1)
    }

    // MARK: BookProgressStore

    @Test("BookProgressStore takes MAX of paging fields, OR of state flags")
    func bookProgressDedupe() throws {
        let ctx = try inMemoryContext()
        let a = BookProgress(title: "Mere Christianity", author: "C.S. Lewis", isChristian: true)
        a.started = true
        a.currentPage = 42
        a.totalPages = 240
        let b = BookProgress(title: "Mere Christianity", author: "C.S. Lewis", isChristian: true)
        b.completed = true
        b.currentPage = 100
        b.totalPages = 240
        b.lastReadAt = Date(timeIntervalSince1970: 1_700_000_000)
        ctx.insert(a); ctx.insert(b)
        try ctx.save()

        let resolved = BookProgressStore.findOrCreate(
            title: "Mere Christianity",
            author: "C.S. Lewis",
            isChristian: true,
            in: ctx
        )
        try ctx.save()

        #expect(resolved.started == true)
        #expect(resolved.completed == true)
        #expect(resolved.currentPage == 100)
        #expect(resolved.totalPages == 240)
        #expect(resolved.lastReadAt == Date(timeIntervalSince1970: 1_700_000_000))

        let all = try ctx.fetch(FetchDescriptor<BookProgress>())
        #expect(all.count == 1)
    }

    // MARK: EquipmentStore

    @Test("EquipmentStore ORs owned and prefers non-empty notes")
    func equipmentDedupe() throws {
        let ctx = try inMemoryContext()
        let a = EquipmentItem(name: "Power rack", isMustHave: true, approxCost: nil, note: nil)
        a.owned = true
        let b = EquipmentItem(name: "Power rack", isMustHave: true, approxCost: "$300", note: "used craigslist")
        b.owned = false
        ctx.insert(a); ctx.insert(b)
        try ctx.save()

        let resolved = EquipmentStore.findOrCreate(name: "Power rack", in: ctx)
        try ctx.save()

        #expect(resolved.owned == true)
        #expect(resolved.note == "used craigslist")
        #expect(resolved.approxCost == "$300")

        let all = try ctx.fetch(FetchDescriptor<EquipmentItem>())
        #expect(all.count == 1)
    }

    // MARK: FavoritesStore

    @Test("FavoritesStore ORs memorization, takes earliest savedAt, latest review")
    func favoriteVerseDedupe() throws {
        let ctx = try inMemoryContext()
        let early = Date(timeIntervalSince1970: 1_700_000_000)
        let late = Date(timeIntervalSince1970: 1_700_000_500)
        let a = FavoriteVerse(reference: "Psalm 144:1")
        a.savedAt = late
        a.isMemorized = true
        a.lastReviewedAt = early
        let b = FavoriteVerse(reference: "Psalm 144:1")
        b.savedAt = early
        b.isMemorized = false
        b.lastReviewedAt = late
        ctx.insert(a); ctx.insert(b)
        try ctx.save()

        let resolved = FavoritesStore.findOrCreate(reference: "Psalm 144:1", in: ctx)
        try ctx.save()

        #expect(resolved.isMemorized == true)
        #expect(resolved.savedAt == early)
        #expect(resolved.lastReviewedAt == late)

        let all = try ctx.fetch(FetchDescriptor<FavoriteVerse>())
        #expect(all.count == 1)
    }

    @Test("FavoritesStore.find returns nil when no match exists")
    func favoritesFindMissing() throws {
        let ctx = try inMemoryContext()
        #expect(FavoritesStore.find(reference: "Psalm 23:1", in: ctx) == nil)
    }

    // MARK: LiftProgressionStore

    @Test("LiftProgressionStore takes MAX of weight/sessions, latest evaluation")
    func liftProgressionDedupe() throws {
        let ctx = try inMemoryContext()
        let early = Date(timeIntervalSince1970: 1_700_000_000)
        let late = Date(timeIntervalSince1970: 1_700_000_500)
        let a = LiftProgression(liftKey: "back-squat", displayName: "Back Squat",
                                currentWeightLb: 225, isMainLift: true)
        a.consecutiveTopSessions = 1
        a.lastEvaluatedAt = early
        let b = LiftProgression(liftKey: "back-squat", displayName: "Back Squat",
                                currentWeightLb: 235, isMainLift: true)
        b.consecutiveTopSessions = 0
        b.lastEvaluatedAt = late
        ctx.insert(a); ctx.insert(b)
        try ctx.save()

        let resolved = LiftProgressionStore.findOrCreate(
            liftKey: "back-squat", displayName: "Back Squat",
            currentWeightLb: 200, isMainLift: true, in: ctx
        )
        try ctx.save()

        #expect(resolved.currentWeightLb == 235)
        #expect(resolved.consecutiveTopSessions == 1)
        #expect(resolved.lastEvaluatedAt == late)

        let all = try ctx.fetch(FetchDescriptor<LiftProgression>())
        #expect(all.count == 1)
    }

    // MARK: PRCacheStore

    @Test("PRCacheStore takes MAX of every scalar and merges JSON dicts per-key")
    func prCacheDedupe() throws {
        let ctx = try inMemoryContext()
        let a = ExercisePRCache(exerciseKey: "back-squat")
        a.bestEstimated1RMLb = 250
        a.bestSetVolumeLb = 1100
        a.setRepsAtWeight([225: 5, 245: 3])
        let b = ExercisePRCache(exerciseKey: "back-squat")
        b.bestEstimated1RMLb = 275
        b.bestHoldSec = 60
        b.setRepsAtWeight([225: 6, 265: 1])
        ctx.insert(a); ctx.insert(b)
        try ctx.save()

        let resolved = PRCacheStore.findOrCreate(exerciseKey: "back-squat", in: ctx)
        try ctx.save()

        #expect(resolved.bestEstimated1RMLb == 275)
        #expect(resolved.bestSetVolumeLb == 1100)
        #expect(resolved.bestHoldSec == 60)

        let merged = resolved.repsAtWeight()
        #expect(merged[225] == 6)
        #expect(merged[245] == 3)
        #expect(merged[265] == 1)

        let all = try ctx.fetch(FetchDescriptor<ExercisePRCache>())
        #expect(all.count == 1)
    }
}
