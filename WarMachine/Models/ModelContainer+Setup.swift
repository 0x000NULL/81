import Foundation
import SwiftData
import OSLog

private let log = Logger(subsystem: "app.81", category: "swiftdata")

enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            UserProfile.self,
            WorkoutSession.self,
            ExerciseLog.self,
            SetLog.self,
            LiftProgression.self,
            DailyLog.self,
            GtgLog.self,
            RuckLog.self,
            SundayReview.self,
            BaselineTest.self,
            BookProgress.self,
            EquipmentItem.self,
            PrayerLog.self,
            MeditationLog.self,
            FavoriteVerse.self,
            PrayerJournalEntry.self
        ]
    }
}

@MainActor
final class AppModelContainer {
    static let shared = AppModelContainer()

    let container: ModelContainer

    private init() {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config: ModelConfiguration
        if let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroup.suiteName) {
            let storeURL = groupURL.appendingPathComponent("81.store")
            config = ModelConfiguration(schema: schema, url: storeURL)
        } else {
            log.warning("App Group container unavailable; using default store")
            config = ModelConfiguration(schema: schema)
        }
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            log.error("Fatal: failed to create ModelContainer: \(String(describing: error))")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
