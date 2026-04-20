import Testing
@testable import WarMachine

@Suite("PlateCalculator")
struct PlateCalculatorTests {

    @Test("empty bar (target == bar) → no plates")
    func emptyBar() {
        let r = PlateCalculator.compute(targetLb: 45, barLb: 45)
        #expect(r.perSide.isEmpty)
        #expect(r.exact)
    }

    @Test("95 lb with 45 bar → one 25 per side")
    func ninetyFive() {
        let r = PlateCalculator.compute(targetLb: 95, barLb: 45)
        #expect(r.perSide == [25])
        #expect(r.exact)
        #expect(r.achievedLb == 95)
    }

    @Test("225 lb with defaults → 45+25+20 per side — but 20 isn't in default set")
    func twoTwentyFive() {
        // Default plates lack a 20 lb, so expected per-side is [45, 25, 10, 10].
        let r = PlateCalculator.compute(targetLb: 225, barLb: 45)
        #expect(r.perSide == [45, 25, 10, 10])
        #expect(r.exact)
        #expect(r.achievedLb == 225)
    }

    @Test("100 lb with defaults is not exact; below=95, above=105")
    func inexact() {
        let r = PlateCalculator.compute(targetLb: 100, barLb: 45)
        #expect(!r.exact)
        #expect(r.achievedLb == 95)
        #expect(r.nearestBelow == 95)
        #expect(r.nearestAbove == 100)  // 45 + 2 × 2.5 = 50
    }

    @Test("women's 35 lb bar, target 135 → 45+5 per side")
    func womensBar() {
        let r = PlateCalculator.compute(targetLb: 135, barLb: 35)
        #expect(r.perSide == [45, 5])
        #expect(r.exact)
    }

    @Test("target below bar stays below bar")
    func belowBar() {
        let r = PlateCalculator.compute(targetLb: 40, barLb: 45)
        #expect(r.perSide.isEmpty)
        #expect(r.achievedLb == 40)
    }

    @Test("reduced plate set — only 45s and 25s")
    func reducedSet() {
        let r = PlateCalculator.compute(targetLb: 135, barLb: 45, plates: [45, 25])
        #expect(r.perSide == [45])
        #expect(r.exact)
    }
}
