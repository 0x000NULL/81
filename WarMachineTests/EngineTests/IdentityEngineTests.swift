import Testing
import Foundation
import SwiftData
@testable import WarMachine

@Suite("IdentityEngine")
@MainActor
struct IdentityEngineTests {

    private func makeProfile(createdAt: Date, sentences: [String] = [], lastReviewed: Date? = nil) throws -> UserProfile {
        let schema = Schema(versionedSchema: SchemaV4.self)
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        let ctx = ModelContext(container)
        let p = UserProfile()
        p.createdAt = createdAt
        p.identitySentences = sentences
        p.lastIdentityReviewedAt = lastReviewed
        ctx.insert(p)
        return p
    }

    @Test("sentenceForToday: empty array falls back to legacy single sentence")
    func fallback() throws {
        let p = try makeProfile(createdAt: .now)
        p.identitySentence = "I am a son of God who does the work."
        let s = IdentityEngine.sentenceForToday(profile: p, on: .now)
        #expect(s == "I am a son of God who does the work.")
    }

    @Test("sentenceForToday: same day returns same sentence")
    func determinism() throws {
        let p = try makeProfile(createdAt: .now, sentences: ["A", "B", "C"])
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        #expect(IdentityEngine.sentenceForToday(profile: p, on: day) ==
                IdentityEngine.sentenceForToday(profile: p, on: day))
    }

    @Test("sentenceForToday: consecutive days index the array sequentially")
    func rotatesAcrossDays() throws {
        let p = try makeProfile(createdAt: .now, sentences: ["A", "B", "C"])
        let d0 = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let d1 = Calendar.current.date(byAdding: .day, value: 1, to: d0)!
        let d2 = Calendar.current.date(byAdding: .day, value: 2, to: d0)!
        let d3 = Calendar.current.date(byAdding: .day, value: 3, to: d0)!
        let seq = [d0, d1, d2, d3].map { IdentityEngine.sentenceForToday(profile: p, on: $0) }
        // Over four consecutive days with a pool of 3, at least two distinct
        // sentences must appear (determinism + increment guarantees rotation).
        #expect(Set(seq).count >= 2)
        // Wrap-around check: day 0 and day 3 must match because 3 % 3 == 0.
        #expect(seq[0] == seq[3])
    }

    @Test("reviewDue: suppressed inside onboarding grace window")
    func reviewSuppressedEarly() throws {
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        let p = try makeProfile(createdAt: created)
        let day15 = created.addingTimeInterval(15 * 86400)
        #expect(IdentityEngine.reviewDue(profile: p, on: day15) == false)
    }

    @Test("reviewDue: triggers at or after 30 days since creation when never reviewed")
    func reviewAfterGrace() throws {
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        let p = try makeProfile(createdAt: created)
        let day30 = created.addingTimeInterval(30 * 86400)
        let day31 = created.addingTimeInterval(31 * 86400)
        #expect(IdentityEngine.reviewDue(profile: p, on: day30) == true)
        #expect(IdentityEngine.reviewDue(profile: p, on: day31) == true)
    }

    @Test("reviewDue: keyed off lastIdentityReviewedAt once it's set")
    func reviewAfterLast() throws {
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        let reviewed = created.addingTimeInterval(60 * 86400)
        let p = try makeProfile(createdAt: created, lastReviewed: reviewed)
        #expect(IdentityEngine.reviewDue(profile: p, on: reviewed.addingTimeInterval(29 * 86400)) == false)
        #expect(IdentityEngine.reviewDue(profile: p, on: reviewed.addingTimeInterval(30 * 86400)) == true)
    }

    @Test("markReviewed stamps lastIdentityReviewedAt")
    func marks() throws {
        let p = try makeProfile(createdAt: .now)
        #expect(p.lastIdentityReviewedAt == nil)
        let stamp = Date(timeIntervalSince1970: 1_700_000_000)
        IdentityEngine.markReviewed(profile: p, on: stamp)
        #expect(p.lastIdentityReviewedAt == stamp)
    }

    @Test("seedIfNeeded copies legacy single sentence into empty array")
    func seeds() throws {
        let p = try makeProfile(createdAt: .now)
        p.identitySentence = "I am ready."
        p.identitySentences = []
        IdentityEngine.seedIfNeeded(profile: p)
        #expect(p.identitySentences == ["I am ready."])
    }

    @Test("seedIfNeeded is a no-op once array is populated")
    func seedIdempotent() throws {
        let p = try makeProfile(createdAt: .now, sentences: ["First", "Second"])
        IdentityEngine.seedIfNeeded(profile: p)
        #expect(p.identitySentences == ["First", "Second"])
    }

    @Test("nextReviewDueAt uses createdAt+grace when never reviewed")
    func nextDueNever() throws {
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        let p = try makeProfile(createdAt: created)
        let due = IdentityEngine.nextReviewDueAt(profile: p, now: created.addingTimeInterval(1))
        #expect(due == created.addingTimeInterval(IdentityEngine.onboardingGrace))
    }

    @Test("nextReviewDueAt uses lastReviewed+interval once set")
    func nextDueAfterReview() throws {
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        let reviewed = created.addingTimeInterval(60 * 86400)
        let p = try makeProfile(createdAt: created, lastReviewed: reviewed)
        let due = IdentityEngine.nextReviewDueAt(profile: p, now: reviewed.addingTimeInterval(1))
        #expect(due == reviewed.addingTimeInterval(IdentityEngine.revisitInterval))
    }
}
