import Foundation

/// Opaque payload describing the matched prior-session set (or aggregate).
/// Views consume either the pre-formatted `summary` or the individual
/// fields when they want to pre-fill inputs.
struct LastSessionHint: Sendable, Equatable {
    let weightLb: Double?
    let reps: Int?
    let durationSec: Int?
    let distanceYards: Int?
    let distanceMiles: Double?
    let loadLb: Double?
    let heartRateAvg: Int?
    let summary: String
}

/// Pure look-ups over an already-fetched `[WorkoutSession]` array. The
/// caller (a view) holds a `@Query` of sessions and forwards it here so
/// the provider doesn't need a `ModelContext`.
enum LastSessionHintProvider {

    /// Per-set hint for rep-shaped logger kinds. Finds the most recent
    /// *completed* session other than `excluding` that contains an
    /// `ExerciseLog` for `exerciseKey`, then the `SetLog` at `setIndex`
    /// among that exercise's non-warmup sets.
    static func perSetHint(in sessions: [WorkoutSession],
                           excluding: UUID,
                           exerciseKey: String,
                           setIndex: Int,
                           kind: LoggerKind) -> LastSessionHint? {
        let candidates = sessions
            .filter { $0.completedAt != nil && $0.id != excluding }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }

        for session in candidates {
            guard let ex = (session.exercises ?? []).first(where: { $0.exerciseKey == exerciseKey }) else {
                continue
            }
            let sets = (ex.sets ?? [])
                .filter { ($0.setType) != .warmup }
                .sorted(by: { $0.setIndex < $1.setIndex })
            guard setIndex < sets.count else {
                return nil
            }
            let prior = sets[setIndex]
            return LastSessionHint(
                weightLb: prior.weightLb,
                reps: prior.reps,
                durationSec: prior.durationSec,
                distanceYards: prior.distanceYards,
                distanceMiles: prior.distanceMiles,
                loadLb: prior.loadLb,
                heartRateAvg: prior.heartRateAvg,
                summary: Format.lastSetHint(set: prior, kind: kind)
            )
        }
        return nil
    }

    /// Aggregate hint for cardio / ruck kinds — summarizes the most
    /// recent completed session's single primary set for this exercise.
    static func aggregateHint(in sessions: [WorkoutSession],
                              excluding: UUID,
                              exerciseKey: String,
                              kind: LoggerKind) -> LastSessionHint? {
        let candidates = sessions
            .filter { $0.completedAt != nil && $0.id != excluding }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }

        for session in candidates {
            guard let ex = (session.exercises ?? []).first(where: { $0.exerciseKey == exerciseKey }) else {
                continue
            }
            // For cardio-session / ruck we store one set; for intervals we
            // summarize total duration. In all cases, collapse to the most
            // informative single line.
            let sets = ex.sets ?? []
            if sets.isEmpty { return nil }
            let totalDur = sets.compactMap { $0.durationSec }.reduce(0, +)
            let totalMiles = sets.compactMap { $0.distanceMiles }.reduce(0, +)
            let hrs = sets.compactMap { $0.heartRateAvg }
            let hr = hrs.isEmpty ? nil : hrs.reduce(0, +) / hrs.count
            let load = sets.compactMap { $0.loadLb }.first

            let summary: String
            switch kind {
            case .cardioSession:
                summary = hr.map { "\(Format.duration(seconds: totalDur)) · \($0) bpm" }
                    ?? Format.duration(seconds: totalDur)
            case .cardioIntervals:
                summary = "\(sets.count) rounds · \(Format.duration(seconds: totalDur))"
            case .jumpRopeFinisher:
                summary = "\(sets.count) rounds · \(Format.duration(seconds: totalDur))"
            case .ruck:
                if let load, totalDur > 0, totalMiles > 0 {
                    let pace = Double(totalDur) / 60.0 / totalMiles
                    summary = String(
                        format: "%.1f mi · %@ · %d lb",
                        totalMiles, Format.pace(minPerMile: pace), Int(load)
                    )
                } else {
                    summary = String(format: "%.1f mi", totalMiles)
                }
            default:
                return nil
            }
            return LastSessionHint(
                weightLb: nil,
                reps: nil,
                durationSec: totalDur > 0 ? totalDur : nil,
                distanceYards: nil,
                distanceMiles: totalMiles > 0 ? totalMiles : nil,
                loadLb: load,
                heartRateAvg: hr,
                summary: summary
            )
        }
        return nil
    }
}
