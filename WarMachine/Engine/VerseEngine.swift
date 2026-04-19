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
}
