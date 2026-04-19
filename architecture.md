# War Machine Protocol iOS App — Architecture

## Stack

| Layer | Choice | Why |
|---|---|---|
| Language | **Swift 5.10+** | Current Apple-blessed language |
| UI | **SwiftUI** (iOS 17.4+ target) | Native, declarative, SwiftData-friendly |
| Persistence | **SwiftData** | Apple's Core Data replacement |
| Health | **HealthKit** | Resting HR, sleep, bodyweight, HRV, workout HR |
| Workouts | **HKWorkoutSession** + **HKWorkoutBuilder** | Foreground session with live HR + GPS |
| Location | **CoreLocation** | GPS routes for rucks |
| Notifications | **UserNotifications** | Local-only |
| Widgets | **WidgetKit** | GTG counter |
| Charts | **Swift Charts** | Built-in |
| Testing | **Swift Testing** (`@Test`) | Modern replacement for XCTest |
| UI Testing | **XCUITest** | Standard |
| Dep mgmt | **Swift Package Manager** | Zero third-party deps |

**No third-party runtime dependencies.** Bible translation: NIV, hardcoded.

**Minimum iOS version: 17.4.** (SwiftData stability, Swift Testing available.) Force dark mode app-wide.

## Privacy

iOS 17+ requires a `PrivacyInfo.xcprivacy` manifest declaring required reason API usage. For this app: declare `NSPrivacyCollectedDataTypes` as empty (no data collection), and declare reason codes for any required reason APIs we use (notably `UserDefaults` — reason `CA92.1`). Include the manifest in the main app target's resources.

## Unit Handling

The app uses **imperial units everywhere internally and in display**:
- Bodyweight, lift weights, ruck weight: **pounds (lbs)**
- Distance: **miles**
- Pace: **min/mile**

HealthKit conversion is handled at the service boundary. Bodyweight is read from HealthKit via `HKUnit.pound()` regardless of device locale — HealthKit performs any necessary conversion internally. Workout distances written to HealthKit use `HKUnit.mile()`. The user never sees kg or km.

## Xcode Project Structure

