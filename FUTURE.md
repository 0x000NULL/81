# Future ideas

These came up during the v1.0 build but were explicitly out of scope.

## Near-term (v1.1)

- Recovery signals dashboard — 7-day HR, HRV, sleep trend cards on Today view.
- Book reading progress page (track pages / chapters across secular + Christian).
- Timeline view — 12-week phase descriptions with "You are here" marker.
- Scripture memorization tracker — mark verses `memorized`, review prompts.
- Prayer journal enhancements — date range filter, tag filter, entries-per-month counts.
- Full app icon set at all sizes (1024 only currently). Add 180, 120, 87, 80, 60, 58, 40.
- Live HR display during Thursday Zone 2 with "180 - age" target indicator.
- Saturday ruck auto-hand-off to GritCircuitView on session end.

## Post-v1

- Shortcuts actions — "Log GTG set" via Siri.
- Focus filter integration for training days.
- iCloud backup (beyond export JSON).
- Weekly Scripture prompt — auto-suggest a verse Monday morning for Thursday memorization.
- Charts on Sunday review screen (promise rate trend, workout completion bar chart).
- Multiple identity sentences with 30-day cadence reminder to revisit.
- Apple Watch companion for rest timer and GTG logging.

## Explicitly declined

- Social features.
- Multi-user accounts.
- Video form demos.
- AI form analysis.
- Nutrition tracking (reference only; auto-computed targets are intentionally the ceiling).
- Multiple Bible translations (NIV only, as a deliberate choice).
- Multi-denominational content mode.
- Metric units.
- iPad / Mac Catalyst.

## Technical debt noted but not fixed

- `SourceKit` live diagnostics occasionally lag after new files; `xcodegen generate` resolves. Not a runtime issue.
- Export screen uses `FileDocument` with a minimal wrapper. Could be improved with direct `.fileExporter` document type.
- `HealthKitService.lastNightSleepSeconds` uses a 24-hour window ending at noon today. Edge cases for travelers crossing time zones not handled.
- `RestTimerService` is a singleton on MainActor — tests are serialized. Consider per-context instances for more robust testability.
