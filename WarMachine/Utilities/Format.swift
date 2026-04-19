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
}
