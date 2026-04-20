import Testing
@testable import WarMachine

@Suite("LoggerClassification")
struct LoggerClassificationTests {

    @Test("every weekday spec classifies deterministically")
    func allSpecs() {
        let specs = Exercises.monday
            + Exercises.tuesday
            + Exercises.wednesday
            + Exercises.thursday
            + Exercises.friday
            + Exercises.saturdayRuck
        for spec in specs {
            let kind = LoggerClassification.kind(for: spec.key)
            #expect(kind == spec.loggerKind,
                    "\(spec.key) classified as \(kind); spec.loggerKind == \(spec.loggerKind)")
        }
    }

    @Test("carries + sled push are distanceLoad")
    func distanceLoadKeys() {
        #expect(LoggerClassification.kind(for: "farmers-carry") == .distanceLoad)
        #expect(LoggerClassification.kind(for: "suitcase-carry") == .distanceLoad)
        #expect(LoggerClassification.kind(for: "sled-push") == .distanceLoad)
    }

    @Test("side plank is durationHold")
    func holdKey() {
        #expect(LoggerClassification.kind(for: "side-plank") == .durationHold)
    }

    @Test("Tuesday interval block is cardioIntervals")
    func intervalKey() {
        #expect(LoggerClassification.kind(for: "interval-block") == .cardioIntervals)
    }

    @Test("Thursday block is cardioSession")
    func zone2Key() {
        #expect(LoggerClassification.kind(for: "zone2-block") == .cardioSession)
    }

    @Test("Saturday long ruck is ruck")
    func ruckKey() {
        #expect(LoggerClassification.kind(for: "long-ruck") == .ruck)
    }

    @Test("jump rope finisher is its own kind")
    func jumpRope() {
        #expect(LoggerClassification.kind(for: "jump-rope-finisher") == .jumpRopeFinisher)
    }

    @Test("ab wheel is bodyweightReps")
    func abWheel() {
        #expect(LoggerClassification.kind(for: "ab-wheel-rollout") == .bodyweightReps)
    }

    @Test("unknown key defaults to weightReps")
    func unknown() {
        #expect(LoggerClassification.kind(for: "this-key-does-not-exist") == .weightReps)
    }

    @Test("usesBarbell true for the seven barbell lifts")
    func barbells() {
        let yes = ["back-squat", "romanian-deadlift", "bench-press",
                   "overhead-press", "deadlift", "barbell-row", "barbell-curl"]
        for k in yes { #expect(LoggerClassification.usesBarbell(exerciseKey: k)) }
    }

    @Test("usesBarbell false for non-barbell movements")
    func nonBarbells() {
        let no = ["walking-lunge-db", "leg-press", "lateral-raise",
                  "farmers-carry", "sled-push", "side-plank", "long-ruck",
                  "weighted-dip", "hammer-curl"]
        for k in no { #expect(!LoggerClassification.usesBarbell(exerciseKey: k)) }
    }
}
