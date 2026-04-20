import Foundation

enum Format {
    static func weight(_ lbs: Double) -> String {
        if lbs.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(lbs)) lb"
        }
        return String(format: "%.1f lb", lbs)
    }

    static func pace(minPerMile: Double) -> String {
        guard minPerMile.isFinite, minPerMile > 0 else { return "—" }
        let mins = Int(minPerMile)
        let secs = Int((minPerMile - Double(mins)) * 60)
        return String(format: "%d:%02d /mi", mins, secs)
    }

    static func miles(_ mi: Double) -> String {
        String(format: "%.2f mi", mi)
    }

    static func duration(seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    static func heartRate(_ bpm: Double?) -> String {
        guard let bpm else { return "—" }
        return "\(Int(bpm.rounded())) bpm"
    }

    static func sleepHours(_ seconds: TimeInterval?) -> String {
        guard let seconds else { return "—" }
        let h = seconds / 3600
        return String(format: "%.1f h", h)
    }

    static func hrv(_ ms: Double?) -> String {
        guard let ms else { return "—" }
        return "\(Int(ms.rounded())) ms"
    }

    /// Compact one-line summary of a completed set, shaped to its
    /// LoggerKind. Used on collapsed rows and summary cards.
    static func setSummary(set: SetLog, kind: LoggerKind) -> String {
        switch kind {
        case .weightReps, .bodyweightReps:
            return "\(Int(set.weightLb)) lb × \(set.reps)"
        case .distanceLoad:
            let yd = set.distanceYards ?? 0
            let load = set.loadLb.map { Int($0) } ?? 0
            return "\(yd)y @ \(load) lb"
        case .durationHold:
            let secs = set.durationSec ?? 0
            return "\(secs)s"
        case .cardioIntervals, .jumpRopeFinisher:
            let secs = set.durationSec ?? 0
            if let hr = set.heartRateAvg {
                return "\(duration(seconds: secs)) · \(hr) bpm"
            }
            return duration(seconds: secs)
        case .cardioSession:
            let secs = set.durationSec ?? 0
            if let hr = set.heartRateAvg {
                return "\(duration(seconds: secs)) · \(hr) bpm"
            }
            return duration(seconds: secs)
        case .ruck:
            let mi = set.distanceMiles ?? 0
            let load = set.loadLb.map { Int($0) } ?? 0
            let secs = set.durationSec ?? 0
            if secs > 0, mi > 0 {
                let pace = Double(secs) / 60.0 / mi
                return String(format: "%.2f mi · %@ · %d lb",
                              mi, pace(minPerMile: pace), load)
            }
            return String(format: "%.2f mi · %d lb", mi, load)
        }
    }

    /// One-line short hint of a prior set for the "Last:" row.
    static func lastSetHint(set: SetLog, kind: LoggerKind) -> String {
        switch kind {
        case .weightReps, .bodyweightReps:
            return "\(Int(set.weightLb)) × \(set.reps)"
        case .distanceLoad:
            let yd = set.distanceYards ?? 0
            let load = set.loadLb.map { Int($0) } ?? 0
            return "\(yd)y @ \(load) lb"
        case .durationHold:
            return "\((set.durationSec ?? 0))s"
        case .cardioIntervals, .cardioSession, .jumpRopeFinisher:
            return duration(seconds: set.durationSec ?? 0)
        case .ruck:
            let mi = set.distanceMiles ?? 0
            return String(format: "%.1f mi", mi)
        }
    }
}
