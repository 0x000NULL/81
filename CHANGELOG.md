# Changelog

## 1.5 — unreleased

### Added
- **Weekly Scripture memorization target** (`WeeklyVerseTarget` model + `WeeklyVerseTargetStore`). Each Monday, `TodayView` ensures a target exists for the week, auto-picking from the user's oldest non-memorized favorites (skipping any used in the last 8 weeks), falling back to memorized favorites for review, then to the deterministic themed daily pick. New `WeeklyVerseCard` on the home screen above the daily `VerseCard` with Memorized / Swap / Dismiss actions. New Monday 08:00 and Thursday 08:00 recurring notifications (`scheduleWeeklyVerseMonday`, `scheduleWeeklyVerseThursday`), toggleable in Settings → Notifications. Deep link `warmachine://verse` routes to the home tab.
- **Multiple identity sentences with 30-day cadence** (`UserProfile.identitySentences: [String]` + `lastIdentityReviewedAt`). New `IdentityEngine` rotates sentences deterministically by date and computes 30-day review-due state (suppressed during onboarding grace). Seed-at-launch copies the legacy single `identitySentence` into the array on first v1.5 run. New `IdentitySentencesEditorView` accessible from Settings → State → Identity sentences and from a home-screen revisit card when 30 days have elapsed. Identity revisit notification (`scheduleIdentityReview`) is a one-shot that rebooks when the user confirms review.
- **Sunday review all-time charts** (`WeeklyStatsEngine` + `SundayReviewChartsSection`). Two Swift Charts surfaces on the Sunday review screen: promise rate line chart (kept ÷ logged per week, 0–100%) and workouts-per-week bar chart (completed, excluding abandoned). Spans from `UserProfile.startDate` through the current week; scrolls horizontally with a 12-week visible window when history exceeds ~26 weeks.

### Changed
- SchemaV4 extended additively (still version 1.3.0; no `migrationPlan`). Adds `WeeklyVerseTarget` to `SchemaV4.models`; `UserProfile` gains `identitySentences: [String]` and `lastIdentityReviewedAt: Date?`. Handled by SwiftData lightweight inference.
- Export schema bumped to `1.5-identity-weekly-verse`. `ProfileData` gains `identitySentences` and `lastIdentityReviewedAt` (both optional for backward compat); new `WeeklyVerseTargetData` collection. Import path seeds `identitySentences` from the legacy single sentence when decoding a pre-1.5 payload.
- `NotificationService` gains three new identifiers (`weeklyVerseMonday`, `weeklyVerseThursday`, `identityReview`) and a `Prefs` namespace for their UserDefaults toggles (all default ON).

### Tests
- 26 new test cases: `IdentityEngineTests` (11), `WeeklyStatsEngineTests` (5), `WeeklyVerseTargetStoreTests` (4), `VerseEngineTests` extensions for `weekStart` / `pickWeeklyTarget` / `currentWeekTarget` (5), `ExportServiceTests` round-trip updated to cover the v1.5 fields, `ExportSchemaV14Tests` retargeted to 1.5.

## 1.3 — unreleased

