# War Machine Protocol iOS App — Goal

## Vision

A single-user, native iOS app that operationalizes the War Machine Protocol for a Christian man — a 22-page static PDF turned into a living, autoregulated training companion with full HealthKit integration, GPS-tracked rucks, lock-screen widgets, and Scripture woven through every screen.

This is a **personal tool**, not a product. Built for one user, shipped to one device, tuned for one 8–12 week program. Every design decision defers to one question: **does this help me show up today, in body and spirit?**

> *"Praise be to the LORD my Rock, who trains my hands for war, my fingers for battle."* — Psalm 144:1 (NIV)

## Christian Foundation

This is not a secular training app with a verse tacked onto the home screen. The Christian frame is core:

- **The body is the Lord's.** Training is stewardship, not vanity. *"Do you not know that your bodies are temples of the Holy Spirit... honor God with your bodies."* (1 Corinthians 6:19–20)
- **Discipline is formation.** Every rep is a chance to die to self. *"I strike a blow to my body and make it my slave."* (1 Corinthians 9:27)
- **Rest is obedience.** Sunday isn't skipped — it's kept. The Sabbath is a command, not a recovery hack.
- **Strength is borrowed.** The prayers and verses throughout the app remind me whose power I'm operating on.
- **Return is always possible.** When I fall, His mercies are new every morning (Lamentations 3:22–23).

Prayers and Scripture are **integrated into the daily flow** (pre-workout, morning log, evening log, Sunday review), not buried in a separate "devotional" section.

## Scope Boundary

- **iOS only.** iPhone. iOS 17.4+.
- **No WatchOS companion.**
- **No backend.** All data in SwiftData on device.
- **Single user.** No account system, no sharing.
- **NIV only.** No translation switcher.
- **Imperial units only.** Weights in lbs, distance in miles, pace in min/mile. HealthKit conversion happens at the service boundary regardless of device locale.

## Core Principles

1. **The protocol decides, the user executes.**
2. **HealthKit for everything measurable.**
3. **One screen per task.**
4. **The log is the point.** Exportable as JSON any time.
5. **Honest feedback.** No participation trophies.
6. **Prayer is a prompt, never a paywall.** Every prayer and verse can be skipped with one tap.

## Functional Requirements

### MUST HAVE (v1)

**Onboarding**
- Experience level selection (Beginner / Intermediate / Advanced)
- HealthKit authorization with clear explanation
- Starting bodyweight + waist (HealthKit pre-fills bodyweight if available)
- Identity sentence capture with Christian framing suggestions as tappable chips
- Initial baseline test (1-mile run, max push-ups 2 min, max pull-ups, 2-mile ruck at 25 lbs, resting HR)
- Notification permission with default schedule
- **"Uncomfortable Truth" screen** as the final onboarding step — the PDF's closing passage verbatim ("None of this is secret... There's just today's rep.") with one button: "I understand. Begin."

**Today screen (main hub)**
- **Identity sentence** displayed subtly below header ("I am ___")
- Today's workout type with duration and preview
- **Verse of the day** card — rotating from themed library
- **"Today's strength" button** (persistent icon in nav bar) — one tap opens scripts & verses sheet for when things are hard, accessible outside of workouts too
- One-tap start for workout
- **Resume banner** if an incomplete workout exists ("Workout in progress, started 2h ago — Resume or Discard")
- **"Skip today" button** (less prominent than Start) — opens reason picker (sick / injured / travel / life / unplanned rest)
- Current week, deload status, days since start
- GTG pull-up progress
- Daily grit status (morning prayer + promise done? evening prayer + review done? hard thing chosen?)
- HealthKit summary (resting HR, sleep)
- Recovery flag banner if red signals present
- **Uncomfortable Truth banner** on first open of weeks 4, 8, and 12 (reminder of the closing message)

