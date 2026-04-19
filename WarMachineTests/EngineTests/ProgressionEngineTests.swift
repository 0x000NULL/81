import Testing
@testable import WarMachine

@Suite("ProgressionEngine")
struct ProgressionEngineTests {

    private func sets(reps: [Int]) -> [SetLog] {
        reps.enumerated().map { idx, r in SetLog(setIndex: idx, weightLb: 100, reps: r) }
    }

    @Test("main lift lower body → +10 when top hit")
    func mainLowerPlusTen() {
        let eval = ProgressionEngine.evaluate(
            liftKey: "back-squat",
            isMainLift: true,
            isLowerBody: true,
            currentWeight: 225,
            thisSessionSets: sets(reps: [6, 6, 6, 6]),
            targetTopReps: 6,
            priorConsecutiveTopSessions: 0
        )
        #expect(eval.shouldProgress)
        #expect(eval.suggestedNewWeight == 235)
    }

    @Test("main lift upper body → +5 when top hit")
    func mainUpperPlusFive() {
        let eval = ProgressionEngine.evaluate(
            liftKey: "bench-press",
            isMainLift: true,
            isLowerBody: false,
            currentWeight: 185,
            thisSessionSets: sets(reps: [6, 6, 6, 6]),
            targetTopReps: 6,
            priorConsecutiveTopSessions: 0
        )
        #expect(eval.shouldProgress)
        #expect(eval.suggestedNewWeight == 190)
    }

    @Test("accessory requires two top sessions")
    func accessoryTwoSession() {
        let oneTop = ProgressionEngine.evaluate(
            liftKey: "lateral-raise",
            isMainLift: false,
            isLowerBody: false,
            currentWeight: 15,
            thisSessionSets: sets(reps: [15, 15, 15]),
            targetTopReps: 15,
            priorConsecutiveTopSessions: 0
        )
        #expect(oneTop.shouldProgress == false)

        let twoTop = ProgressionEngine.evaluate(
            liftKey: "lateral-raise",
            isMainLift: false,
            isLowerBody: false,
            currentWeight: 15,
            thisSessionSets: sets(reps: [15, 15, 15]),
            targetTopReps: 15,
            priorConsecutiveTopSessions: 1
        )
        #expect(twoTop.shouldProgress)
        #expect(twoTop.suggestedNewWeight == 20)
    }

    @Test("not hitting top → no progression")
    func notHitTop() {
        let eval = ProgressionEngine.evaluate(
            liftKey: "back-squat",
            isMainLift: true,
            isLowerBody: true,
            currentWeight: 225,
            thisSessionSets: sets(reps: [6, 6, 5, 5]),
            targetTopReps: 6,
            priorConsecutiveTopSessions: 0
        )
        #expect(eval.shouldProgress == false)
    }

    @Test("ruck held comfortably → +0.5 mi")
    func ruckProgressionDistance() {
        let result = ProgressionEngine.evaluateRuck(
            currentMiles: 6,
            currentWeightLb: 35,
            completedDurationSeconds: 90 * 60,
            perceivedFelt: 5
        )
        if case .holdLoad(let newMiles) = result {
            #expect(newMiles == 6.5)
        } else {
            Issue.record("Expected holdLoad")
        }
    }

    @Test("ruck completed but hard → +2.5 lb weight")
    func ruckProgressionWeight() {
        let result = ProgressionEngine.evaluateRuck(
            currentMiles: 6,
            currentWeightLb: 35,
            completedDurationSeconds: 90 * 60,
            perceivedFelt: 8
        )
        if case .holdDistance(let newWeight) = result {
            #expect(newWeight == 37.5)
        } else {
            Issue.record("Expected holdDistance")
        }
    }
}
