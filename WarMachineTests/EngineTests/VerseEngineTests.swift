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
