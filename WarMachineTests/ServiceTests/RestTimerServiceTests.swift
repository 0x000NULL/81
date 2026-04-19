import Testing
import Foundation
@testable import WarMachine

@Suite("RestTimerService", .serialized)
@MainActor
struct RestTimerServiceTests {
    @Test("skip clears state")
    func skipClears() async {
        let svc = RestTimerService.shared
        svc.skip()
        await svc.start(exerciseLogID: UUID(), setIndex: 0, duration: 60)
        #expect(svc.state != nil)
        svc.skip()
        #expect(svc.state == nil)
    }

    @Test("remaining seconds starts near duration")
    func elapsedTime() async {
        let svc = RestTimerService.shared
        svc.skip()
        await svc.start(exerciseLogID: UUID(), setIndex: 0, duration: 30)
        let initialRemaining = svc.remainingSeconds
        #expect(initialRemaining > 0)
        #expect(initialRemaining <= 30)
        svc.skip()
    }
}
