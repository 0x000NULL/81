import Foundation

/// Pure plate-loading helper. Given a target barbell weight, bar weight,
/// and available plate denominations, returns a per-side plate stack
/// (descending) plus the nearest-below / nearest-above targets when the
/// exact load can't be made.
///
/// Algorithm: greedy descent. Plates are sorted descending and pulled
/// (with unlimited repeats) until the remaining per-side residual is
/// less than the smallest plate.
enum PlateCalculator {
    static let defaultPlates: [Double] = [45, 35, 25, 10, 5, 2.5]

    struct Result: Equatable {
        let targetLb: Double
        let barLb: Double
        let perSide: [Double]
        let achievedLb: Double
        let nearestBelow: Double?
        let nearestAbove: Double?

        var exact: Bool { abs(achievedLb - targetLb) < 0.01 }
    }

    static func compute(targetLb: Double,
                        barLb: Double,
                        plates: [Double] = defaultPlates) -> Result {
        let cleanPlates = plates.filter { $0 > 0 }.sorted(by: >)

        // Target can't be less than the bar.
        if targetLb < barLb {
            return Result(
                targetLb: targetLb,
                barLb: barLb,
                perSide: [],
                achievedLb: min(targetLb, barLb),
                nearestBelow: nil,
                nearestAbove: barLb
            )
        }

        let perSideTarget = (targetLb - barLb) / 2.0
        let (stack, residual) = greedyStack(perSideTarget: perSideTarget, plates: cleanPlates)
        let achievedPerSide = perSideTarget - residual
        let achieved = barLb + achievedPerSide * 2

        if abs(achieved - targetLb) < 0.01 {
            return Result(
                targetLb: targetLb,
                barLb: barLb,
                perSide: stack,
                achievedLb: achieved,
                nearestBelow: nil,
                nearestAbove: nil
            )
        }

        // Not exact: the greedy answer is the nearest below (it's the
        // largest loadable weight ≤ target). Nearest above adds the
        // smallest plate that makes the total ≥ target.
        let below = achieved
        let above = nearestAbove(targetLb: targetLb, barLb: barLb, plates: cleanPlates)

        return Result(
            targetLb: targetLb,
            barLb: barLb,
            perSide: stack,
            achievedLb: achieved,
            nearestBelow: below,
            nearestAbove: above
        )
    }

    private static func greedyStack(perSideTarget: Double,
                                    plates: [Double]) -> ([Double], Double) {
        var stack: [Double] = []
        var residual = perSideTarget
        for plate in plates {
            while residual + 0.001 >= plate {
                stack.append(plate)
                residual -= plate
            }
        }
        return (stack, residual)
    }

    private static func nearestAbove(targetLb: Double,
                                     barLb: Double,
                                     plates: [Double]) -> Double? {
        guard let smallest = plates.last else { return nil }
        // Add one more smallest-plate per side past the greedy answer.
        let perSideTarget = (targetLb - barLb) / 2.0
        let (stack, _) = greedyStack(perSideTarget: perSideTarget, plates: plates)
        let perSide = stack.reduce(0, +) + smallest
        return barLb + perSide * 2
    }
}
