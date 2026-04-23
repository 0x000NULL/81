# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project identity

User-facing name is **"81"**; internal target, scheme, and Swift module all stay **`WarMachine`**. Never rename the module — `@testable import WarMachine` and `PRODUCT_MODULE_NAME=WarMachine` depend on it (Swift rejects `81` as a module name because it starts with a digit). Bundle IDs are `com.ethanaldrich.81.*` (the original `com.warmachine.*` was unavailable on Apple's portal). Deep-link scheme is `warmachine://`.

## Project generation

`WarMachine.xcodeproj` is **generated from `project.yml` by XcodeGen** — do not edit `.xcodeproj` files by hand. After changing `project.yml`, file membership, Info.plist keys, entitlements, or adding/removing source files, regenerate:

```sh
xcodegen generate
```

`DEVELOPMENT_TEAM` in `project.yml` is intentionally blank and must be filled in locally before first build.

## Build / test commands

```sh
# Build for simulator
xcodebuild -scheme WarMachine -destination 'platform=iOS Simulator,name=iPhone 17' build

# Full test run (unit + UI)
xcodebuild -scheme WarMachine -destination 'platform=iOS Simulator,name=iPhone 17' test

# Single test (Swift Testing uses xctest-style identifiers: Target/Suite/test)
xcodebuild -scheme WarMachine -destination 'platform=iOS Simulator,name=iPhone 17' \
  test -only-testing:WarMachineTests/ProgressionEngineTests/mainLiftAddsFivePounds
```

In Xcode: ⌘R to run, ⌘U to test. Dark-mode only (forced app-wide via `.preferredColorScheme(.dark)` and `UIUserInterfaceStyle=Dark`) — don't add light-mode variants.

## Architecture

Single-user iOS-only app (iPhone, iOS 17.4+). **Zero third-party runtime dependencies** — everything uses Apple frameworks. Imperial units everywhere internally and in display; HealthKit conversion happens at the service boundary via `HKUnit.pound()` / `HKUnit.mile()`.

### Targets (see `project.yml`)

- **WarMachine** — main iOS app. Sources: `WarMachine/` + `Shared/`.
- **GtgWidget** — WidgetKit extension for home-screen pull-up counter. Sources: `GtgWidget/` + `Shared/`. Deep-links back into the app via `warmachine://gtg`.
- **WarMachineTests** — Swift Testing (`@Test`), not XCTest. Organized under `EngineTests/`, `ProtocolTests/`, `ServiceTests/`.
- **WarMachineUITests** — XCUITest.

Both app and widget belong to App Group `group.BA256NPZGA.warmachine`.

### Data flow: App Group is load-bearing

- **SwiftData store** lives in the App Group container at `group.BA256NPZGA.warmachine/81.store` (see `Models/ModelContainer+Setup.swift`). Falls back to default store only if the App Group container is unavailable. Do not change the store path without a migration plan — it's the user's entire workout/journal/prayer history.
- **Widget snapshot** lives in App Group `UserDefaults` under key `gtg.snapshot.v1` (`Shared/AppGroup.swift`, `Shared/SharedModels.swift`). The widget reads the snapshot; the app writes it after every GTG log. The widget does **not** touch SwiftData.
- The `Shared/` folder contains only the code that must be accessible from both targets. Keep it minimal.

### Schema

`SchemaV4: VersionedSchema` (`Models/ModelContainer+Setup.swift`, version `1.3.0`) is the current schema and the single source of truth for model registration. **Any new `@Model` type must be added to `SchemaV4.models`** — otherwise queries silently return empty and writes crash at runtime.

V4's core delta vs V3 is dropping `@Attribute(.unique)` from 8 models so the store can open under `NSPersistentCloudKitContainer` (CloudKit has no unique-constraint primitive). Uniqueness now lives in `Models/Stores/` — eight `findOrCreate` helpers (`GtgLogStore`, `DailyLogStore`, `SundayReviewStore`, `BookProgressStore`, `EquipmentStore`, `FavoritesStore`, `LiftProgressionStore`, `PRCacheStore`) that return the canonical row and merge any sync-collision duplicates inline (sum reps, MAX progress fields, OR booleans, prefer non-empty text, per-key MAX in JSON dicts). Every find-or-create write site routes through them — adding a new uniqueness key means adding a Store, not a `@Attribute(.unique)`.

**Extend SchemaV4 additively.** v1.5 added `WeeklyVerseTarget` to `SchemaV4.models` and gave `UserProfile` new fields (`identitySentences: [String]`, `lastIdentityReviewedAt: Date?`) without bumping the schema version — SwiftData lightweight inference handles additive changes cleanly, same as v1.0→v1.3. Keep this pattern until a non-additive change forces a real staged migration.

**`AppModelContainer` does NOT pass a `migrationPlan:` — this is deliberate.** `SchemaV1`/`V2`/`V3`/`V4` and `WarMachineMigrationPlan` still exist in the file, but they all reference the same live `@Model` classes, so each version hashes to the *current* model graph at runtime rather than a frozen snapshot. `NSStagedMigrationManager` rejects that (`loadIssueModelContainer`), which is what caused the crash-on-launch after the Phase 0 PR merge. Letting SwiftData do default lightweight inference against `SchemaV4` works and is how v1.0→v1.1→v1.3 shipped (the V3→V4 delta is a constraint relaxation, which lightweight inference handles cleanly). Don't re-enable the plan unless you're ready to freeze per-version model snapshots (separate namespaces, distinct `@Model` classes per version).

`AppModelContainer` surfaces any container-open failure via `launchError: String?` and an in-memory fallback; `WarMachineApp` then shows a copyable `LaunchErrorView` instead of crashing. Keep that path intact — it's cheap insurance for the next migration footgun. The same path catches CloudKit attach failures (signed-out iCloud, missing container provisioning).

### iCloud sync — two layers

- **Live sync via `NSPersistentCloudKitContainer`.** `ModelConfiguration` is constructed with `cloudKitDatabase: .private(AppModelContainer.cloudKitContainerID)` when the user has not opted out via the `cloudkit.sync.enabled` UserDefaults key (default ON). Container ID is `iCloud.com.ethanaldrich.81.app` and must be provisioned on developer.apple.com plus deployed to Production via CloudKit Dashboard before any TestFlight build. `CloudKitStatusService` (`@Observable @MainActor` singleton) wraps `CKContainer.accountStatus` and `NSPersistentCloudKitContainer.eventChangedNotification` for the Settings UI. Toggle changes require an app relaunch (the container is configured once at init).
- **Defense-in-depth dated JSON snapshots.** `CloudBackupService.writeDailyBackupIfNeeded(...)` runs from `WarMachineApp.onLaunch`, debounced to one write per calendar day, retains the most recent 7 in `iCloud.com.ethanaldrich.81.app/Documents/backup-YYYY-MM-DD.json`. Reuses `ExportService.buildPayload` end-to-end. Settings → iCloud Sync → Backups… surfaces a restore sheet that delegates to `ExportService.importPayload` (wipes-and-loads).

### AppIntents (Siri Shortcuts)

`Intents/LogGtgSetIntent.swift` + `Intents/WarMachineShortcuts.swift` register the "Log GTG Set" Shortcut with Siri. The intent runs without opening the app (`openAppWhenRun = false`), prompts for `reps`, and delegates to `LogGtgSetIntent.logSet(reps:in:)` which is the testable pure helper. Adding a new AppIntent: drop into `Intents/`, add it to `WarMachineShortcuts.appShortcuts`, regenerate. Phrases use `\(.applicationName)` so they pick up the bundle display name ("81").

### Layered architecture

```
Views ─────────────▶ Engines (pure logic) ──▶ Models (SwiftData)
   │                     │
   └───────▶ Services (HealthKit, Location, Notifications, RestTimer, Export)
```

- **`Engine/`** — pure, synchronous decision logic with no I/O. `TodayEngine`, `ProgressionEngine`, `DeloadEngine`, `ReturnEngine` (six-branch policy for gaps / injury / sickness / travel), `VerseEngine` (deterministic by date, plus weekly-target picking), `IdentityEngine` (deterministic rotation across `UserProfile.identitySentences` + 30-day review-due calculation), `WeeklyStatsEngine` (promise-rate and workouts-per-week series for Sunday-review charts), `PRDetector` + `PRDetectorBridge` (six `PRKind`s; writes through `ExercisePRCache`), `PlateCalculator` (greedy with unlimited repeats — defaults include 2.5 lb), `LastSessionHintProvider`, `LoggerKindBackfill` (runs once at launch to reclassify legacy `ExerciseLog` rows). Tests live here. Keep engines free of SwiftData `ModelContext` — pass in the data they need.
- **`Services/`** — side-effectful boundaries. `HealthKitService` is an actor; `RestTimerService` is a MainActor singleton (note in `FUTURE.md`: tests serialized as a consequence). Sleep aggregation intentionally sums only `.asleepCore + .asleepREM + .asleepDeep` — do not include `.inBed`/`.awake`.
- **`Protocol/`** — static reference data (exercises, schedule, scaling, verses, prayers, starting weights, interval modalities, etc.). Treat as read-only constants. `LoggerClassification.kind(for: exerciseKey)` is the mapping from `exerciseKey` → `LoggerKind` that drives which logger view the Workout tab renders; keep it authoritative.
- **`Views/`** organized by flow: `Onboarding/`, `Main/`, `Workout/`, `Log/`, `Review/`, `Library/`, `Progress/`, `Settings/`, `Components/`.
- **`App/`** — `WarMachineApp.swift` entrypoint, `AppRouter.swift` top-level navigation, `DeepLink.swift` for URL-scheme handling. Routes: `warmachine://gtg` → `DeepLink.gtg` (widget pull-up counter), `warmachine://verse` → `DeepLink.weeklyVerse` (home tab). On launch, `TodayEngine.cleanupStaleSessions` runs to clean abandoned `WorkoutSession` rows.

### Notifications — `NotificationService.Prefs` convention

Per-notification UserDefaults toggles live under `NotificationService.Prefs` (e.g. `weeklyVerseMondayEnabled`, `identityReviewEnabled`). All default ON; `Prefs.bool(_:)` returns `true` when unset so new reminders light up without a migration. Identifiers live alongside in `NotificationService.Identifier`. Adding a reminder: add both keys, wire a `schedule…(enabled:)` method, call it from `rescheduleAll()`, and expose a toggle in Settings → Notifications.

### Rest timer — time-math, not tick-count

`RestTimerService` is elapsed-time based (stores a start `Date`) plus a one-shot `UNNotification`, so it survives app backgrounding. Full app kill drops in-flight timer state but the notification still fires. Don't convert it to a Timer-tick accumulator.

### Export / import

`ExportService` writes schema version `"1.5-identity-weekly-verse"` (see `ExportPayload.currentSchemaVersion`) covering every model, including `ExercisePRCache`, `WarmUpLog`, and `WeeklyVerseTarget`. Decoders seed new fields (e.g. `identitySentences` from the legacy single `identitySentence`) for backward compatibility with older payloads. Import **wipes current data** before loading. When adding a new `@Model`, update export/import round-trip and the corresponding test in `ServiceTests/ExportServiceTests.swift` (and the schema-version test in `ExportSchemaV14Tests.swift` — file name kept from v1.4; currently targets 1.5).

## Conventions worth knowing

- Imperial units only in app code and UI; no kg, km, or metric display.
- Force dark mode — no light-mode assets.
- iPhone only — `TARGETED_DEVICE_FAMILY=1`, no Catalyst, no iPad.
- Privacy manifest reasons are declared: `CA92.1` (UserDefaults/App Group), `C617.1` (FileTimestamp during export), `E174.1` (DiskSpace during export). Adding APIs in those categories? Keep the manifest in sync.
- `@Attribute(.unique)` is used instead of the `#Unique` macro (macro is iOS 18; target is 17.4).
- Avoid type names that shadow SwiftUI (`TimelineView`, `Label`, etc.). A local `TimelineView` tripped compile in files with `@Query` recently — prefer prefixed names (`TrainingTimelineView`).

## Additional context

- `architecture.md` — full design doc (schema details, engine branches, view specs). Consult for deep questions.
- `goal.md`, `idea.txt`, `idea.pdf` — product intent / source material.
- `CHANGELOG.md`, `FUTURE.md` — release history and explicitly in-/out-of-scope ideas.
