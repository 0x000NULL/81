import Testing
@testable import WarMachine

@Suite("PRDetector")
struct PRDetectorTests {

    @Test("Epley 1RM: 1 rep == weight")
    func epley1Rep() {
        #expect(PRDetector.estimated1RM(weightLb: 225, reps: 1) == 225)
    }

    @Test("Epley 1RM: 5 reps at 185 = ~215.8")
    func epley5Rep() {
        let est = PRDetector.estimated1RM(weightLb: 185, reps: 5)
        #expect(abs(est - 215.833) < 0.01)
    }

    @Test("Epley 1RM: 10 reps at 135 = 180")
    func epley10Rep() {
        let est = PRDetector.estimated1RM(weightLb: 135, reps: 10)
        #expect(abs(est - 180) < 0.01)
    }

    @Test("first-ever weightReps set hits all three PR kinds")
    func firstEverSet() {
        let input = PRDetector.Input(
            exerciseKey: "bench-press",
            loggerKind: .weightReps,
            setType: .normal,
            weightLb: 135, reps: 8,
            durationSec: nil, distanceYards: nil, distanceMiles: nil, loadLb: nil
        )
        let out = PRDetector.detect(
            input,
            priorEstimated1RM: nil,
            priorSetVolume: nil,
            priorRepsAtWeight: [:],
            priorHoldSec: nil,
            priorCarryYardsAtLoad: [:],
            priorRuckMilesAtLoad: [:]
        )
        #expect(out.kinds.contains(.estimated1RM))
        #expect(out.kinds.contains(.volume))
        #expect(out.kinds.contains(.repsAtWeight))
    }

    @Test("tie on all kinds → no PR")
    func tieNoPR() {
        let input = PRDetector.Input(
            exerciseKey: "bench-press",
            loggerKind: .weightReps,
            setType: .normal,
            weightLb: 135, reps: 8,
            durationSec: nil, distanceYards: nil, distanceMiles: nil, loadLb: nil
        )
        let out = PRDetector.detect(
            input,
            priorEstimated1RM: 171,  // 135 * (1 + 8/30) == 171
            priorSetVolume: 1080,    // 135 * 8
            priorRepsAtWeight: [135: 8],
            priorHoldSec: nil,
            priorCarryYardsAtLoad: [:],
            priorRuckMilesAtLoad: [:]
        )
        #expect(out.kinds.isEmpty)
    }

    @Test("warmup set never produces PR")
    func warmupBlocked() {
        let input = PRDetector.Input(
            exerciseKey: "bench-press",
            loggerKind: .weightReps,
            setType: .warmup,
            weightLb: 500, reps: 10,
            durationSec: nil, distanceYards: nil, distanceMiles: nil, loadLb: nil
        )
        let out = PRDetector.detect(input,
            priorEstimated1RM: 0, priorSetVolume: 0,
            priorRepsAtWeight: [:], priorHoldSec: nil,
            priorCarryYardsAtLoad: [:], priorRuckMilesAtLoad: [:])
        #expect(out.kinds.isEmpty)
    }

    @Test("drop set never produces PR")
    func dropBlocked() {
        let input = PRDetector.Input(
            exerciseKey: "bench-press",
            loggerKind: .weightReps,
            setType: .drop,
            weightLb: 500, reps: 10,
            durationSec: nil, distanceYards: nil, distanceMiles: nil, loadLb: nil
        )
        let out = PRDetector.detect(input,
            priorEstimated1RM: 0, priorSetVolume: 0,
            priorRepsAtWeight: [:], priorHoldSec: nil,
            priorCarryYardsAtLoad: [:], priorRuckMilesAtLoad: [:])
        #expect(out.kinds.isEmpty)
    }

    @Test("failure set DOES count for PR")
    func failureCounts() {
        let input = PRDetector.Input(
            exerciseKey: "bench-press",
            loggerKind: .weightReps,
            setType: .failure,
            weightLb: 225, reps: 3,
            durationSec: nil, distanceYards: nil, distanceMiles: nil, loadLb: nil
        )
        let out = PRDetector.detect(input,
            priorEstimated1RM: 0, priorSetVolume: 0,
            priorRepsAtWeight: [:], priorHoldSec: nil,
            priorCarryYardsAtLoad: [:], priorRuckMilesAtLoad: [:])
        #expect(!out.kinds.isEmpty)
    }

    @Test("longer hold → longestHoldSec PR")
    func holdPR() {
        let input = PRDetector.Input(
            exerciseKey: "side-plank",
            loggerKind: .durationHold,
            setType: .normal,
            weightLb: nil, reps: nil,
            durationSec: 60, distanceYards: nil, distanceMiles: nil, loadLb: nil
        )
        let out = PRDetector.detect(input,
            priorEstimated1RM: nil, priorSetVolume: nil,
            priorRepsAtWeight: [:], priorHoldSec: 45,
            priorCarryYardsAtLoad: [:], priorRuckMilesAtLoad: [:])
        #expect(out.kinds == [.longestHoldSec])
        #expect(out.updatedHoldSec == 60)
    }

    @Test("further carry at same load → furthestCarryAtLoad PR")
    func carryPR() {
        let input = PRDetector.Input(
            exerciseKey: "farmers-carry",
            loggerKind: .distanceLoad,
            setType: .normal,
            weightLb: nil, reps: nil,
            durationSec: nil, distanceYards: 50,
            distanceMiles: nil, loadLb: 100
        )
        let out = PRDetector.detect(input,
            priorEstimated1RM: nil, priorSetVolume: nil,
            priorRepsAtWeight: [:], priorHoldSec: nil,
            priorCarryYardsAtLoad: [100: 40], priorRuckMilesAtLoad: [:])
        #expect(out.kinds == [.furthestCarryAtLoad])
    }

    @Test("cardio session never produces PR")
    func cardioNoPR() {
        let input = PRDetector.Input(
            exerciseKey: "zone2-block",
            loggerKind: .cardioSession,
            setType: .normal,
            weightLb: nil, reps: nil,
            durationSec: 60 * 60, distanceYards: nil,
            distanceMiles: 5.0, loadLb: nil
        )
        let out = PRDetector.detect(input,
            priorEstimated1RM: nil, priorSetVolume: nil,
            priorRepsAtWeight: [:], priorHoldSec: nil,
            priorCarryYardsAtLoad: [:], priorRuckMilesAtLoad: [:])
        #expect(out.kinds.isEmpty)
    }
}
