# Future ideas

These came up during the v1.0 build but were explicitly out of scope.

## Near-term (v1.1)

All shipped in v1.1 — see CHANGELOG.md.

## Near-term (v1.3)

Shipped — see CHANGELOG.md:
- Siri Shortcut "Log GTG set".
- iCloud backup — full SwiftData ↔ CloudKit live sync **plus** dated JSON snapshots in iCloud Drive (defense-in-depth, retain 7).

## Near-term (v1.5)

Shipped — see CHANGELOG.md:
- Weekly Scripture prompt — auto-suggest a verse Monday morning for Thursday memorization.
- Charts on Sunday review screen (promise rate trend, workout completion bar chart).
- Multiple identity sentences with 30-day cadence reminder to revisit.

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