```
WarMachine.xcodeproj
├── WarMachine/
│   ├── App/
│   │   ├── WarMachineApp.swift
│   │   └── AppRouter.swift
│   │
│   ├── Models/                        # @Model SwiftData
│   │   ├── UserProfile.swift
│   │   ├── WorkoutSession.swift
│   │   ├── ExerciseLog.swift
│   │   ├── SetLog.swift
│   │   ├── LiftProgression.swift
│   │   ├── DailyLog.swift              # now has skippedReason, linkedJournalEntryID
│   │   ├── GtgLog.swift
│   │   ├── RuckLog.swift
│   │   ├── SundayReview.swift
│   │   ├── BaselineTest.swift
│   │   ├── BookProgress.swift
│   │   ├── EquipmentItem.swift
│   │   ├── PrayerLog.swift
│   │   ├── MeditationLog.swift
│   │   ├── FavoriteVerse.swift         # full v1 implementation, not stub
│   │   ├── PrayerJournalEntry.swift    # NEW
│   │   └── ModelContainer+Setup.swift
│   │
│   ├── Protocol/                      # static data
│   │   ├── Exercises.swift
│   │   ├── Schedule.swift
│   │   ├── Scaling.swift
│   │   ├── Scripts.swift
│   │   ├── HardThings.swift           # 4 categories including Spiritual
│   │   ├── Books.swift                # secular + christian arrays
│   │   ├── Equipment.swift
│   │   ├── Nutrition.swift             # NEW - static reference data
│   │   ├── WarmUps.swift               # NEW - per-day warm-up routines
│   │   ├── StartingWeights.swift       # NEW - bodyweight-derived starting weights for all lifts
│   │   ├── BibleVerses.swift
│   │   ├── Prayers.swift
│   │   ├── Meditations.swift
│   │   └── UncomfortableTruth.swift    # NEW - closing passage from PDF
│   │
│   ├── Engine/
│   │   ├── TodayEngine.swift
│   │   ├── ProgressionEngine.swift
│   │   ├── DeloadEngine.swift
│   │   ├── ReturnEngine.swift          # now handles sick-day resumption, injury flag, legitimate skips
│   │   └── VerseEngine.swift
│   │
│   ├── Services/
│   │   ├── HealthKitService.swift
│   │   ├── WorkoutSessionService.swift
│   │   ├── LocationService.swift
│   │   ├── NotificationService.swift
│   │   ├── RestTimerService.swift      # NEW - background-safe timer
│   │   └── ExportService.swift
│   │
│   ├── Views/
│   │   ├── Onboarding/
│   │   │   ├── WelcomeView.swift
│   │   │   ├── LevelSelectionView.swift
│   │   │   ├── HealthKitPermissionView.swift
│   │   │   ├── IdentityView.swift
│   │   │   ├── BaselineTestView.swift
│   │   │   └── UncomfortableTruthOnboardingView.swift   # NEW - final screen
│   │   ├── Main/
│   │   │   ├── RootTabView.swift
│   │   │   ├── TodayView.swift          # now has identity line, resume banner, skip-today button
│   │   │   └── SkipTodaySheet.swift     # NEW
│   │   ├── Workout/
│   │   │   ├── WorkoutView.swift        # now has warm-up card, travel-mode toggle, strength button
│   │   │   ├── WarmUpCard.swift         # NEW
│   │   │   ├── PreWorkoutPrayerSheet.swift
│   │   │   ├── PostWorkoutPrayerSheet.swift
│   │   │   ├── ExerciseCardView.swift
│   │   │   ├── SetLoggerView.swift
│   │   │   ├── RestTimerView.swift      # rewritten as time-based
│   │   │   ├── AlternativesSheet.swift
│   │   │   ├── ScriptsAndVersesSheet.swift  # "Today's Strength" sheet
│   │   │   ├── GritCircuitView.swift    # NEW - Saturday circuit special flow
│   │   │   ├── ResumeWorkoutSheet.swift # NEW
│   │   │   └── WorkoutSummaryView.swift
│   │   ├── Log/
│   │   │   ├── DailyLogView.swift
│   │   │   ├── GtgLogView.swift
│   │   │   └── RuckLogView.swift
│   │   ├── Review/
│   │   │   ├── SundayReviewView.swift
│   │   │   └── BaselineReviewView.swift
│   │   ├── Library/
│   │   │   ├── HardThingsView.swift
│   │   │   ├── ScriptsView.swift
│   │   │   ├── BibleVersesView.swift
│   │   │   ├── FavoriteVersesView.swift         # NEW
│   │   │   ├── PrayersView.swift
│   │   │   ├── MeditationsView.swift
│   │   │   │   ├── LectioDivinaView.swift
│   │   │   │   ├── BreathPrayerView.swift
│   │   │   │   ├── ExamenView.swift
│   │   │   │   ├── ScriptureMemorizationView.swift
│   │   │   │   └── SilentWaitingView.swift
│   │   │   ├── PrayerJournalView.swift          # NEW
│   │   │   ├── PrayerJournalEntryView.swift     # NEW
│   │   │   ├── NutritionView.swift              # NEW
│   │   │   ├── BooksView.swift
│   │   │   └── EquipmentView.swift
│   │   ├── Progress/ProgressView.swift
│   │   ├── Settings/SettingsView.swift
│   │   └── Components/
│   │       ├── PrimaryButton.swift
│   │       ├── SecondaryButton.swift
│   │       ├── NumberStepper.swift
│   │       ├── Card.swift
│   │       ├── Banner.swift
│   │       ├── VerseCard.swift             # now has heart/favorite toggle
│   │       ├── PrayerCard.swift
│   │       ├── StrengthButton.swift        # NEW - persistent scripts/verses access
│   │       └── IdentityLine.swift          # NEW
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   ├── Info.plist
│   │   └── WarMachine.entitlements
│   │
│   └── Utilities/
│       ├── Date+Helpers.swift
│       ├── Weight+Rounding.swift           # NEW - round5, round2_5 helpers
│       └── Format.swift
│
├── GtgWidget/
│   ├── GtgWidget.swift
│   ├── GtgWidgetEntryView.swift
│   ├── GtgWidgetProvider.swift
│   └── Info.plist
│
├── Shared/
│   ├── SharedModels.swift
│   └── AppGroup.swift
│
└── WarMachineTests/
    ├── EngineTests/
    │   ├── TodayEngineTests.swift
    │   ├── ProgressionEngineTests.swift
    │   ├── DeloadEngineTests.swift
    │   ├── ReturnEngineTests.swift          # covers sick/injury/travel paths
    │   └── VerseEngineTests.swift
    ├── ProtocolTests/
    │   └── StartingWeightsTests.swift       # NEW
    └── ServiceTests/
        ├── ExportServiceTests.swift
        └── RestTimerServiceTests.swift      # NEW
```