### Added
- Siri Shortcut "Log GTG Set" via `LogGtgSetIntent` + `WarMachineShortcuts` (`AppShortcutsProvider`). Prompts for reps, runs without opening the app, accumulates onto today's `GtgLog`, refreshes the home-screen widget timeline.
- Live iCloud sync via `NSPersistentCloudKitContainer` — every `@Model` mirrored to the user's private CloudKit DB (container `iCloud.com.ethanaldrich.81.app`). Settings → iCloud Sync surfaces account status, last-sync timestamp, an opt-out toggle (default ON), and an "Open iCloud settings" shortcut when the user is signed out.
- Defense-in-depth dated backups: `CloudBackupService` writes one `backup-YYYY-MM-DD.json` per day to the app's iCloud Drive ubiquity container, retains the most recent 7. Restore from any dated file via Settings → iCloud Sync → Backups…
- `Models/Stores/` — eight `findOrCreate` helpers (`GtgLogStore`, `DailyLogStore`, `SundayReviewStore`, `BookProgressStore`, `EquipmentStore`, `FavoritesStore`, `LiftProgressionStore`, `PRCacheStore`) that own row uniqueness now that `@Attribute(.unique)` is gone, merging duplicates inline on read (sum reps, MAX progress, OR booleans, prefer non-empty text, per-key MAX in JSON dicts).
- `CloudKitStatusService` — `@Observable @MainActor` singleton wrapping `CKContainer.accountStatus` and `NSPersistentCloudKitContainer.eventChangedNotification` for the Settings UI.
- `WidgetCenter.shared.reloadAllTimelines()` is now called from `GtgLogView.persistSnapshot()` so in-app GTG logs refresh the widget immediately (previously only the scheduled timeline picked up changes).

### Changed
- SchemaV4 (1.3.0). Drops `@Attribute(.unique)` from `LiftProgression.liftKey`, `DailyLog.date`, `GtgLog.date`, `SundayReview.weekStartDate`, `BookProgress.title`, `EquipmentItem.name`, `FavoriteVerse.reference`, `ExercisePRCache.exerciseKey`. CloudKit's record model has no unique-constraint primitive, so any of these would have prevented the store from opening under sync. Lightweight migration handles the V3→V4 delta as a constraint relaxation.
- `ModelConfiguration` is constructed with `cloudKitDatabase: .private(...)` when `cloudkit.sync.enabled` is true (default), `.none` otherwise. Toggle change requires an app relaunch.
- `project.yml` — `UIBackgroundModes` adds `remote-notification` (CloudKit silent-push); entitlements add `com.apple.developer.icloud-services: [CloudKit]`, `com.apple.developer.icloud-container-identifiers: [iCloud.com.ethanaldrich.81.app]`, `com.apple.developer.ubiquity-container-identifiers: [iCloud.com.ethanaldrich.81.app]`.
- 7 find-or-create call sites routed through the new `Stores/` helpers: `GtgLogView`, `DailyLogView`, `SkipTodaySheet`, `SundayReviewView`, `VerseCard`, `BooksView`, `PRDetectorBridge`, `LogGtgSetIntent`. `PRDetectorBridge.detectAndPersist` is now `@MainActor` (cascaded from `PRCacheStore`).

### Tests
- 21 new tests: `LogGtgSetIntentTests` (3), `StoreDedupeTests` (10), `SchemaV4Tests` (3), `CloudBackupServiceTests` (5).

## 1.2 — unreleased

