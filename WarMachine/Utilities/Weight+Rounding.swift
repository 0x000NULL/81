import Foundation

enum WeightRounding {
    static func round5(_ x: Double) -> Double {
        max(0, (x / 5.0).rounded() * 5.0)
    }

    static func round2_5(_ x: Double) -> Double {
        max(0, (x / 2.5).rounded() * 2.5)
    }
}
