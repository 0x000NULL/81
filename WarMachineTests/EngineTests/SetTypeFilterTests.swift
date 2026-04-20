import Testing
@testable import WarMachine

@Suite("Progression set-type filter")
struct SetTypeFilterTests {

    private func makeSet(weight: Double, reps: Int, type: SetType) -> SetLog {
        let s = SetLog(setIndex: 0, weightLb: weight, reps: reps)
        s.setType = type
        return s
    }

    @Test("warmup sets are excluded from hitTopOfRange")
    func warmupsExcluded() {
        let sets = [
            makeSet(weight: 95,  reps: 5, type: .warmup),
            makeSet(weight: 185, reps: 6, type: .normal),
            makeSet(weight: 185, reps: 6, type: .normal),
            makeSet(weight: 185, reps: 6, type: .normal),
            makeSet(weight: 185, reps: 6, type: .normal)
        ]
        #expect(ProgressionEngine.hitTopOfRange(sets: sets, targetTopReps: 6))
    }

    @Test("drop sets are excluded from hitTopOfRange")
    func dropsExcluded() {
        let sets = [
            makeSet(weight: 185, reps: 6, type: .normal),
            makeSet(weight: 185, reps: 6, type: .normal),
            makeSet(weight: 135, reps: 2, type: .drop)      // low reps; would normally fail
        ]
        #expect(ProgressionEngine.hitTopOfRange(sets: sets, targetTopReps: 6))
    }

    @Test("failure set still counts and hits top")
    func failureCountsOnTop() {
        let sets = [
            makeSet(weight: 185, reps: 6, type: .normal),
            makeSet(weight: 185, reps: 6, type: .normal),
            makeSet(weight: 185, reps: 6, type: .failure)
        ]
        #expect(ProgressionEngine.hitTopOfRange(sets: sets, targetTopReps: 6))
    }

    @Test("failure set that misses top blocks progression")
    func failureBlocksWhenMissed() {
        let sets = [
            makeSet(weight: 185, reps: 6, type: .normal),
            makeSet(weight: 185, reps: 6, type: .normal),
            makeSet(weight: 185, reps: 4, type: .failure)
        ]
        #expect(ProgressionEngine.hitTopOfRange(sets: sets, targetTopReps: 6) == false)
    }

    @Test("all warmups → treated as empty")
    func allWarmups() {
        let sets = [
            makeSet(weight: 95, reps: 10, type: .warmup),
            makeSet(weight: 95, reps: 10, type: .warmup)
        ]
        #expect(ProgressionEngine.hitTopOfRange(sets: sets, targetTopReps: 6) == false)
    }

    @Test("SetType helpers flag tonnage/progression correctly")
    func typeHelpers() {
        #expect(SetType.warmup.countsTowardProgression == false)
        #expect(SetType.warmup.countsTowardTonnage == false)
        #expect(SetType.warmup.eligibleForPR == false)
        #expect(SetType.drop.countsTowardProgression == false)
        #expect(SetType.drop.countsTowardTonnage == true)
        #expect(SetType.drop.eligibleForPR == false)
        #expect(SetType.failure.countsTowardProgression)
        #expect(SetType.failure.eligibleForPR)
        #expect(SetType.normal.countsTowardProgression)
        #expect(SetType.normal.countsTowardTonnage)
    }
}