## SwiftData Schema — updates and additions

### Enum additions

```swift
enum SkipReason: String, Codable, CaseIterable {
    case sick, injured, travel, life, unplannedRest
}

// HardThingCategory gains .spiritual
enum HardThingCategory: String, Codable, CaseIterable {
    case physical, mental, social, spiritual
}
```

### UserProfile additions

```swift
@Model
final class UserProfile {
    // ... existing fields ...

    // Consolidated morning notification (replaces two separate ones)
    var morningReminderHour: Int = 6
    var morningReminderMinute: Int = 45

    var eveningReminderHour: Int = 21
    var eveningReminderMinute: Int = 0
    var workoutReminderHour: Int = 18

    // State flags
    var injuryFlag: Bool = false
    var injuryNote: String?
    var rebuildModeRemainingSessions: Int = 0   // when > 0, next N workouts use 80% weights
}
```

### DailyLog additions

```swift
@Model
final class DailyLog {
    // ... existing fields ...
    var morningPrayerPrayed: Bool = false
    var eveningPrayerPrayed: Bool = false
    var examenNotes: String?

    // Skip handling
    var skippedReason: SkipReason?
    var skippedNote: String?

    // Prayer journal link
    var linkedJournalEntryID: UUID?
}
```

### PrayerJournalEntry model

```swift
@Model
final class PrayerJournalEntry {
    var id: UUID
    var createdAt: Date
    var date: Date                           // startOfDay — allows "today's entry" query
    var text: String
    var tag: String?                         // free-form user tag
    var linkedFromDailyLog: Bool             // true if created via evening prayer flow

    init(text: String, tag: String? = nil, linkedFromDailyLog: Bool = false) {
        self.id = UUID()
        self.createdAt = .now
        self.date = Calendar.current.startOfDay(for: .now)
        self.text = text
        self.tag = tag
        self.linkedFromDailyLog = linkedFromDailyLog
    }
}
```

### FavoriteVerse — now full v1 implementation

```swift
@Model
final class FavoriteVerse {
    #Unique<FavoriteVerse>([\.reference])
    var reference: String                    // e.g., "Psalm 144:1"
    var savedAt: Date
    var note: String?                        // optional personal note

    init(reference: String, note: String? = nil) {
        self.reference = reference
        self.savedAt = .now
        self.note = note
    }
}
```

`VerseCard` exposes a heart icon that toggles favorite state via this model.

### WorkoutSession — two new fields for resume + travel mode

```swift
@Model
final class WorkoutSession {
    // ... existing fields ...
    var isTravelMode: Bool = false           // session-level flag
    var abandoned: Bool = false              // user explicitly discarded
}
```

## Starting Weights (all lifts, all levels)

