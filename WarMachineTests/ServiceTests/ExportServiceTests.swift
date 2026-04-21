import Testing
import Foundation
import SwiftData
@testable import WarMachine

@Suite("ExportService")
@MainActor
struct ExportServiceTests {

    @Test("round-trip covers schema 1.3 fields (birthDate, book progress, memorization)")
    func roundTrip() async throws {
        let schema = Schema(versionedSchema: SchemaV4.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let ctx = ModelContext(container)

        let dob = Calendar.current.date(from: DateComponents(year: 1990, month: 3, day: 14))!
        let profile = UserProfile()
        profile.bodyweightLb = 200
        profile.identitySentence = "I am a son of God."
        profile.identitySentences = ["I am a son of God.", "I am free in Christ."]
        profile.lastIdentityReviewedAt = Date(timeIntervalSince1970: 1_700_000_500)
        profile.birthDate = dob
        ctx.insert(profile)

        let fav = FavoriteVerse(reference: "Psalm 144:1", note: "anchor")
        fav.isMemorized = true
        fav.lastReviewedAt = Date(timeIntervalSince1970: 1_700_000_000)
        ctx.insert(fav)

        let book = BookProgress(title: "Mere Christianity", author: "C.S. Lewis", isChristian: true)
        book.started = true
        book.currentPage = 42
        book.totalPages = 240
        book.currentChapter = 3
        book.totalChapters = 17
        book.lastReadAt = Date(timeIntervalSince1970: 1_700_000_100)
        ctx.insert(book)

        let entry = PrayerJournalEntry(text: "thankful", tag: "gratitude")
        ctx.insert(entry)

        let monday = VerseEngine.weekStart(of: Date(timeIntervalSince1970: 1_700_000_000))
        let target = WeeklyVerseTarget(weekStartDate: monday, reference: "Isaiah 40:31")
        target.memorizedAt = Date(timeIntervalSince1970: 1_700_000_300)
        ctx.insert(target)

        try ctx.save()

        let payload = try ExportService.buildPayload(context: ctx)
        #expect(payload.schemaVersion == "1.5-identity-weekly-verse")
        #expect(payload.profile?.bodyweightLb == 200)
        #expect(payload.profile?.birthDate == dob)
        #expect(payload.profile?.identitySentences == ["I am a son of God.", "I am free in Christ."])
        #expect(payload.profile?.lastIdentityReviewedAt == Date(timeIntervalSince1970: 1_700_000_500))
        #expect(payload.favorites.count == 1)
        #expect(payload.favorites.first?.isMemorized == true)
        #expect(payload.favorites.first?.lastReviewedAt == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(payload.weeklyVerseTargets?.count == 1)
        #expect(payload.weeklyVerseTargets?.first?.reference == "Isaiah 40:31")
        #expect(payload.weeklyVerseTargets?.first?.memorizedAt == Date(timeIntervalSince1970: 1_700_000_300))
        #expect(payload.books.count == 1)
        #expect(payload.books.first?.currentPage == 42)
        #expect(payload.books.first?.totalPages == 240)
        #expect(payload.books.first?.currentChapter == 3)
        #expect(payload.books.first?.totalChapters == 17)
        #expect(payload.books.first?.lastReadAt == Date(timeIntervalSince1970: 1_700_000_100))
        #expect(payload.journal.count == 1)

        let data = try ExportService.encode(payload)
        let decoded = try ExportService.decode(data)
        #expect(decoded.profile?.identitySentence == "I am a son of God.")
        #expect(decoded.profile?.birthDate == dob)
        #expect(decoded.favorites.first?.reference == "Psalm 144:1")
        #expect(decoded.favorites.first?.isMemorized == true)
        #expect(decoded.books.first?.currentPage == 42)
        #expect(decoded.journal.first?.text == "thankful")
    }

    @Test("decodes a 1.2-schema payload with missing 1.3 fields")
    func backwardsCompatWith12Payload() async throws {
        // Minimal 1.2-era JSON — no birthDate, no book progress detail fields, no memorization fields.
        let json = """
        {
          "schemaVersion": "1.2-christian-journal",
          "exportedAt": "2026-01-01T00:00:00Z",
          "profile": {
            "id": "00000000-0000-0000-0000-000000000001",
            "createdAt": "2026-01-01T00:00:00Z",
            "startDate": "2026-01-01T00:00:00Z",
            "level": "intermediate",
            "bodyweightLb": 180,
            "waistInches": 34,
            "identitySentence": "I am a son of God.",
            "morningReminderHour": 6,
            "morningReminderMinute": 45,
            "eveningReminderHour": 21,
            "eveningReminderMinute": 0,
            "workoutReminderHour": 18,
            "injuryFlag": false,
            "rebuildModeRemainingSessions": 0
          },
          "workouts": [],
          "exercises": [],
          "sets": [],
          "lifts": [],
          "daily": [],
          "gtg": [],
          "rucks": [],
          "sundays": [],
          "baselines": [],
          "books": [
            {
              "title": "Mere Christianity",
              "author": "C.S. Lewis",
              "isChristian": true,
              "started": true,
              "completed": false
            }
          ],
          "equipment": [],
          "prayers": [],
          "meditations": [],
          "favorites": [
            {
              "reference": "Psalm 144:1",
              "savedAt": "2026-01-01T00:00:00Z"
            }
          ],
          "journal": []
        }
        """
        let data = Data(json.utf8)
        let decoded = try ExportService.decode(data)

        #expect(decoded.schemaVersion == "1.2-christian-journal")
        #expect(decoded.profile?.birthDate == nil)
        #expect(decoded.books.first?.currentPage == nil)
        #expect(decoded.books.first?.totalPages == nil)
        #expect(decoded.favorites.first?.isMemorized == nil)
        #expect(decoded.favorites.first?.lastReviewedAt == nil)

        // Import into a fresh context — missing fields should default (0 for Ints, false for isMemorized).
        let schema = Schema(versionedSchema: SchemaV4.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let ctx = ModelContext(container)
        try ExportService.importPayload(decoded, into: ctx)

        let books = try ctx.fetch(FetchDescriptor<BookProgress>())
        #expect(books.count == 1)
        #expect(books.first?.currentPage == 0)
        #expect(books.first?.totalPages == 0)
        #expect(books.first?.lastReadAt == nil)

        let favs = try ctx.fetch(FetchDescriptor<FavoriteVerse>())
        #expect(favs.count == 1)
        #expect(favs.first?.isMemorized == false)
        #expect(favs.first?.lastReviewedAt == nil)

        // v1.5 back-compat: importing a pre-1.5 payload seeds identitySentences
        // from the single identitySentence on the profile.
        let profiles = try ctx.fetch(FetchDescriptor<UserProfile>())
        #expect(profiles.count == 1)
        #expect(profiles.first?.identitySentences == ["I am a son of God."])
        #expect(profiles.first?.lastIdentityReviewedAt == nil)
    }
}