### Added
- Strong-style checkbox set logger: every target set pre-renders as a row with a "Last: 185 × 5" hint pulled from the most recent completed session; tapping the checkbox persists the set and starts the rest timer.
- Per-kind loggers dispatched by `ExerciseLog.loggerKind`: `DurationHoldLogger` (side plank, per-side L/R rows with timer), `DistanceRepsLogger` (carries, sled push — yards + load), `CardioIntervalLogger` (Tuesday intervals with modality picker + per-round work/rest timers), `JumpRopeFinisherLogger` (10 × 30s on / 30s off), `CardioSessionLogger` (Thursday Zone 2 with live HR and zone band), `RuckLogger` (Saturday ruck — manual distance + load; live GPS behind a UserProfile flag).
- Walkthrough pager (`TabView(.page)`) replaces the scrolling exercise list: page 0 warm-up + travel mode, pages 1…N per exercise, finish page with session stats. Progress bar with live elapsed clock (pause-aware), overview sheet with tap-to-jump.
- Set-type tags (warmup / normal / failure / drop) via row ellipsis menu. Warm-ups and drop sets are excluded from progression and tonnage; failure sets count for progression and PR.
- RPE capture: collapsible 1–10 slider on every rep-based set row.
- Plate calculator: tap the weight label on a barbell lift to open a per-side plate breakdown with bar picker (45 / 35 / 55 / 25), inexact-target nearest-below / nearest-above, and a Settings-backed plate inventory.
- Warm-up per-item check-off backed by the new `WarmUpLog` model; all-items-checked auto-marks the routine done.
- Session pause via progress-bar `pause.circle` glyph — paused time is subtracted from the live elapsed clock and persisted on `WorkoutSession.pauseIntervals`.
- PR detection: `PRDetector` evaluates Epley 1RM, single-set volume, reps-at-weight, longest-hold seconds, furthest-carry-at-load, and furthest-ruck-at-load against a persistent `ExercisePRCache`. PR pills render inline on set rows and callouts surface on the summary. Warm-ups and drop sets are ineligible; failure sets are eligible.
- `WorkoutSummaryView` rebuilt around four stat cards: Session (duration, sets, tonnage, cardio miles, hold seconds, avg HR), Today's work (per-exercise target-hit breakdown), New PRs, difficulty / notes / progression.
- Settings → Workout section: bar picker, plate inventory editor, Live GPS ruck beta toggle, Reset PR cache.
- `GritCircuitView` now collects live HR across the circuit and writes `activeEnergyKcal` (MET heuristic) + `avgHR` to HealthKit on finish.

### Changed
- SchemaV3 (1.2.0) with lightweight migration from V2. New fields on `SetLog` (`durationSec`, `distanceYards`, `distanceMiles`, `loadLb`, `rpe`, `heartRateAvg`, `cutRestShort`, `roundIndex`, `setTypeRaw`, `prKinds`, `isCompleted`); on `ExerciseLog` (`loggerKindRaw`, `pickedVariantKey`, `workDurationSec`); on `WorkoutSession` (`pauseIntervals`, `totalTonnageLb`, `liveDurationModeRaw`, `warmUp` relationship); on `UserProfile` (`preferredBarbellLb`, `availablePlatesLb`, `liveGPSRuckEnabled`). New models: `WarmUpLog`, `ExercisePRCache`.
- `LoggerKindBackfill` runs once at app launch after migration to reclassify legacy `ExerciseLog` rows by `exerciseKey`.
- `ProgressionEngine.hitTopOfRange` now filters sets by `SetType.countsTowardProgression` (warm-ups and drops excluded; failure sets count).
- `HealthKitService.saveWorkout` now receives `distanceMi` + `avgHR` from `WorkoutSummaryView` so HKWorkouts for Zone 2 / ruck / interval days carry the right metadata.
- Export schema bumped to `1.4-workout-v2`. `SetData`, `ExerciseData`, `WorkoutData`, `ProfileData` gained the new field surface; new `ExercisePRCacheData` and `WarmUpData` payloads appended. Backwards-compatible with 1.3 payloads.

### Tests
- 33 new tests: `SchemaV3MigrationTests`, `LoggerClassificationTests`, `LastSessionHintProviderTests`, `IntervalModalityTests`, `PlateCalculatorTests`, `PRDetectorTests`, `SetTypeFilterTests`, `ExportSchemaV14Tests`.

## 1.1 — unreleased

### Added
- Recovery signals dashboard on Today: 7-day sparklines for resting HR, HRV, and sleep hours with delta-vs-mean indicators.
- Book reading progress: per-book page/chapter counters, progress bars, and status chips in Books library.
- 12-week timeline view in Progress tab: phase bands (Accumulation Block 1, Deload, Accumulation Block 2, Deload + Final Baseline), "You are here" marker, baseline week indicators.
- Scripture memorization tracker: mark favorites memorized, weekly review prompt on Today view picks the least-recently-reviewed memorized verse.
- Prayer journal enhancements: date-range filter with presets, tag filter, per-month counts in section headers, active-filter chips.
- Full app icon set: explicit per-size PNGs (40/58/60/80/87/120/180) in addition to the 1024 marketing icon.
- Thursday Zone 2 live HR card: live BPM readout with "180 − age" target band (green/amber/red coloring), driven by birthday field on UserProfile (entered in Settings).
- Saturday ruck → Grit Circuit auto-handoff: after logging a ruck on Saturday, the Grit Circuit opens as a full-screen cover. Works from both the quick log (RuckLogView) and the live workout completion path.

