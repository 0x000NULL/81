import SwiftUI
import SwiftData

/// Wednesday jump-rope finisher. Fixed modality (jump rope), fixed
/// prescription (10 × 30s on / 30s off). No picker; just the rounds
/// grid with per-round timers.
struct JumpRopeFinisherLogger: View {
    let exercise: ExerciseLog
    let spec: ExerciseSpec?
    let onCheckboxToggled: (SetLog, Bool) -> Void

    var body: some View {
        IntervalRoundsLogger(
            exercise: exercise,
            rounds: 10,
            workSec: 30,
            restSec: 30,
            modalityPicker: false,
            fixedModality: .jumpRope,
            onCheckboxToggled: onCheckboxToggled
        )
    }
}