`Protocol/StartingWeights.swift` is the single source for initial weights across the program. Derived from bodyweight and level; accessories derived from main lifts where possible.

```swift
import Foundation

enum StartingWeights {

    /// Returns the starting working weight (lbs) for a given lift.
    /// `bodyweight` is in pounds.
    static func weight(for liftKey: String,
                       level: TrainingLevel,
                       bodyweight bw: Double) -> Double {

        func round5(_ x: Double) -> Double { max(0, (x / 5.0).rounded() * 5.0) }
        func round25(_ x: Double) -> Double { max(0, (x / 2.5).rounded() * 2.5) }

        switch liftKey {
        // ── Main lifts (barbell, bodyweight multipliers) ─────────────────
        case "back-squat":
            return round5(bw * [.beginner: 1.00, .intermediate: 1.25, .advanced: 1.50][level]!)
        case "bench-press":
            return round5(bw * [.beginner: 0.60, .intermediate: 0.80, .advanced: 1.00][level]!)
        case "deadlift":
            return round5(bw * [.beginner: 1.25, .intermediate: 1.50, .advanced: 1.85][level]!)
        case "overhead-press":
            return round5(bw * [.beginner: 0.40, .intermediate: 0.55, .advanced: 0.65][level]!)
        case "barbell-row":
            return round5(bw * [.beginner: 0.50, .intermediate: 0.70, .advanced: 0.80][level]!)
        case "weighted-pullup":
            // Added weight on top of bodyweight. Beginners & intermediates start unweighted.
            return level == .advanced ? round5(bw * 0.10) : 0

        // ── Accessory lower ──────────────────────────────────────────────
        case "romanian-deadlift":
            return round5(weight(for: "deadlift", level: level, bodyweight: bw) * 0.70)
        case "walking-lunge-db":   // per dumbbell
            return [.beginner: 20, .intermediate: 25, .advanced: 35][level]!
        case "leg-press":
            return round5(weight(for: "back-squat", level: level, bodyweight: bw) * 1.50)
        case "leg-curl":
            return [.beginner: 40, .intermediate: 60, .advanced: 80][level]!
        case "calf-raise":
            return round5(weight(for: "back-squat", level: level, bodyweight: bw) * 0.50)

        // ── Accessory upper push ─────────────────────────────────────────
        case "incline-db-press":   // per dumbbell
            return round25(weight(for: "bench-press", level: level, bodyweight: bw) * 0.25)
        case "lateral-raise":      // per dumbbell
            return [.beginner: 10.0, .intermediate: 12.5, .advanced: 15.0][level]!
        case "weighted-dip":
            return level == .advanced ? 25 : 0
        case "triceps-pushdown":
            return round5(bw * 0.25)

        // ── Accessory upper pull ─────────────────────────────────────────
        case "seated-cable-row":
            return round5(bw * 0.60)
        case "face-pull":
            return [.beginner: 25, .intermediate: 35, .advanced: 45][level]!
        case "barbell-curl":
            return round5(bw * 0.30)
        case "hammer-curl":        // per dumbbell
            return [.beginner: 15, .intermediate: 20, .advanced: 30][level]!

        // ── Carries (per hand unless noted) ──────────────────────────────
        case "farmers-carry":
            return round5(bw * 0.50)
        case "suitcase-carry":
            return round5(bw * 0.40)

        // ── Ruck starting load ───────────────────────────────────────────
        case "ruck-load":
            return [.beginner: 20, .intermediate: 35, .advanced: 45][level]!

        default:
            return 0
        }
    }
}
```

Tested via `StartingWeightsTests.swift`. Edge cases: sub-150 bodyweight, 250+ bodyweight, level transitions (re-running onboarding).

## Protocol Data — static content files

All Christian content files (`BibleVerses.swift`, `Prayers.swift`, `Meditations.swift`) are unchanged — see the Claude Code prompt for the authoritative NIV text. Additions:

