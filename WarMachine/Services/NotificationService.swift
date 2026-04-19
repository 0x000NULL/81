import Foundation
import UserNotifications
import OSLog

private let log = Logger(subsystem: "app.81", category: "notifications")

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private enum Identifier {
        static let morning = "81.reminder.morning"
        static let workout = "81.reminder.workout"
        static let evening = "81.reminder.evening"
        static let sabbath = "81.reminder.sabbath"
        static let deload  = "81.reminder.deload"
        static let rest    = "81.reminder.rest"
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func settings() async -> UNNotificationSettings {
        await center.notificationSettings()
    }

    // MARK: Recurring schedule

    func scheduleAllRecurring(morningHour: Int, morningMinute: Int,
                              workoutHour: Int,
                              eveningHour: Int, eveningMinute: Int) async {
        await scheduleMorning(hour: morningHour, minute: morningMinute)
        await scheduleWorkoutReminder(hour: workoutHour)
        await scheduleEveningReview(hour: eveningHour, minute: eveningMinute)
        await scheduleSabbathReview()
    }

    func scheduleMorning(hour: Int, minute: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Morning"
        content.body = "Verse, promise, and today's hard thing."
        content.sound = .default
        var comp = DateComponents()
        comp.hour = hour
        comp.minute = minute
        await replace(id: Identifier.morning, content: content, components: comp)
    }

    func scheduleWorkoutReminder(hour: Int) async {
        for weekday in TrainingSchedule.trainingWeekdays {
            let content = UNMutableNotificationContent()
            content.title = "Workout in 30"
            content.body = "Get the pack on. Go."
            content.sound = .default
            var comp = DateComponents()
            comp.hour = hour
            // iOS weekday: 1=Sun … 7=Sat. Our ISO 1=Mon … 7=Sun.
            comp.weekday = weekday == 7 ? 1 : weekday + 1
            let id = "\(Identifier.workout).\(weekday)"
            await replace(id: id, content: content, components: comp)
        }
    }

    func scheduleEveningReview(hour: Int, minute: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Evening review"
        content.body = "Three questions, then prayer."
        content.sound = .default
        var comp = DateComponents()
        comp.hour = hour
        comp.minute = minute
        await replace(id: Identifier.evening, content: content, components: comp)
    }

    func scheduleSabbathReview() async {
        let content = UNMutableNotificationContent()
        content.title = "Sabbath review"
        content.body = "Where did you see God this week?"
        content.sound = .default
        var comp = DateComponents()
        comp.hour = 18
        comp.minute = 0
        comp.weekday = 1 // Sunday
        await replace(id: Identifier.sabbath, content: content, components: comp)
    }

    func scheduleDeloadFlag(for weekStartingDate: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Deload week"
        content.body = "Cut working weights 40%. Same movements."
        content.sound = .default
        let comp = Calendar.current.dateComponents([.year, .month, .day, .hour], from: weekStartingDate)
        await replace(id: Identifier.deload, content: content, components: comp)
    }

    // MARK: Rest timer (one-shot)

    func scheduleRestTimer(duration: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Rest complete"
        content.body = "Next set."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(duration), repeats: false)
        let request = UNNotificationRequest(identifier: Identifier.rest, content: content, trigger: trigger)
        try await center.add(request)
    }

    func cancelRestTimer() async {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.rest])
    }

    // MARK: Cancel all

    func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: Helpers

    private func replace(id: String, content: UNNotificationContent, components: DateComponents) async {
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        do {
            try await center.add(request)
        } catch {
            log.error("Failed to schedule \(id): \(String(describing: error))")
        }
    }
}
