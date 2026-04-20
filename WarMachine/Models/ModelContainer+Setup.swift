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

// v1.1 — additive-only field changes; all new fields are optional or defaulted,
// which SwiftData handles as a lightweight migration.
//   UserProfile:   + birthDate: Date?
//   BookProgress:  + currentPage/totalPages/currentChapter/totalChapters (Int, default 0), + lastReadAt: Date?
//   FavoriteVerse: + isMemorized (Bool, default false), + lastReviewedAt: Date?
enum SchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 1, 0)

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

// v1.2 — Workout section expansion.
//   SetLog:         + durationSec, distanceYards, distanceMiles, loadLb,
//                     rpe, heartRateAvg, cutRestShort, roundIndex,
//                     setTypeRaw, prKinds, isCompleted
//   ExerciseLog:    + loggerKindRaw, pickedVariantKey, workDurationSec
//   WorkoutSession: + pauseIntervals, totalTonnageLb, liveDurationModeRaw,
//                     warmUp relationship
//   UserProfile:    + preferredBarbellLb, availablePlatesLb
//   New models:     + WarmUpLog, ExercisePRCache
enum SchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 2, 0)

    static var models: [any PersistentModel.Type] {
        [
            UserProfile.self,
            WorkoutSession.self,
            ExerciseLog.self,
            SetLog.self,
            WarmUpLog.self,
            ExercisePRCache.self,
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

enum WarMachineMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self),
            .lightweight(fromVersion: SchemaV2.self, toVersion: SchemaV3.self)
        ]
    }
}

@MainActor
final class AppModelContainer {
    static let shared = AppModelContainer()

    let container: ModelContainer

    private init() {
        let schema = Schema(versionedSchema: SchemaV3.self)
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
            container = try ModelContainer(
                for: schema,
                migrationPlan: WarMachineMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            log.error("Fatal: failed to create ModelContainer: \(String(describing: error))")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
