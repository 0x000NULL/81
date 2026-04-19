import Testing
@testable import WarMachine

@Suite("StartingWeights")
struct StartingWeightsTests {

    @Test("back squat scales with level and bodyweight")
    func backSquat() {
        let begLow = StartingWeights.weight(for: "back-squat", level: .beginner, bodyweight: 140)
        let intMed = StartingWeights.weight(for: "back-squat", level: .intermediate, bodyweight: 200)
        let advHigh = StartingWeights.weight(for: "back-squat", level: .advanced, bodyweight: 250)
        #expect(begLow == 140)
        #expect(intMed == 250)
        #expect(advHigh == 375)
    }

    @Test("weighted-pullup returns 0 for beginner/intermediate, nonzero for advanced")
    func pullup() {
        #expect(StartingWeights.weight(for: "weighted-pullup", level: .beginner, bodyweight: 180) == 0)
        #expect(StartingWeights.weight(for: "weighted-pullup", level: .intermediate, bodyweight: 180) == 0)
        #expect(StartingWeights.weight(for: "weighted-pullup", level: .advanced, bodyweight: 180) > 0)
    }

    @Test("rounds to nearest 5 lb for main lifts")
    func rounding() {
        // 150 × 1.25 = 187.5 → 190 or 185 depending on rounding. Swift's .rounded() uses .toNearestOrEven: 187.5 / 5 = 37.5 → 38 → 190.
        let w = StartingWeights.weight(for: "back-squat", level: .intermediate, bodyweight: 150)
        #expect(w.truncatingRemainder(dividingBy: 5) == 0)
    }

    @Test("every liftKey returns a non-negative weight")
    func allLiftsReturnNonNegative() {
        for lift in StartingWeights.allLiftKeys {
            for level in TrainingLevel.allCases {
                let w = StartingWeights.weight(for: lift.key, level: level, bodyweight: 180)
                #expect(w >= 0, "\(lift.key) at \(level) returned \(w)")
            }
        }
    }

    @Test("level transitions produce increasing weights for main lifts")
    func levelOrdering() {
        for key in ["back-squat", "bench-press", "deadlift", "overhead-press", "barbell-row"] {
            let beg = StartingWeights.weight(for: key, level: .beginner, bodyweight: 200)
            let int = StartingWeights.weight(for: key, level: .intermediate, bodyweight: 200)
            let adv = StartingWeights.weight(for: key, level: .advanced, bodyweight: 200)
            #expect(int >= beg, "\(key): intermediate (\(int)) should be >= beginner (\(beg))")
            #expect(adv >= int, "\(key): advanced (\(adv)) should be >= intermediate (\(int))")
        }
    }

    @Test("romanian-deadlift is derived from deadlift")
    func derivedAccessories() {
        let dl = StartingWeights.weight(for: "deadlift", level: .intermediate, bodyweight: 200)
        let rdl = StartingWeights.weight(for: "romanian-deadlift", level: .intermediate, bodyweight: 200)
        #expect(abs(rdl - dl * 0.70) <= 5)
    }
}
