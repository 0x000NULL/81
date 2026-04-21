import Foundation

/// Logic for the multi-sentence identity rotation and the 30-day revisit cadence.
/// Pure — no SwiftData reads. Pass in the profile.
enum IdentityEngine {

    /// Every 30-day cycle from `lastIdentityReviewedAt` (or from `createdAt +
    /// onboardingGrace` if never reviewed). Exposed so tests don't depend on
    /// Calendar math for the interval itself.
    static let revisitInterval: TimeInterval = 30 * 24 * 60 * 60
    /// Suppress the 30-day prompt for this window after profile creation so
    /// it doesn't fire during onboarding week.
    static let onboardingGrace: TimeInterval = 30 * 24 * 60 * 60

    /// The sentence to display on `date`. Deterministic: same date → same
    /// sentence from the array. Falls back to the legacy single `identitySentence`
    /// when `identitySentences` is empty.
    static func sentenceForToday(profile: UserProfile, on date: Date = .now) -> String {
        let pool = profile.identitySentences.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !pool.isEmpty else { return profile.identitySentence }
        let dayKey = Calendar.current.startOfDay(for: date).timeIntervalSince1970
        let seed = UInt64(max(0, dayKey))
        let idx = Int(seed / 86_400 % UInt64(pool.count))
        return pool[idx]
    }

    /// True when the user should be prompted to revisit their identity sentences.
    /// Logic:
    ///   - If never reviewed: due once `date >= profile.createdAt + onboardingGrace`.
    ///   - Otherwise: due once `date >= lastIdentityReviewedAt + revisitInterval`.
    static func reviewDue(profile: UserProfile, on date: Date = .now) -> Bool {
        if let last = profile.lastIdentityReviewedAt {
            return date.timeIntervalSince(last) >= revisitInterval
        }
        return date.timeIntervalSince(profile.createdAt) >= onboardingGrace
    }

    /// The next scheduled date at which the review prompt becomes due. Used
    /// to book the one-shot notification.
    static func nextReviewDueAt(profile: UserProfile, now: Date = .now) -> Date {
        let base = profile.lastIdentityReviewedAt ?? profile.createdAt
        let interval: TimeInterval = profile.lastIdentityReviewedAt == nil ? onboardingGrace : revisitInterval
        let scheduled = base.addingTimeInterval(interval)
        // Guard against a due-date in the past (e.g. long-abandoned profile)
        // so we always book at least a little ahead of `now`.
        return max(scheduled, now.addingTimeInterval(60 * 60))
    }

    /// Stamp `lastIdentityReviewedAt` to `date`. Caller saves context and
    /// re-books the notification.
    static func markReviewed(profile: UserProfile, on date: Date = .now) {
        profile.lastIdentityReviewedAt = date
    }

    /// Used by the one-time launch-step seeding the array from the single
    /// onboarding sentence for pre-v1.5 profiles.
    static func seedIfNeeded(profile: UserProfile) {
        guard profile.identitySentences.isEmpty else { return }
        let seed = profile.identitySentence.trimmingCharacters(in: .whitespaces)
        guard !seed.isEmpty else { return }
        profile.identitySentences = [seed]
    }
}
