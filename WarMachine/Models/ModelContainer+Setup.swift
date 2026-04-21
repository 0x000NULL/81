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

// v1.3 — Drop @Attribute(.unique) on every model that had one
// (LiftProgression.liftKey, DailyLog.date, GtgLog.date,
//  SundayReview.weekStartDate, BookProgress.title, EquipmentItem.name,
//  FavoriteVerse.reference, ExercisePRCache.exerciseKey).
//
// Why: NSPersistentCloudKitContainer rejects unique constraints — they
// have no equivalent in CloudKit's record model, so the store fails to
// open with sync enabled. Uniqueness now lives in the Stores/ helpers
// (findOrCreate + merge-on-collision), which are safe under sync.
//
// v1.5 delta (additive, lightweight-inferrable):
//   + WeeklyVerseTarget model (Monday-keyed memorization target history)
//   + UserProfile.identitySentences: [String]
//   + UserProfile.lastIdentityReviewedAt: Date?
enum SchemaV4: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 3, 0)

    static var models: [any PersistentModel.Type] {
        SchemaV3.models + [WeeklyVerseTarget.self]
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

    /// CloudKit container ID. Must match the entitlements file and be
    /// provisioned in developer.apple.com (Xcode auto-creates on first
    /// signed build) and have schema deployed in CloudKit Dashboard
    /// before TestFlight/App Store submission.
    static let cloudKitContainerID = "iCloud.com.ethanaldrich.81.app"

    /// UserDefaults key for the user-visible iCloud sync toggle.
    /// Defaults to ON; users opt out via Settings → iCloud Sync.
    static let cloudSyncEnabledKey = "cloudkit.sync.enabled"

    let container: ModelContainer
    /// Non-nil when the real store failed to open — caller should surface
    /// this to the user instead of presenting the normal UI, because the
    /// container is a read-only in-memory fallback with no user data.
    let launchError: String?

    private init() {
        let schema = Schema(versionedSchema: SchemaV4.self)
        let cloudSyncEnabled = (UserDefaults.standard.object(forKey: Self.cloudSyncEnabledKey) as? Bool) ?? true
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = cloudSyncEnabled
            ? .private(Self.cloudKitContainerID)
            : .none
        let config: ModelConfiguration
        if let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroup.suiteName) {
            let storeURL = groupURL.appendingPathComponent("81.store")
            config = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: cloudKitDatabase)
        } else {
            log.warning("App Group container unavailable; using default store")
            config = ModelConfiguration(schema: schema, cloudKitDatabase: cloudKitDatabase)
        }
        do {
            // Deliberately no migrationPlan: SchemaV1/V2/V3/V4 all
            // reference the current live @Model classes, so they hash
            // identically at runtime and NSStagedMigrationManager can't
            // find a matching "from" schema for the on-disk store.
            // Letting SwiftData do its default lightweight inference
            // against SchemaV4 is the right behavior until we freeze
            // per-version model snapshots. Lightweight inference handles
            // the SchemaV3 → V4 delta (drop @Attribute(.unique)) by
            // simply dropping the unique index on the underlying store.
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
