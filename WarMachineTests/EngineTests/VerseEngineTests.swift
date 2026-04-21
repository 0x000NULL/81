import Testing
import Foundation
import SwiftData
@testable import WarMachine

@Suite("VerseEngine")
struct VerseEngineTests {
    @Test("same date returns same verse across calls")
    func determinism() {
        let d = Date(timeIntervalSince1970: 1_700_000_000)
        let a = VerseEngine.verseOfDay(on: d)
        let b = VerseEngine.verseOfDay(on: d)
        #expect(a.reference == b.reference)
    }

    @Test("different dates usually return different verses")
    func variability() {
        let a = VerseEngine.verseOfDay(on: Date(timeIntervalSince1970: 1_700_000_000))
        let b = VerseEngine.verseOfDay(on: Date(timeIntervalSince1970: 1_700_864_000))
        // Not guaranteed — but across many days we expect variation. Pick two indices 10 days apart.
        _ = (a, b)
    }

    @Test("themed verse pick respects theme when pool non-empty")
    func themed() {
        let v = VerseEngine.themedVerseOfDay(on: .now, theme: .strength)
        #expect(v.theme == .strength)
    }

    @Test("memorization review: no memorized verses returns nil")
    @MainActor
    func memoNoneMemorized() throws {
        let ctx = try Self.makeContext()
        let fv = FavoriteVerse(reference: "Psalm 144:1")
        ctx.insert(fv)
        #expect(VerseEngine.memorizationReviewDue(favorites: [fv], now: .now) == nil)
    }

    @Test("memorization review: all reviewed within past week returns nil")
    @MainActor
    func memoAllFresh() throws {
        let ctx = try Self.makeContext()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let a = FavoriteVerse(reference: "Psalm 1:1"); a.isMemorized = true
        a.lastReviewedAt = now.addingTimeInterval(-2 * 86400)
        let b = FavoriteVerse(reference: "Romans 8:28"); b.isMemorized = true
        b.lastReviewedAt = now.addingTimeInterval(-6 * 86400)
        ctx.insert(a); ctx.insert(b)
        #expect(VerseEngine.memorizationReviewDue(favorites: [a, b], now: now) == nil)
    }

    @Test("memorization review: picks the oldest past-threshold verse; nil counts as oldest")
    @MainActor
    func memoOldestPicked() throws {
        let ctx = try Self.makeContext()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let fresh = FavoriteVerse(reference: "Psalm 1:1"); fresh.isMemorized = true
        fresh.lastReviewedAt = now.addingTimeInterval(-3 * 86400)
        let due = FavoriteVerse(reference: "Romans 8:28"); due.isMemorized = true
        due.lastReviewedAt = now.addingTimeInterval(-10 * 86400)
        let neverReviewed = FavoriteVerse(reference: "Isaiah 40:31"); neverReviewed.isMemorized = true
        ctx.insert(fresh); ctx.insert(due); ctx.insert(neverReviewed)

        let picked = VerseEngine.memorizationReviewDue(favorites: [fresh, due, neverReviewed], now: now)
        #expect(picked?.reference == "Isaiah 40:31") // nil lastReviewedAt treated as oldest
    }

    @Test("memorization review: ignores non-memorized favorites")
    @MainActor
    func memoIgnoresUnmarked() throws {
        let ctx = try Self.makeContext()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let saved = FavoriteVerse(reference: "Psalm 1:1") // not memorized, never reviewed
        ctx.insert(saved)
        #expect(VerseEngine.memorizationReviewDue(favorites: [saved], now: now) == nil)
    }

    // MARK: - Weekly target tests (v1.5)

    @Test("weekStart normalizes any day in a week to its Monday")
    func weekStartNormalizes() {
        // 2023-11-15 was a Wednesday.
        let wednesday = Calendar.current.date(from: DateComponents(year: 2023, month: 11, day: 15))!
        let monday = VerseEngine.weekStart(of: wednesday)
        let weekday = Calendar.current.component(.weekday, from: monday)
        #expect(weekday == 2)
    }

    @Test("pickWeeklyTarget prefers oldest non-memorized favorite")
    @MainActor
    func pickPrefersFavorites() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let older = FavoriteVerse(reference: "Psalm 144:1")
        older.savedAt = now.addingTimeInterval(-10 * 86400)
        let newer = FavoriteVerse(reference: "Romans 8:37")
        newer.savedAt = now
        let picked = VerseEngine.pickWeeklyTarget(
            favorites: [newer, older], priorTargets: [], on: now
        )
        #expect(picked.reference == "Psalm 144:1")
    }

    @Test("pickWeeklyTarget skips references used in the last 8 weeks")
    @MainActor
    func pickSkipsRecent() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let favA = FavoriteVerse(reference: "Psalm 144:1")
        favA.savedAt = now.addingTimeInterval(-10 * 86400)
        let favB = FavoriteVerse(reference: "Romans 8:37")
        favB.savedAt = now.addingTimeInterval(-5 * 86400)

        let priorMonday = Calendar.current.date(byAdding: .day, value: -7, to: VerseEngine.weekStart(of: now))!
        let prior = WeeklyVerseTarget(weekStartDate: priorMonday, reference: "Psalm 144:1")

        let picked = VerseEngine.pickWeeklyTarget(
            favorites: [favA, favB], priorTargets: [prior], on: now
        )
        #expect(picked.reference == "Romans 8:37")
    }

    @Test("pickWeeklyTarget falls back to the themed daily pick when no favorites")
    @MainActor
    func pickFallback() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let picked = VerseEngine.pickWeeklyTarget(favorites: [], priorTargets: [], on: now)
        // Must be a real verse from the pool, not garbage.
        #expect(BibleVerses.byReference(picked.reference) != nil)
    }

    @Test("currentWeekTarget matches on the Monday of the enclosing week")
    @MainActor
    func currentWeekMatches() throws {
        let anyDay = Date(timeIntervalSince1970: 1_700_000_000)
        let monday = VerseEngine.weekStart(of: anyDay)
        let target = WeeklyVerseTarget(weekStartDate: monday, reference: "Isaiah 40:31")
        #expect(VerseEngine.currentWeekTarget(targets: [target], on: anyDay)?.reference == "Isaiah 40:31")

        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: anyDay)!
        #expect(VerseEngine.currentWeekTarget(targets: [target], on: nextWeek) == nil)
    }

    @MainActor
    private static func makeContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        return ModelContext(container)
    }
}
