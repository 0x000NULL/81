import SwiftUI
import SwiftData

/// Timed-hold logger (side plank, dead hang, hollow hold). One row per
/// side per target set — e.g. 3 × 30s each side = 6 rows labeled L/R.
/// Each row captures a single `durationSec` value; the default is the
/// spec target (stored on `ExerciseLog.targetRepsMin` as seconds).
struct DurationHoldLogger: View {
    let exercise: ExerciseLog
    let spec: ExerciseSpec?
    let onCheckboxToggled: (SetLog, Bool) -> Void
    let onRequestEdit: (SetLog) -> Void

    @Environment(\.modelContext) private var context
    @Query private var sessions: [WorkoutSession]

    @State private var rows: [RowState] = []

    private struct RowState: Identifiable {
        let id: UUID
        var setNumber: Int
        var sideLabel: String?      // "L" / "R" — nil for single-sided holds
        var isBonus: Bool
        var durationSec: Int
        var setType: SetType
        var isChecked: Bool
        var persistedSet: SetLog?
        var hint: LastSessionHint?
        var roundIndex: Int?
        var rpe: Double?
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            Divider().background(Theme.textSecondary.opacity(0.3))
            ForEach($rows) { $row in
                SetRow(
                    setNumber: row.setNumber,
                    sideLabel: row.sideLabel,
                    isBonus: row.isBonus,
                    kinds: [.duration],
                    hint: row.hint,
                    showPRBadge: !(row.persistedSet?.prKinds.isEmpty ?? true),
                    usesBarbell: false,
                    barbellLb: 45,
                    weightLb: .constant(0),
                    reps: .constant(0),
                    yards: .constant(0),
                    loadLb: .constant(0),
                    durationSec: $row.durationSec,
                    setType: $row.setType,
                    isChecked: $row.isChecked,
                    onToggleCheck: { checked in toggleCheck(rowID: row.id, checked: checked) },
                    onPrefillFromHint: { prefillFromHint(rowID: row.id) },
                    onEdit: { if let s = row.persistedSet { onRequestEdit(s) } },
                    onDelete: { deletePersistedSet(rowID: row.id) },
                    onSkip: { skip(rowID: row.id) },
                    rpe: $row.rpe
                )
                Divider().background(Theme.textSecondary.opacity(0.15))
            }
        }
        .onAppear { if rows.isEmpty { rebuildRows() } }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Set").frame(minWidth: 44, alignment: .leading)
            Text("Last session")
            Spacer()
            Text("Done")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Theme.textSecondary)
    }

    private var perSide: Bool {
        exercise.exerciseKey == "side-plank"
    }

    private var defaultSec: Int {
        // ExerciseSpec encodes seconds into targetRepsMin/Max for holds.
        max(exercise.targetRepsMin, 10)
    }

    private func rebuildRows() {
        let existing = (exercise.sets ?? []).sorted(by: { ($0.setIndex, $0.roundIndex ?? 0) < ($1.setIndex, $1.roundIndex ?? 0) })
        var next: [RowState] = []
        let baseRows = exercise.targetSets
        let rowsPerSet = perSide ? 2 : 1

        for setI in 0..<baseRows {
            for r in 0..<rowsPerSet {
                let persisted = existing.first { s in
                    s.setIndex == setI && (s.roundIndex ?? 0) == (perSide ? r : 0)
                }
                let hint = LastSessionHintProvider.perSetHint(
                    in: sessions,
                    excluding: exercise.session?.id ?? UUID(),
                    exerciseKey: exercise.exerciseKey,
                    setIndex: setI * rowsPerSet + r,
                    kind: .durationHold
                )
                next.append(RowState(
                    id: UUID(),
                    setNumber: setI + 1,
                    sideLabel: perSide ? (r == 0 ? "L" : "R") : nil,
                    isBonus: false,
                    durationSec: persisted?.durationSec ?? hint?.durationSec ?? defaultSec,
                    setType: persisted?.setType ?? .normal,
                    isChecked: persisted?.isCompleted ?? false,
                    persistedSet: persisted,
                    hint: hint,
                    roundIndex: perSide ? r : nil,
                    rpe: persisted?.rpe
                ))
            }
        }
        rows = next
    }

    private func toggleCheck(rowID: UUID, checked: Bool) {
        guard let idx = rows.firstIndex(where: { $0.id == rowID }) else { return }
        var row = rows[idx]
        if checked {
            let set = persist(row: &row)
            row.persistedSet = set
            rows[idx] = row
            onCheckboxToggled(set, true)
        } else if let set = row.persistedSet {
            context.delete(set)
            try? context.save()
            row.persistedSet = nil
            rows[idx] = row
            onCheckboxToggled(set, false)
        }
    }

    private func persist(row: inout RowState) -> SetLog {
        if let existing = row.persistedSet {
            existing.durationSec = row.durationSec
            existing.setType = row.setType
            existing.rpe = row.rpe
            existing.isCompleted = true
            existing.completedAt = .now
            try? context.save()
            return existing
        }
        let set = SetLog(setIndex: row.setNumber - 1, weightLb: 0, reps: 0)
        set.durationSec = row.durationSec
        set.roundIndex = row.roundIndex
        set.setType = row.setType
        set.rpe = row.rpe
        set.isCompleted = true
        set.exercise = exercise
        context.insert(set)
        if exercise.sets == nil { exercise.sets = [] }
        exercise.sets?.append(set)
        try? context.save()
        return set
    }

    private func prefillFromHint(rowID: UUID) {
        guard let idx = rows.firstIndex(where: { $0.id == rowID }),
              let s = rows[idx].hint?.durationSec else { return }
        rows[idx].durationSec = s
    }

    private func deletePersistedSet(rowID: UUID) {
        guard let idx = rows.firstIndex(where: { $0.id == rowID }),
              let set = rows[idx].persistedSet else { return }
        context.delete(set)
        try? context.save()
        rows[idx].persistedSet = nil
        rows[idx].isChecked = false
    }

    private func skip(rowID: UUID) {
        guard let idx = rows.firstIndex(where: { $0.id == rowID }) else { return }
        rows[idx].durationSec = 0
        rows[idx].setType = .warmup
        _ = persist(row: &rows[idx])
        rows[idx].isChecked = true
    }
}
