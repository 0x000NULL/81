import Testing
import Foundation
import SwiftData
@testable import WarMachine

@Suite("ExportService")
@MainActor
struct ExportServiceTests {

    @Test("round-trip with favorites and journal entries")
    func roundTrip() async throws {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let ctx = ModelContext(container)

        let profile = UserProfile()
        profile.bodyweightLb = 200
        profile.identitySentence = "I am a son of God."
        ctx.insert(profile)

        let fav = FavoriteVerse(reference: "Psalm 144:1", note: "anchor")
        ctx.insert(fav)

        let entry = PrayerJournalEntry(text: "thankful", tag: "gratitude")
        ctx.insert(entry)

        try ctx.save()

        let payload = try ExportService.buildPayload(context: ctx)
        #expect(payload.schemaVersion == "1.2-christian-journal")
        #expect(payload.profile?.bodyweightLb == 200)
        #expect(payload.favorites.count == 1)
        #expect(payload.journal.count == 1)

        let data = try ExportService.encode(payload)
        let decoded = try ExportService.decode(data)
        #expect(decoded.profile?.identitySentence == "I am a son of God.")
        #expect(decoded.favorites.first?.reference == "Psalm 144:1")
        #expect(decoded.journal.first?.text == "thankful")
    }
}
