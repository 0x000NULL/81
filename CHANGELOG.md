# Changelog

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
