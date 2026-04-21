import Foundation

enum VerseEngine {

    /// Deterministic verse-of-day from date seed. Same date → same verse.
    static func verseOfDay(on date: Date = .now) -> BibleVerse {
        let dayKey = Calendar.current.startOfDay(for: date).timeIntervalSince1970
        let seed = UInt64(max(0, dayKey))
        let index = Int(seed % UInt64(BibleVerses.all.count))
        return BibleVerses.all[index]
    }

    /// Theme preferred for a given DayType.
    static func preferredTheme(for dayType: DayType) -> VerseTheme {
        switch dayType {
        case .legs, .push, .pull: return .strength
        case .intervals:          return .perseverance
        case .zone2:              return .trust
        case .grit:               return .warfare
        case .rest:               return .rest
        }
    }

    /// Verse pick biased toward a theme for today, but deterministic per date.
    static func themedVerseOfDay(on date: Date = .now, theme: VerseTheme? = nil) -> BibleVerse {
        if let theme {
            let pool = BibleVerses.byTheme(theme)
            guard !pool.isEmpty else { return verseOfDay(on: date) }
            let dayKey = Calendar.current.startOfDay(for: date).timeIntervalSince1970
            let seed = UInt64(max(0, dayKey))
            let idx = Int(seed % UInt64(pool.count))
            return pool[idx]
        }
        return verseOfDay(on: date)
    }

    /// Weekly memorization review cadence. Returns the memorized favorite with the
    /// oldest `lastReviewedAt` if that value is at least 7 days old (or nil). Returns
    /// nil when there are no memorized verses or all are within the past week.
    static func memorizationReviewDue(favorites: [FavoriteVerse], now: Date = .now) -> FavoriteVerse? {
        let memorized = favorites.filter { $0.isMemorized }
        guard !memorized.isEmpty else { return nil }
        let weekSeconds: TimeInterval = 7 * 24 * 60 * 60
        let due = memorized.filter { fv in
            guard let last = fv.lastReviewedAt else { return true }
            return now.timeIntervalSince(last) >= weekSeconds
        }
        return due.min { a, b in
            (a.lastReviewedAt ?? .distantPast) < (b.lastReviewedAt ?? .distantPast)
        }
    }

    // MARK: Weekly memorization target

    /// Monday-normalized start of the week containing `date`. Matches the
    /// `weekday = 2` convention used by SundayReview.
    static func weekStart(of date: Date) -> Date {
        let cal = Calendar.current
        var comp = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        comp.weekday = 2
        return cal.date(from: comp) ?? cal.startOfDay(for: date)
    }

    /// Picks the verse that should be "this week's memorization target" for the
    /// week containing `date`. Preference order:
    /// 1. User's non-memorized favorites, oldest-saved first, skipping any
    ///    reference used by the last 8 prior targets.
    /// 2. User's memorized favorites that haven't been retargeted recently
    ///    (lets memorized verses cycle back for review).
    /// 3. Deterministic themed daily pick for that Monday (fallback pool).
    static func pickWeeklyTarget(favorites: [FavoriteVerse],
                                 priorTargets: [WeeklyVerseTarget],
                                 on date: Date = .now) -> BibleVerse {
        let monday = weekStart(of: date)
        let recentRefs: Set<String> = Set(
            priorTargets
                .filter { $0.weekStartDate < monday }
                .sorted { $0.weekStartDate > $1.weekStartDate }
                .prefix(8)
                .map(\.reference)
        )

        let nonMemorized = favorites
            .filter { !$0.isMemorized && !recentRefs.contains($0.reference) }
            .sorted { $0.savedAt < $1.savedAt }
        for fav in nonMemorized {
            if let verse = BibleVerses.byReference(fav.reference) { return verse }
        }

        let memorized = favorites
            .filter { $0.isMemorized && !recentRefs.contains($0.reference) }
            .sorted {
                ($0.lastReviewedAt ?? .distantPast) < ($1.lastReviewedAt ?? .distantPast)
            }
        for fav in memorized {
            if let verse = BibleVerses.byReference(fav.reference) { return verse }
        }

        return verseOfDay(on: monday)
    }

    /// Returns the target for the week containing `date`, if one has been
    /// picked. Nil if the user hasn't opened the app yet this week.
    static func currentWeekTarget(targets: [WeeklyVerseTarget], on date: Date = .now) -> WeeklyVerseTarget? {
        let monday = weekStart(of: date)
        return targets.first { Calendar.current.isDate($0.weekStartDate, inSameDayAs: monday) }
    }
}
