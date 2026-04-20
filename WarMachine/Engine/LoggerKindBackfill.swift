import Foundation
import SwiftData
import OSLog

private let log = Logger(subsystem: "app.81", category: "backfill")

/// Reclassifies legacy `ExerciseLog` rows that migrated to SchemaV3 with
/// the default `loggerKindRaw = .weightReps`. Runs once at app start.
/// Idempotent: rows that already match their inferred kind are skipped.
enum LoggerKindBackfill {
    static func run(context: ModelContext) {
        let logs: [ExerciseLog]
        do {
            logs = try context.fetch(FetchDescriptor<ExerciseLog>())
        } catch {
            log.error("Backfill fetch failed: \(String(describing: error))")
            return
        }
        var touched = 0
        for row in logs {
            let inferred = LoggerClassification.kind(for: row.exerciseKey)
            if row.loggerKindRaw != inferred.rawValue {
                row.loggerKindRaw = inferred.rawValue
                touched += 1
            }
        }
        if touched > 0 {
            do {
                try context.save()
                log.info("LoggerKind backfill reclassified \(touched) ExerciseLog rows")
            } catch {
                log.error("Backfill save failed: \(String(describing: error))")
            }
        }
    }
}
