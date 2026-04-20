import AppIntents
import Foundation
import SwiftData
import WidgetKit

struct LogGtgSetIntent: AppIntent {
    static var title: LocalizedStringResource = "Log GTG Set"
    static var description = IntentDescription(
        "Records a Greasing-the-Groove pull-up set to today's count."
    )
    static var openAppWhenRun: Bool = false

    @Parameter(
        title: "Reps",
        description: "Number of pull-ups in this set.",
        inclusiveRange: (1, 100)
    )
    var reps: Int

    init() {}

    init(reps: Int) {
        self.reps = reps
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        let context = ModelContext(AppModelContainer.shared.container)
        let result = try LogGtgSetIntent.logSet(reps: reps, in: context)

        GtgWidgetSnapshot(
            date: .now,
            count: result.totalReps,
            target: result.target
        ).save()
        WidgetCenter.shared.reloadAllTimelines()

        let dialog: IntentDialog = "Logged \(reps). \(result.totalReps) of \(result.target) today."
        return .result(value: result.totalReps, dialog: dialog)
    }

    struct SetResult: Equatable {
        let totalReps: Int
        let setsCompleted: Int
        let target: Int
    }

    @MainActor
    static func logSet(reps: Int, in context: ModelContext) throws -> SetResult {
        let log = GtgLogStore.findOrCreate(date: .now, in: context)
        log.totalReps += reps
        log.setsCompleted += 1
        try context.save()
        return SetResult(
            totalReps: log.totalReps,
            setsCompleted: log.setsCompleted,
            target: log.target
        )
    }
}
