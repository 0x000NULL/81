import Foundation

/// Classifies every `ExerciseSpec` by logger kind and bar usage via
/// `LoggerClassification`. Done as computed properties rather than stored
/// fields to avoid touching all ~30 spec instantiations in `Exercises.swift`.
extension ExerciseSpec {
    var loggerKind: LoggerKind {
        LoggerClassification.kind(for: key)
    }

    var usesBarbell: Bool {
        LoggerClassification.usesBarbell(exerciseKey: key)
    }
}
