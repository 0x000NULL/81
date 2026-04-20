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
    // SchemaV1 is intentionally absent: its model graph is identical to
    // SchemaV2 (V2 only added optional/defaulted fields, which resolve off
    // the current model definitions), so NSStagedMigrationManager rejects
    // a V1→V2 stage as a degenerate no-op when another stage is present.
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV2.self, SchemaV3.self]
    }

    static var stages: [MigrationStage] {
        // Use .custom (not .lightweight) so SwiftData takes the staged-
        // migration path that tolerates adding a new @Relationship on an
        // existing entity (WorkoutSession.warmUp) and a new @Model with
        // @Attribute(.unique) (ExercisePRCache). Closures are nil — the
        // actual schema delta is still inferred automatically.
        [
            .custom(
                fromVersion: SchemaV2.self,
                toVersion: SchemaV3.self,
                willMigrate: nil,
                didMigrate: nil
            )
        ]
    }
}

@MainActor
final class AppModelContainer {
    static let shared = AppModelContainer()

    let container: ModelContainer
    /// Non-nil when the real store failed to open — caller should surface
    /// this to the user instead of presenting the normal UI, because the
    /// container is a read-only in-memory fallback with no user data.
    let launchError: String?

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
            // Deliberately no migrationPlan: SchemaV1/V2/V3 all reference
            // the current live @Model classes, so they hash identically
            // at runtime and NSStagedMigrationManager can't find a
            // matching "from" schema for the on-disk store. Letting
            // SwiftData do its default lightweight inference against
            // SchemaV3 is the right behavior until we freeze per-version
            // model snapshots.
            container = try ModelContainer(
                for: schema,
                configurations: [config]
            )
            launchError = nil
        } catch {
            let detail = String(reflecting: error)
            print("ModelContainer init failed: \(detail)")
            log.error("ModelContainer init failed: \(detail)")
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                container = try ModelContainer(for: schema, configurations: [memoryConfig])
            } catch {
                fatalError("Fallback in-memory ModelContainer also failed: \(error)")
            }
            launchError = detail
        }
    }
}
