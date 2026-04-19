# 81

A single-user native iOS app that operationalizes the War Machine Protocol — a 22-page static training program from Alan Ritchson's *War Machine* (2026) and Army Ranger conditioning standards — as a living, autoregulated companion for a Christian man.

SwiftUI + SwiftData + HealthKit. iOS 17.4+. iPhone only. Dark mode only. Zero third-party dependencies. 41 NIV verses, 7 prayers, 6 meditations woven into the daily flow.

## What it is

- **Training logger** — legs, intervals + core, push, Zone 2, pull + carries, Saturday grit day. Per-exercise target sets/reps/rest, autoregulated +5/+10 lb progression, deload every 5–6 weeks, rebuild mode after illness.
- **Live workout** — HealthKit-backed HKWorkouts, GPS ruck routes, time-based rest timer that survives backgrounding.
- **Daily grit** — morning prayer, verse of the day, promise, hard thing; evening three questions, examen, prayer, sleep/HR; prayer journal entry.
- **Saturday circuit** — five-tile GritCircuitView. Ruck and circuit save as two linked HKWorkouts.
- **Sunday review** — Sabbath prayer + verse, weekly stats, four prompts including "Where did I see God this week?"
- **Scripture + prayer library** — all 41 NIV verses themed by Strength, Perseverance, Discipline, Warfare, Rest, Identity, Failure & Return, Trust, Work & Purpose; heart-to-favorite, searchable prayer journal, six meditations (Lectio Divina, Breath Prayer, Examen, Scripture Memorization, Silent Waiting, Attribute of God).
- **Return Protocol** — six-branch logic: injury → paused progression; sick → rebuild at 80% for 2–3 sessions; travel/life → resume at current; unexplained 3–7 / 8–21 / 22+ day gaps each handled distinctly.
- **Widget** — home-screen GTG pull-up counter. No verse. Deep-links to in-app log.

## Prerequisites

- macOS 14+ with Xcode 15.4+ (tested on Xcode 26).
- [xcodegen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`
- A paid Apple Developer Team ID for on-device install / TestFlight distribution.

## Setup

```sh
cd 81
# Edit project.yml → settings.base.DEVELOPMENT_TEAM with your Team ID
xcodegen generate
open WarMachine.xcodeproj
```

In Xcode:
- Select the `WarMachine` scheme → iPhone simulator or your device.
- ⌘R to run, ⌘U to test.

From the command line:

```sh
xcodebuild -scheme WarMachine -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -scheme WarMachine -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Direct install to device

1. Plug in an iPhone (iOS 17.4+).
2. Select your device in the scheme dropdown.
3. ⌘R. Xcode signs and installs. Trust the developer profile on device: Settings → General → VPN & Device Management.

## TestFlight distribution

1. Archive: Product → Archive (Release configuration).
2. Distribute App → App Store Connect → Upload.
3. App Store Connect → TestFlight tab → Add to internal testing.

## Where data lives

- SwiftData store is in the App Group container: `group.com.warmachine.app/81.store`.
- Shared by the main app and the GTG widget extension.
- Daily GTG snapshot also cached in App Group UserDefaults for widget reads.

## Export / import

- Settings → **Export JSON** — writes `81-export-YYYY-MM-DD.json` via `UIDocumentPickerViewController`. Schema version `"1.2-christian-journal"`. Includes everything: profile, workouts, sets, lifts, daily logs, rucks, GTG, Sunday reviews, baselines, books, equipment, prayers, meditations, favorite verses, and prayer journal.
- Settings → **Import JSON** — wipes current data and loads from file. Useful for device migration.

## Decisions I made that weren't specified

- **Product name "81"** — user-facing only. Internal target / scheme / directory / Swift module all stay `WarMachine`. Bundle IDs stay `com.warmachine.*`. Rationale: preserve the pre-built `project.yml` structure with minimum churn; bundle IDs are opaque anyway.
- **PRODUCT_MODULE_NAME set to `WarMachine` explicitly** — because Swift rejects `81` as a module name (starts with a digit), Xcode would auto-sanitize to `_81`; explicit override keeps `@testable import WarMachine` working.
- **iOS 17.4 over 17.0** — the source prompt said 17.4+; `project.yml` shipped with 17.0. Bumped to 17.4 for SwiftData stability and Swift Testing availability.
- **Ruck + Grit circuit as two linked HKWorkouts** — one `WorkoutSession` parent row in SwiftData, two HealthKit writes (hiking + HIIT).
- **Sleep aggregation** — sum only `.asleepCore + .asleepREM + .asleepDeep`. `.inBed` and `.awake` excluded.
- **Rest timer** — in-memory `@Observable` + UNNotification one-shot. Backgrounding survives (time math). Full app kill drops in-flight timer state; the notification still fires.
- **`@Attribute(.unique)` on FavoriteVerse.reference** — the prompt mentioned `#Unique` macro but that's iOS 18. We target 17.4, so `@Attribute(.unique)` is the equivalent.
- **`Uncomfortable Truth` milestone** — `UserProfile.lastUTMilestoneShown: Int?`; set to 4/8/12 after the banner is tapped so it doesn't redisplay the same day.
- **Widget deep-link scheme** — `warmachine://gtg` opens the app. URL scheme registered in Info.plist.
- **URL scheme kept as `warmachine`** — matches bundle ID prefix, not the display name. User-facing deep links use this.
- **Privacy manifest reasons** — `CA92.1` (UserDefaults for App Group), `C617.1` (FileTimestamp during export), `E174.1` (DiskSpace during export).
- **App icon** — auto-generated at build time (see `/tmp/make_icon.py` script in repo history); 1024×1024 PNG with the "81" glyph on near-black background. If you need all sub-sizes, add them manually in Xcode's asset catalog.
- **Launch screen** — solid dark color (`LaunchBackground`). No "81" glyph in launch screen (fast cold start); the glyph appears immediately in `RootView`.

## Test coverage

42 Swift Testing cases covering:
- `StartingWeights` — rounding, bodyweight/level scaling, derived accessories, level ordering for main lifts.
- `ReturnEngine` — all six policy branches incl. mixed-reason gaps.
- `TodayEngine` — stale session cleanup, UT milestone gating, incomplete workout detection.
- `ProgressionEngine` — main lift +5/+10, accessory 2-session rule, ruck distance vs weight logic.
- `DeloadEngine` — detection, multiplier precedence.
- `VerseEngine` — deterministic same-date selection.
- `RestTimerService` — state transitions.
- `ExportService` — round-trip with FavoriteVerse + PrayerJournalEntry; schema version.

## License

Personal tool. Not distributed publicly.

> *"I have fought the good fight, I have finished the race, I have kept the faith."* — 2 Timothy 4:7 (NIV)
