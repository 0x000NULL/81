import Testing
import Foundation
@testable import WarMachine

@Suite("TrainingPhases")
struct TrainingPhasesTests {

    @Test("week 1 is Accumulation Block 1")
    func weekOne() {
        #expect(TrainingPhases.phase(forWeek: 1).name == "Accumulation — Block 1")
    }

    @Test("week 6 is Deload")
    func weekSixIsDeload() {
        let p = TrainingPhases.phase(forWeek: 6)
        #expect(p.isDeload)
        #expect(p.name == "Deload")
    }

    @Test("week 12 is Deload + Final Baseline")
    func weekTwelve() {
        let p = TrainingPhases.phase(forWeek: 12)
        #expect(p.isDeload)
        #expect(p.name == "Deload + Final Baseline")
    }

    @Test("week 13 wraps back to Block 1 of next cycle")
    func weekThirteenWraps() {
        #expect(TrainingPhases.phase(forWeek: 13).name == "Accumulation — Block 1")
        #expect(TrainingPhases.normalizedWeek(13) == 1)
    }

    @Test("week 18 maps to Deload (week 6 of cycle 2)")
    func weekEighteen() {
        #expect(TrainingPhases.normalizedWeek(18) == 6)
        #expect(TrainingPhases.phase(forWeek: 18).isDeload)
    }

    @Test("baseline weeks are 4, 8, 12")
    func baselineWeeks() {
        #expect(TrainingPhases.baselineWeeks == [4, 8, 12])
    }

    @Test("normalizedWeek guards zero/negative")
    func normalizedZero() {
        #expect(TrainingPhases.normalizedWeek(0) == 1)
        #expect(TrainingPhases.normalizedWeek(-5) == 1)
    }
}
