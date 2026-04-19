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
}
