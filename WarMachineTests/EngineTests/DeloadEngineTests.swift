import Testing
@testable import WarMachine

@Suite("DeloadEngine")
struct DeloadEngineTests {
    @Test("deload weeks are 6 and 12")
    func detection() {
        #expect(DeloadEngine.isDeloadWeek(6))
        #expect(DeloadEngine.isDeloadWeek(12))
        #expect(!DeloadEngine.isDeloadWeek(5))
    }

    @Test("deload multiplier is 0.60 (40% reduction)")
    func multiplier() {
        let m = DeloadEngine.weightMultiplier(weekNumber: 6, rebuildModeActive: false, returnRestartPercent: nil)
        #expect(m == 0.60)
    }

    @Test("rebuild mode trumps normal week")
    func rebuildTrumps() {
        let m = DeloadEngine.weightMultiplier(weekNumber: 3, rebuildModeActive: true, returnRestartPercent: nil)
        #expect(m == 0.80)
    }

    @Test("return restart percent trumps both")
    func restartTrumps() {
        let m = DeloadEngine.weightMultiplier(weekNumber: 6, rebuildModeActive: true, returnRestartPercent: 0.70)
        #expect(m == 0.70)
    }

    @Test("normal week is 1.0")
    func normalWeek() {
        let m = DeloadEngine.weightMultiplier(weekNumber: 3, rebuildModeActive: false, returnRestartPercent: nil)
        #expect(m == 1.0)
    }
}
