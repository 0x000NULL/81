import SwiftUI
import SwiftData

/// Strong-style checkbox-per-set logger for `weightReps` and
/// `bodyweightReps`. Pre-renders rows for every target set plus any
/// bonus rows the user adds; each row is independently editable /
/// checkable / retaggable.
///
/// Delete + edit hit the `SetEditSheet` in `ExerciseCardView` via
/// `onRequestEdit` / `onRequestDelete` — the parent owns sheet state.
struct SetLoggerView: View {
    let exercise: ExerciseLog
    let spec: ExerciseSpec?
    let multiplier: Double
    let onCheckboxToggled: (SetLog, Bool) -> Void
    let onRequestEdit: (SetLog) -> Void
    let onRequestPlateCalculator: (Binding<Double>) -> Void

    @Environment(\.modelContext) private var context
    @Query private var sessions: [WorkoutSession]

    @State private var rows: [RowState] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            Divider().background(Theme.textSecondary.opacity(0.3))
            ForEach($rows) { $row in
                SetRow(
                    setNumber: row.setNumber,
                    sideLabel: nil,
                    isBonus: row.isBonus,
                    kinds: kindsForLogger,
                    hint: row.hint,
                    showPRBadge: row.showPRBadge,
                    usesBarbell: spec?.usesBarbell ?? false,
                    barbellLb: 45,
                    weightLb: $row.weightLb,
                    reps: $row.reps,
                    yards: .constant(0),
                    loadLb: .constant(0),
                    durationSec: .constant(0),
                    setType: $row.setType,
                    isChecked: $row.isChecked,
                    onToggleCheck: { checked in toggleCheck(rowID: row.id, checked: checked) },
                    onPrefillFromHint: { prefillFromHint(rowID: row.id) },
                    onEdit: { if let s = row.persistedSet { onRequestEdit(s) } },
                    onDelete: { deletePersistedSet(rowID: row.id) },
                    onSkip: { skip(rowID: row.id) },
                    onTapWeightLabel: {
                        onRequestPlateCalculator($row.weightLb)
                    }
                )
                Divider().background(Theme.textSecondary.opacity(0.15))
            }
            HStack {
                Button {
                    addBonusRow()
                } label: {
                    Label("Add set", systemImage: "plus.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.top, 4)
        }
        .onAppear { if rows.isEmpty { rebuildRows() } }
    }

    // MARK: - Row model

    private struct RowState: Identifiable {
        let id: UUID
        var setNumber: Int
        var isBonus: Bool
        var weightLb: Double
        var reps: Int
        var setType: SetType
        var isChecked: Bool
        var persistedSet: SetLog?
        var hint: LastSessionHint?
        var showPRBadge: Bool
    }

    private var kindsForLogger: SetRow.Kinds {
        exercise.loggerKind == .bodyweightReps ? .bodyweightReps : .weightReps
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Text("Set").frame(minWidth: 44, alignment: .leading)
            Text("Last session")
            Spacer()
            Text("Done")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Theme.textSecondary)
        .padding(.bottom, 2)
    }

    // MARK: - Row lifecycle

    private func rebuildRows() {
        let existing = (exercise.sets ?? []).sorted { $0.setIndex < $1.setIndex }
        var next: [RowState] = []
        let targetCount = max(exercise.targetSets, existing.count)
        for i in 0..<targetCount {
            let persisted: SetLog? = existing.first(where: { $0.setIndex == i })
            let isBonus = i >= exercise.targetSets
            let adjustedTarget = WeightRounding.round5(exercise.targetWeight * multiplier)
            let hint = LastSessionHintProvider.perSetHint(
                in: sessions,
                excluding: exercise.session?.id ?? UUID(),
                exerciseKey: exercise.exerciseKey,
                setIndex: i,
                kind: exercise.loggerKind
            )
            let defaultWeight = persisted?.weightLb ?? hint?.weightLb ?? adjustedTarget
            let defaultReps = persisted?.reps ?? hint?.reps ?? exercise.targetRepsMax
            next.append(RowState(
                id: UUID(),
                setNumber: i + 1,
                isBonus: isBonus,
                weightLb: defaultWeight,
                reps: defaultReps,
                setType: persisted?.setType ?? .normal,
                isChecked: persisted?.isCompleted ?? false,
                persistedSet: persisted,
                hint: hint,
                showPRBadge: !(persisted?.prKinds.isEmpty ?? true)
            ))
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
            row.showPRBadge = false
            rows[idx] = row
            onCheckboxToggled(set, false)
        }
    }

    private func persist(row: inout RowState) -> SetLog {
        if let existing = row.persistedSet {
            existing.weightLb = row.weightLb
            existing.reps = row.reps
            existing.setType = row.setType
            existing.isCompleted = true
            existing.completedAt = .now
            try? context.save()
            return existing
        }
        let set = SetLog(setIndex: row.setNumber - 1, weightLb: row.weightLb, reps: row.reps)
        set.setType = row.setType
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
              let hint = rows[idx].hint else { return }
        if let w = hint.weightLb { rows[idx].weightLb = w }
        if let r = hint.reps { rows[idx].reps = r }
    }

    private func deletePersistedSet(rowID: UUID) {
        guard let idx = rows.firstIndex(where: { $0.id == rowID }),
              let set = rows[idx].persistedSet else { return }
        context.delete(set)
        try? context.save()
        rows[idx].persistedSet = nil
        rows[idx].isChecked = false
        rows[idx].showPRBadge = false
    }

    private func skip(rowID: UUID) {
        guard let idx = rows.firstIndex(where: { $0.id == rowID }) else { return }
        // Persist as a zero-reps warmup so it stops blocking "all done"
        // checks but doesn't count anywhere.
        rows[idx].reps = 0
        rows[idx].setType = .warmup
        let _ = persist(row: &rows[idx])
        rows[idx].isChecked = true
    }

    private func addBonusRow() {
        let nextIndex = rows.count
        let last = rows.last
        let hint = LastSessionHintProvider.perSetHint(
            in: sessions,
            excluding: exercise.session?.id ?? UUID(),
            exerciseKey: exercise.exerciseKey,
            setIndex: nextIndex,
            kind: exercise.loggerKind
        )
        rows.append(RowState(
            id: UUID(),
            setNumber: nextIndex + 1,
            isBonus: true,
            weightLb: last?.weightLb ?? exercise.targetWeight * multiplier,
            reps: last?.reps ?? exercise.targetRepsMax,
            setType: .normal,
            isChecked: false,
            persistedSet: nil,
            hint: hint,
            showPRBadge: false
        ))
    }
}