### `Nutrition.swift`

Static reference data, computed from user's bodyweight:

```swift
struct NutritionGuidance {
    let proteinGrams: Int         // bodyweight × 1
    let waterOunces: Int          // bodyweight × 0.5
    let carbsNote: String         // "Moderate-high on training days: rice, oats, potatoes, fruit, pasta, bread"
    let fatsNote: String          // "~25-30% of calories: olive oil, avocado, eggs, fatty fish, nuts"
    let electrolytesNote: String  // "On long conditioning days: LMNT-style mix or salt food + potassium"
    let sampleMealPlan: [Meal]    // scaled if bodyweight differs significantly from 200lb reference
}
```

The view renders these as sections with no interactive logging — pure reference.

### `WarmUps.swift`

Per-day warm-up routines, verbatim from PDF:

```swift
struct WarmUpRoutine {
    let dayType: DayType
    let durationMinutes: ClosedRange<Int>    // 5...8 typical
    let steps: [String]
}
```

Example for Legs:
- "Bike or row 5 minutes"
- "20 bodyweight squats"
- "10 walking lunges each leg"
- "10 glute bridges"
- "10 leg swings each direction"

Rendered as a collapsible card in WorkoutView with "Skip" and "Warm-up done" buttons. Not timed, not logged beyond a boolean.

### `UncomfortableTruth.swift`

```swift
enum UncomfortableTruth {
    static let passage = """
    None of this is secret. None of it is complicated.

    People who seem to have inhuman willpower aren't using different techniques \
    — they've just been doing these boring things consistently for years.

    There's no hack. There's no shortcut. There's just today's rep.
    Do it. Then do tomorrow's.

    The first one is the hardest.
    """
}
```

Shown as final onboarding screen and as a banner on first open of Weeks 4, 8, 12.

### `HardThings.swift` — Spiritual category

Twelve items covering Scripture reading, memorization, uninterrupted prayer, social media fast, skipping a meal for prayer, confession, written forgiveness, anonymous giving, attending church, praying for someone you resent, reading a Psalm aloud, 30 minutes of silence. See Claude Code prompt for full list.

### `Books.swift`

