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

`SchemaV2: VersionedSchema` (`Models/ModelContainer+Setup.swift`) is the current schema and the single source of truth for model registration. **Any new `@Model` type must be added to `SchemaV2.models`** — otherwise queries silently return empty and writes crash at runtime. Current version identifier is `1.1.0`. `SchemaV1` (v1.0.0) is retained for migration only; `WarMachineMigrationPlan` declares the V1→V2 lightweight stage. Bump to a new `SchemaV3` + add another migration stage if you change existing model shapes again.

### Layered architecture

```
Views ─────────────▶ Engines (pure logic) ──▶ Models (SwiftData)
   │                     │
   └───────▶ Services (HealthKit, Location, Notifications, RestTimer, Export)
```

- **`Engine/`** — pure, synchronous decision logic with no I/O. `TodayEngine`, `ProgressionEngine`, `DeloadEngine`, `ReturnEngine` (six-branch policy for gaps / injury / sickness / travel), `VerseEngine` (deterministic by date). Tests live here. Keep engines free of SwiftData `ModelContext` — pass in the data they need.
- **`Services/`** — side-effectful boundaries. `HealthKitService` is an actor; `RestTimerService` is a MainActor singleton (note in `FUTURE.md`: tests serialized as a consequence). Sleep aggregation intentionally sums only `.asleepCore + .asleepREM + .asleepDeep` — do not include `.inBed`/`.awake`.
- **`Protocol/`** — static reference data (exercises, schedule, scaling, verses, prayers, starting weights, etc.). Treat as read-only constants.
- **`Views/`** organized by flow: `Onboarding/`, `Main/`, `Workout/`, `Log/`, `Review/`, `Library/`, `Progress/`, `Settings/`, `Components/`.
- **`App/`** — `WarMachineApp.swift` entrypoint, `AppRouter.swift` top-level navigation, `DeepLink.swift` for URL-scheme handling. On launch, `TodayEngine.cleanupStaleSessions` runs to clean abandoned `WorkoutSession` rows.

### Rest timer — time-math, not tick-count

`RestTimerService` is elapsed-time based (stores a start `Date`) plus a one-shot `UNNotification`, so it survives app backgrounding. Full app kill drops in-flight timer state but the notification still fires. Don't convert it to a Timer-tick accumulator.

### Export / import

`ExportService` writes schema version `"1.2-christian-journal"` covering every model. Import **wipes current data** before loading. When adding a new `@Model`, update export/import round-trip and the corresponding test in `ServiceTests/ExportServiceTests.swift`.

## Conventions worth knowing

- Imperial units only in app code and UI; no kg, km, or metric display.
- Force dark mode — no light-mode assets.
- iPhone only — `TARGETED_DEVICE_FAMILY=1`, no Catalyst, no iPad.
- Privacy manifest reasons are declared: `CA92.1` (UserDefaults/App Group), `C617.1` (FileTimestamp during export), `E174.1` (DiskSpace during export). Adding APIs in those categories? Keep the manifest in sync.
- `@Attribute(.unique)` is used instead of the `#Unique` macro (macro is iOS 18; target is 17.4).

## Additional context

- `architecture.md` — full design doc (schema details, engine branches, view specs). Consult for deep questions.
- `goal.md`, `idea.txt`, `idea.pdf` — product intent / source material.
- `CHANGELOG.md`, `FUTURE.md` — release history and explicitly in-/out-of-scope ideas.
