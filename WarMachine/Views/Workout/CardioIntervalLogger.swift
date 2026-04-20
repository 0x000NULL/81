import SwiftUI
import SwiftData

/// Tuesday interval block. Thin wrapper over `IntervalRoundsLogger` that
/// surfaces the modality picker (user chooses track 400s / hill sprints
/// / rower / etc.) and adapts the round count / work & rest durations
/// to the chosen modality.
struct CardioIntervalLogger: View {
    let exercise: ExerciseLog
    let spec: ExerciseSpec?
    let onCheckboxToggled: (SetLog, Bool) -> Void

    var body: some View {
        // If the user has already picked a modality, honor its prescription;
        // otherwise fall back to the spec defaults so the caller can still
        // render sensibly before a pick.
        let modality = exercise.pickedVariantKey.flatMap(IntervalModality.init(rawValue:))
        let rounds = modality?.rounds ?? max(1, exercise.targetSets)
        let workSec = modality?.workSec ?? 60
        let restSec = modality?.restSec ?? 30
        IntervalRoundsLogger(
            exercise: exercise,
            rounds: rounds,
            workSec: workSec,
            restSec: restSec,
            modalityPicker: true,
            fixedModality: nil,
            onCheckboxToggled: onCheckboxToggled
        )
    }
}
