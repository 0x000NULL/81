import Testing
import HealthKit
@testable import WarMachine

@Suite("IntervalModality")
struct IntervalModalityTests {

    @Test("track 400s maps to running")
    func trackMapsRunning() {
        #expect(IntervalModality.track400s.hkActivityType == .running)
        #expect(IntervalModality.hillSprints.hkActivityType == .running)
        #expect(IntervalModality.treadmill.hkActivityType == .running)
    }

    @Test("rower and bike map to rowing / cycling")
    func rowBike() {
        #expect(IntervalModality.rower.hkActivityType == .rowing)
        #expect(IntervalModality.assaultBike.hkActivityType == .cycling)
    }

    @Test("swim maps to swimming")
    func swim() {
        #expect(IntervalModality.swim.hkActivityType == .swimming)
    }

    @Test("burpees map to HIIT")
    func hiit() {
        #expect(IntervalModality.bodyweightBurpees.hkActivityType == .highIntensityIntervalTraining)
    }

    @Test("rounds / work / rest values are consistent")
    func roundsConsistent() {
        for kind in IntervalModality.allCases {
            #expect(kind.rounds > 0, "\(kind) must have positive rounds")
            #expect(kind.workSec > 0, "\(kind) must have positive workSec")
            #expect(kind.restSec >= 0, "\(kind) must have non-negative restSec")
        }
    }

    @Test("all cases have a non-empty label and prescription")
    func labels() {
        for kind in IntervalModality.allCases {
            #expect(!kind.label.isEmpty)
            #expect(!kind.prescription.isEmpty)
        }
    }
}