**Workout logger**
- **Warm-up card** at top of workout, collapsed by default — contains the day's specific warm-up from the PDF. Buttons: "Skip" and "Warm-up done." Log-only, not timed.
- **Travel Mode toggle** in session header — one tap swaps every exercise to its bodyweight/travel alternative across the whole session; individual swaps still possible
- **Mid-workout resume**: if app is closed and reopened, state is restored; user returns to the exact set they were on
- Pre-workout prayer sheet shown on start (skippable)
- Per exercise: target sets × reps, target weight (from progression), rest duration
- NumberStepper for weight/reps
- Rest timer runs in background with notification + haptic. **Time-based, not countdown** — if app backgrounded and user returns after timer elapsed, auto-dismisses cleanly. "Skip rest" button always available.
- Alternatives sheet per exercise
- **Scripts & Verses sheet ("Today's Strength")** always accessible from nav bar, one tap, large target. Shows 8 self-talk scripts paired with anchor verses, plus a "Give me one" button that picks contextually.
- Subjective difficulty (1–10) at session end
- Post-workout prayer on completion (short, skippable)
- Writes HKWorkout to HealthKit (strength / HIIT / hiking per day type)

**Saturday Grit Day circuit (special flow)**
- After the ruck, a dedicated `GritCircuitView` — not the standard set/rep logger
- Five movement tiles (push-ups 50, pull-ups 25, air squats 100, sit-ups 50, bear crawl 40 yards)
- Each tile: progress bar + tap to enter "how many did you just do?" → subtracts from remaining
- Break-as-needed model matches PDF intent
- Alternatives available per tile
- Completes when all five hit their target

**Tracked workout sessions** (HealthKit live workout)
- Tuesday intervals: HR zones, saves HKWorkout
- Thursday Zone 2: HR monitoring with "180 minus age" target; optional Scripture Memorization mode (weekly verse, not daily — so a verse has time to actually stick)
- Saturday ruck: GPS + HR + distance, HKWorkout with route

**Autoregulated progression**
- **Starting weights derived from bodyweight + level** — see architecture.md `StartingWeights` table covering all 20+ lifts in the program, not just the big six
- Main lifts: top of rep range cleanly → +5 upper / +10 lower
- Accessories: 2 consecutive top sessions → +5 or +1 set
- Ruck: distance at target pace → +2.5–5 lb or +0.5 mi

**Grease-the-groove pull-ups**
- Daily counter, auto-skips Fri/Sun
- Lock screen + home screen widget

**Ruck tracker**
- Quick log OR live session (GPS + HR)

**Daily grit log**
- **Morning section**:
  - Morning prayer card
  - Verse of the day
  - Promise capture
  - Hard thing picker (4 categories including Spiritual)
- **Evening section**:
  - 3-question review
  - Examen card (expandable, optional notes)
  - Evening prayer card
  - Sleep/energy/HR (HealthKit pre-fills)
  - **"Add to prayer journal?" prompt** — one tap opens a text entry for that day's entry

**Prayer Journal**
- New Library section
- Free-text dated entries, searchable
- Quick "Add entry" from Library or from evening prayer flow
- Optional tags (free-form, e.g., "family", "work", "struggle")
- Included in JSON export

**Hard Thing Menu — four categories**
- Physical, Mental, Social (from PDF)
- **Spiritual** (new): ~12 items covering Scripture reading, memorization, fasting, forgiveness, silence, etc.

**Library**
- Prayers (7 prayers, full text)
- Bible Verses (~41 NIV verses by theme) — **one-tap heart to save to favorites**
- **Favorite Verses** — personal collection of saved verses, sortable by date/reference/theme
- Meditations (6 guided practices: Lectio Divina, Breath Prayer, Examen, Scripture Memorization, Silent Waiting, Attribute of God)
- Scripts (8 from PDF, each paired with anchor verse)
- Books (secular from PDF + Christian section)
- Equipment (from PDF)
- **Nutrition** — reference only, no tracking. Protein target auto-computed from bodyweight (1g/lb), water target (half bodyweight in oz), carbs/fats guidance, electrolytes note for long conditioning days, sample training-day meal plan.

