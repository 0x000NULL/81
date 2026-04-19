import Foundation
import Observation
import OSLog

private let log = Logger(subsystem: "app.81", category: "rest-timer")

@Observable
@MainActor
final class RestTimerService {
    static let shared = RestTimerService()

    struct TimerState: Codable {
        var exerciseLogID: UUID
        var setIndex: Int
        var startedAt: Date
        var durationSeconds: Int
    }

    private(set) var state: TimerState?

    var remainingSeconds: Int {
        guard let s = state else { return 0 }
        let elapsed = Date().timeIntervalSince(s.startedAt)
        return max(0, s.durationSeconds - Int(elapsed))
    }

    var isRunning: Bool { state != nil && remainingSeconds > 0 }

    func start(exerciseLogID: UUID, setIndex: Int, duration: Int) async {
        state = TimerState(exerciseLogID: exerciseLogID,
                           setIndex: setIndex,
                           startedAt: .now,
                           durationSeconds: duration)
        do {
            try await NotificationService.shared.scheduleRestTimer(duration: duration)
        } catch {
            log.error("Rest timer notification failed: \(String(describing: error))")
        }
    }

    func skip() {
        state = nil
        Task { await NotificationService.shared.cancelRestTimer() }
    }

    /// Called periodically by the UI to refresh.
    func tick() {
        if state != nil && remainingSeconds == 0 {
            state = nil
        }
    }
}