### Changed
- SchemaV2 (1.1.0) with lightweight migration from V1. New fields: UserProfile.birthDate, BookProgress.{currentPage,totalPages,currentChapter,totalChapters,lastReadAt}, FavoriteVerse.{isMemorized,lastReviewedAt}.
- Export schema bumped to `1.3-christian-journal`. Backwards-compatible with 1.2 payloads (missing fields default on import).

### Tests
- 17 new tests (ExportService BC, VerseEngine memorization review, TrainingPhases lookups, UserProfile age math). 59 total passing.

## 1.0 — 2026-04-19

Initial release.

### Added
- Onboarding flow: level, HealthKit permission, bodyweight/waist, identity sentence (with Christian chips), baseline test (1-mile, push-ups, pull-ups, 2-mile ruck, resting HR), Uncomfortable Truth acknowledgment.
- Today view: identity line, verse of the day with heart-to-favorite, daily grit summary, resume banner, skip-today sheet, Return Protocol prompts, GTG summary, Health snapshot.
- Workout flow: warm-up card, pre-workout prayer, travel mode, exercise cards with alternatives, time-based rest timer with one-shot notification, long-press set edit/delete, post-workout prayer and progression evaluation.
- Saturday GritCircuitView: five tiles (push-ups, pull-ups, air squats, sit-ups, bear crawl), break-as-needed logging, alternatives per tile.
- Daily log: morning (prayer + verse + promise + hard thing) and evening (three questions + examen + prayer + sleep/energy/HR + prayer journal prompt).
- GTG pull-up logger with daily target and App Group snapshot for widget.
- Ruck quick-log (live session hook wired for future extension).
- Sunday review: Sabbath prayer + verse, weekly stats, four prompts including "Where did I see God this week?".
- Baseline review: weeks 0/4/8/12 comparison table.
- Library: Bible Verses (41 NIV), Favorite Verses, Prayers (7), Meditations (6), Scripts (8), Hard Things (4 categories incl. 12 spiritual), Prayer Journal (grouped, searchable), Nutrition (computed targets), Books (secular + Christian), Equipment (checklist).
- Progress: Swift Charts for main lifts, ruck pace, baseline trajectory.
- Settings: notification times, injury/rebuild clear, export/import, reset, Uncomfortable Truth passage.
- Widget: GTG pull-up counter (small + medium), deep-links to app via `warmachine://gtg`.
- Engines: `TodayEngine`, `ProgressionEngine`, `DeloadEngine`, `ReturnEngine` (six branches), `VerseEngine` (deterministic by date).
- Services: actor-based `HealthKitService` with sleep aggregation (core + REM + deep), `WorkoutSessionService` with live HR stream, `LocationService` with best-for-navigation GPS, `RestTimerService` (elapsed-based), `NotificationService` (single morning, workout, evening, Sabbath, rest, deload), `ExportService` (JSON schema `1.2-christian-journal`).
- SwiftData schema v1 with `VersionedSchema`. Models: UserProfile, WorkoutSession, ExerciseLog, SetLog, LiftProgression, DailyLog, GtgLog, RuckLog, SundayReview, BaselineTest, BookProgress, EquipmentItem, PrayerLog, MeditationLog, FavoriteVerse, PrayerJournalEntry.
- 42 Swift Testing cases covering engines, starting weights, rest timer, export round-trip.
- Privacy manifest with declared reasons.
- Dark mode only. App icon. Launch screen.