Two arrays: `secular` (PDF's 12 books) and `christian` (Mere Christianity, The Practice of the Presence of God, The Pursuit of God, The Ruthless Elimination of Hurry, Spiritual Disciplines for the Christian Life, Celebration of Discipline).

## Engine Modules

### `TodayEngine.swift`

Adds two methods:

```swift
enum TodayEngine {
    // existing: current week, is deload week, day type for today, baseline test due

    /// Returns the most recent incomplete (not completedAt, not abandoned) WorkoutSession.
    /// Surfaces the Resume banner on TodayView.
    static func incompleteWorkout(context: ModelContext) -> WorkoutSession? { ... }

    /// True if today is the first open of week 4, 8, or 12.
    /// Used to surface Uncomfortable Truth banner.
    static func isUncomfortableTruthMilestone(for date: Date,
                                              startDate: Date,
                                              lastShownMilestone: Int?) -> Bool { ... }
}
```

### `ReturnEngine.swift` — three-branch logic

```swift
enum ReturnPolicy {
    case continueNormally
    case resumeAtCurrent
    case restartAt(percent: Double, rebuildWeeks: Int)
    case returningFromIllness           // 80% for 2-3 sessions via rebuildMode
    case injuryFlagged(note: String?)   // paused progression, banner
    case travelOrLifeGap                // resume normally, no restart
}

enum ReturnEngine {
    /// Evaluates the user's current state based on DailyLogs and UserProfile flags.
    static func evaluate(now: Date,
                         lastCompletedWorkout: Date?,
                         recentDailyLogs: [DailyLog],   // last 30 days
                         userProfile: UserProfile) -> ReturnPolicy {

        // 1. Injury flag wins
        if userProfile.injuryFlag {
            return .injuryFlagged(note: userProfile.injuryNote)
        }

        // 2. Rebuild mode active → returning from illness
        if userProfile.rebuildModeRemainingSessions > 0 {
            return .returningFromIllness
        }

        guard let last = lastCompletedWorkout else {
            return .continueNormally  // no workouts yet
        }

        let daysSince = Calendar.current.dateComponents(
            [.day], from: last, to: now
        ).day ?? 0

        if daysSince <= 2 { return .continueNormally }

        // 3. Check if recent days were mostly skipped-with-reason
        let gapDays = recentDailyLogs.filter { $0.date > last && $0.date <= now }
        let sickCount = gapDays.filter { $0.skippedReason == .sick }.count
        let legitCount = gapDays.filter {
            [.travel, .life, .unplannedRest].contains($0.skippedReason ?? .life)
        }.count
        let unexplainedCount = gapDays.count - sickCount - legitCount

        // If most of the gap was sick → illness return path
        if sickCount >= 2 && sickCount > unexplainedCount {
            return .returningFromIllness
        }

        // If most of the gap was travel/life → resume normally
        if legitCount > unexplainedCount {
            return .travelOrLifeGap
        }

        // Otherwise — unexplained absence, apply original Return Protocol
        switch daysSince {
        case 3...7:   return .resumeAtCurrent
        case 8...21:  return .restartAt(percent: 0.80, rebuildWeeks: 1)
        default:      return .restartAt(percent: 0.70, rebuildWeeks: 2)
        }
    }
}
```

On `.returningFromIllness` selection, the TodayView prompts the user, and upon acceptance sets `userProfile.rebuildModeRemainingSessions = 3`. Each subsequent WorkoutView applies `currentWeight * 0.80` and decrements the counter on completion.

### `VerseEngine.swift` — unchanged from prior spec

## Services

### `RestTimerService.swift` — NEW

Time-based, background-safe rest timer. Stores timer state in a shared struct exposed via `@Observable`:

```swift
@Observable
final class RestTimerService {
    struct TimerState: Codable {
        var exerciseLogID: UUID
        var setIndex: Int
        var startedAt: Date
        var durationSeconds: Int
    }

    private(set) var state: TimerState?

    var remainingSeconds: Int {
        guard let s = state else { return 0 }
        let elapsed = Date().timeIntervalSince(s.startedAt)
        return max(0, s.durationSeconds - Int(elapsed))
    }

    var isRunning: Bool { remainingSeconds > 0 }

    func start(exerciseLogID: UUID, setIndex: Int, duration: Int) async {
        state = TimerState(exerciseLogID: exerciseLogID,
                           setIndex: setIndex,
                           startedAt: .now,
                           durationSeconds: duration)
        await NotificationService.shared.scheduleRestTimer(duration: duration)
    }

    func skip() {
        state = nil
        Task { await NotificationService.shared.cancelRestTimer() }
    }
}
```

Timer is **elapsed-based, not countdown** — app backgrounding doesn't pause it. When the user returns, UI derives `remainingSeconds` from `state.startedAt + duration - now`. If ≤ 0, timer auto-dismisses.

### `NotificationService.swift` — updated schedule

Consolidated morning notification:

```swift
/// Schedules a single daily morning notification deep-linking to TodayView.
/// Default 6:45. User-configurable.
func scheduleMorningReminder(hour: Int, minute: Int) async throws { ... }
```

Full schedule:
- **Morning** (daily, default 6:45) — single notification replacing prior separate prayer + promise reminders
- **Workout reminder** (training days, default 18:00)
- **Evening review** (daily, default 21:00) — combined prayer + 3-question prompt
- **Sunday Sabbath review** (Sunday 18:00)
- **Rest timer** (one-shot via `RestTimerService`)
- **Deload week flag** (calendar trigger at week 5 and week 6 boundaries)

### Other services unchanged

## UI Integration — key additions

### TodayView layout

```
┌──────────────────────────────┐
│ Week 3 · Day 15              │
│ "I am a son of God who does  │
│  the work."                  │  ← identity line
├──────────────────────────────┤
│ [ Today's Strength ]         │  ← StrengthButton, persistent
├──────────────────────────────┤
│ ⚠ Resume workout in progress │  ← only if incomplete session exists
│ Started 2h ago                │
│ [Resume]  [Discard]          │
├──────────────────────────────┤
│ Today: Legs                  │
│ 60–75 min · 7 exercises      │
│       [ Start Workout ]      │
│       [ Skip today ]         │  ← opens SkipTodaySheet
├──────────────────────────────┤
│ VERSE OF THE DAY      ♡      │  ← heart toggles FavoriteVerse
│ "Praise be to the LORD..."   │
│  — Psalm 144:1 · NIV         │
├──────────────────────────────┤
│ Daily Grit                   │
│ □ Morning prayer             │
│ □ Promise: ___               │
│ □ Hard thing: ___            │
│ □ Evening prayer             │
├──────────────────────────────┤
│ Pull-ups: 3/8 sets · 12 reps │
├──────────────────────────────┤
│ Resting HR: 52 · Sleep: 7.4h │
└──────────────────────────────┘
```

### Workout flow — updated

1. Tap Start → **WarmUpCard** shown at top, collapsible, default collapsed
   - "Show warm-up" / "Skip" / "Done" buttons
2. **PreWorkoutPrayerSheet** (skippable)
3. Optional: Travel Mode toggle in nav bar → swaps all exercises to travel alternatives for this session
4. Exercise-by-exercise flow as before
5. **Strength button** persistent in nav bar for mid-workout scripts & verses
6. Rest timer time-based, background-safe
7. On completion → WorkoutSummaryView → post-workout prayer → progression evaluation
8. If `rebuildModeRemainingSessions > 0`, weights are auto-80%'d for this session; counter decremented on completion

### Saturday Grit flow — special

After completing the ruck, TodayView shows "Grit Circuit" as a separate session button. Tapping opens `GritCircuitView`:

```
┌──────────────────────────────┐
│ Grit Circuit                 │
│ Break as needed. Finish the  │
│ work.                         │
├──────────────────────────────┤
│ Push-ups          34/50  ▓▓░ │  ← tap to log more
│ Pull-ups          12/25  ▓░░ │
│ Air squats        0/100  ░░░ │
│ Sit-ups           50/50  ▓▓▓ │  ← complete, checkmark
│ Bear crawl        0/40y  ░░░ │
├──────────────────────────────┤
│        [ Finish ]            │  ← disabled until all complete
└──────────────────────────────┘
```

Tap any tile → NumberStepper modal "How many did you just do?" → subtracts from remaining. Tile shows checkmark when target hit. Alternatives picker per tile. Saves as WorkoutSession with dayType `.grit`.

### Return Protocol display

When `ReturnEngine` returns anything other than `.continueNormally`, TodayView surfaces a prayer-forward prompt:

For `.returningFromIllness`:
```
┌──────────────────────────────┐
│ [Verse: Lamentations 3:22-23]│
├──────────────────────────────┤
│ Welcome back.                │
│ The protocol is clear:       │
│ rest until 24h symptom-free, │
│ then 80% for 2–3 sessions    │
│ before normal.               │
│                              │
│ [ Pray and begin at 80% ]    │
│ [ Not yet ]                  │
└──────────────────────────────┘
```

For `.injuryFlagged`:
```
┌──────────────────────────────┐
│ Injury noted.                │
│ "See a physio. Work around   │
│  it. Never train through     │
│  sharp pain."                │
│                              │
│ Progression is paused.       │
│ You can still log workouts.  │
│                              │
│ [ Clear injury flag ]        │
│ [ Edit note ]                │
└──────────────────────────────┘
```

For `.travelOrLifeGap`:
```
┌──────────────────────────────┐
│ Welcome back.                │
│ Resuming at current weights. │
│                              │
│ [ Start today's workout ]    │
└──────────────────────────────┘
```

For the harder restart paths: prayer-after-failure card + verse + the original copy.

### SkipTodaySheet

```
┌──────────────────────────────┐
│ Skip today?                  │
├──────────────────────────────┤
│ ○ Sick                       │
│ ○ Injured                    │
│ ○ Traveling / no equipment   │
│ ○ Life / emergency           │
│ ○ Unplanned rest             │
├──────────────────────────────┤
│ Note (optional)              │
│ [__________________________] │
├──────────────────────────────┤
│         [ Save ]             │
└──────────────────────────────┘
```

Writes `DailyLog.skippedReason` and optional `skippedNote`. If "Injured" → also sets `userProfile.injuryFlag = true`.

### PrayerJournalView

- List of entries, newest first, grouped by month
- Search bar at top (searches text and tag)
- Tap entry → PrayerJournalEntryView (edit, delete, save)
- + button → new entry
- Entry view: date header, large text field, optional tag field, Save/Cancel

Auto-prompt at end of evening prayer flow: "Add a note for today?" → if yes, opens new entry prefilled with today's date, linked to DailyLog.

### FavoriteVersesView

- List of favorited verses
- Sort controls: by date saved (default), by reference (canonical Bible order), by theme
- Tap → expanded VerseCard with optional personal note field
- Swipe to unfavorite

### StrengthButton component

Persistent UI affordance. Shows as a labeled icon button using SF Symbol `shield.lefthalf.filled`. Present in:
- TodayView top-right nav
- WorkoutView top-right nav (always visible during workouts)
- GritCircuitView top-right nav

Tap opens `ScriptsAndVersesSheet`:
- Eight self-talk scripts, each with anchor verse
- "Give me one" button picks contextually (mid-workout → perseverance; pre-workout → strength/courage; struggling → identity; failed promise → failure & return)
- Large type for under-load reading

### NutritionView

Four sections:
1. **Targets** — protein grams (bodyweight × 1), water ounces (bodyweight × 0.5). Auto-computed from UserProfile.bodyweight.
2. **Carbs & fats** — guidance copy from PDF
3. **Electrolytes** — note for long conditioning days
4. **Sample training day** — meal plan from PDF, with a note: "Scale portions to your calorie target."

No tracking. No logging. Pure reference.

### UncomfortableTruth placements

1. Final onboarding screen (`UncomfortableTruthOnboardingView`) — full passage, single "I understand. Begin." button
2. First-open-of-week banner on weeks 4, 8, 12 — shortened pull quote: "There's no hack. There's no shortcut. There's just today's rep."
3. Settings → About screen — full text, always readable

## Testing

- `StartingWeightsTests.swift` — verifies rounding, edge cases (low/high bodyweight), level differentiation
- `ReturnEngineTests.swift` — all six policy branches, gap calculations with mixed skip reasons, rebuild mode
- `RestTimerServiceTests.swift` — background elapsed accuracy, skip behavior
- `ExportServiceTests.swift` — roundtrip including new models (PrayerJournalEntry, FavoriteVerse)

## Performance — unchanged

All additions are static data or one-time computations. No runtime perf impact.

## Tone Discipline (reinforced)

- **No saccharine language.** No "champion!", no "God's got this!", no "you got this!"
- **No exclamation points** except "Amen."
- **No emoji.**
- **SF Symbols only.** No religious symbols (no cross icons); use `text.book.closed` for verses, `shield.lefthalf.filled` for the Strength button, `heart` / `heart.fill` for favorites.
- **Verse references always include translation tag "NIV" on first display per screen.**
- **Bold the reference, regular the body.**
- **Prayers are written once by a careful hand.** No generated devotionals. No verse-randomizer-with-inspirational-backgrounds.