**Weekly Sunday review — Sabbath framed**
- Local notification Sunday 6pm
- Opens with Sabbath prayer + rest-themed verse (Matthew 11:28–30 or Mark 2:27)
- Computed stats: workouts completed, promise rate, hard things, prayers prayed, HR trend, sleep average
- Four prompts: pattern / win / focus for next week / **where did I see God this week?**
- Locks week on save

**Baseline fitness test**
- Every 4 weeks (Weeks 0, 4, 8, 12)
- Comparison view

**Deload automation**
- Weeks 5–6 banner, 40% reduced weights, one week

**Skip day handling**
- Reason picker: sick / injured / travel / life / unplanned rest
- Stored on DailyLog, exported in JSON
- Affects Return Protocol logic (see below)

**Return Protocol — now handles three states**

*Pure absence (no logs, no skip reasons):*
- 1 missed: verse + "Don't miss twice. His mercies are new today."
- 1 week: resume at current, prayer after failure
- 2–3 weeks: restart at 80%, rebuild 1 week, prayer after failure
- 4+ weeks: restart at 70%, rebuild 2 weeks, prayer after failure

*Consecutive sick days:*
- Resumption prompt on first non-sick day: "Returning from illness. Per the protocol: rest until 24h symptom-free, then 80% for 2–3 days before normal."
- Auto-sets "rebuild mode" flag on UserProfile — next 2 or 3 workouts use 80% of current weights
- Clears flag after rebuild window

*Injury flag:*
- Persistent banner: "See a physio. Work around it. Never train through sharp pain."
- Progression paused (no auto-suggestions) until user manually clears
- User can still log workouts; just no autoregulation while flagged

*Legitimate skips (travel, life):*
- Do NOT trigger Return Protocol restart percentages
- Resume normally when user returns

**HealthKit integration** — as previously specified
**Local notifications** — consolidated morning notification (default 6:45, "Morning") deep-linking to TodayView; workout reminder on training days; evening review at 21:00; Sunday Sabbath review at 18:00; rest timer one-shot; deload banner trigger
**Widgets** — GTG counter unchanged. No verse on widget.
**Data export/import** — JSON, schema version "1.2-christian-journal"

**Settings**
- Notification times (morning, workout, evening, Sunday)
- HealthKit status
- Export/import
- Deload status and manual trigger
- Clear injury flag / rebuild mode
- Reset with confirmation

### SHOULD HAVE (v1.1)

- Recovery signals dashboard (7-day HR trend, HRV trend, sleep trend)
- Book reading progress (secular + Christian)
- Equipment checklist
- Timeline view with phase descriptions
- Progress charts via Swift Charts
- Scripture memorization tracker (mark verses as "memorized", review prompts)
- Prayer journal: date range filtering, tag filtering, entry count per month

### NICE TO HAVE (post-v1)

- Shortcuts actions (log GTG set via Siri)
- Focus filters integration
- iCloud backup
- Live Activities for active workout (removed from v1.1 — not worth complexity)

## Explicit Non-Goals

- Social features
- Video library or form demos
- AI form analysis
- E-commerce
- Custom program building
- Nutrition tracking (reference only)
- Multiple translations
- Multi-denominational content mode
- Metric units
- iPad / WatchOS

## Success Metrics

- Complete 80%+ of scheduled workouts in first 4 weeks
- Daily grit log fill rate > 6/7 days by week 3
- Pre-workout prayer prayed on 70%+ of workouts by week 4
- All training workouts appear in Apple Health
- Zero data loss across a 12-week run
- App cold-start under 1s
- Rest timer reliably fires with app backgrounded
- Over 12 weeks: memorize at least 4 verses via Thursday Zone 2 Scripture Memorization mode
- At least one prayer journal entry per week by week 4

## The Test

If my phone dies mid-ruck and I reboot with no signal, I should still be able to log what I remember, see tomorrow's workout, pray tonight's prayer, update my grit log, write a journal entry, and see the day's verse — all offline, none lost.

> *"I have fought the good fight, I have finished the race, I have kept the faith."* — 2 Timothy 4:7 (NIV)
