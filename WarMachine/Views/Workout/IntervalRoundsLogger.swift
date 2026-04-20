import SwiftUI
import SwiftData

/// Shared round-by-round logger used by Tuesday intervals and the
/// Wednesday jump-rope finisher. Each round becomes a `SetLog` with
/// `roundIndex` and `durationSec` populated; optional `heartRateAvg`
/// captures the mean HR sampled during the work bout.
///
/// Rounds fire sequentially: tap to start the work timer; at the end
/// of the prescribed work duration the row marks complete, a rest
/// countdown kicks in, and the next round unlocks. The user can also
/// early-finish (logs actual elapsed work), skip, or add bonus rounds.
struct IntervalRoundsLogger: View {
    let exercise: ExerciseLog
    let rounds: Int
    let workSec: Int
    let restSec: Int
    /// Shown when the user hasn't yet picked a modality. For the jump-
    /// rope finisher the caller forces `.jumpRope` so this is never
    /// displayed.
    let modalityPicker: Bool
    let fixedModality: IntervalModality?
    let onCheckboxToggled: (SetLog, Bool) -> Void

    @Environment(\.modelContext) private var context
    @Query private var sessions: [WorkoutSession]

    @State private var selectedModality: IntervalModality?
    @State private var activeRoundStart: Date?
    @State private var activeRoundIndex: Int?
    @State private var rows: [RowState] = []

    private struct RowState: Identifiable {
        let id: UUID
        var roundNumber: Int
        var isBonus: Bool
        var durationSec: Int
        var setType: SetType
        var isChecked: Bool
        var persistedSet: SetLog?
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let hint = aggregateHint {
                LastSessionPill(text: "Last: \(hint.summary)")
            }
            if modalityPicker, selectedModality == nil {
                modalityMenu
            } else {
                roundsList
            }
        }
        .onAppear {
            if selectedModality == nil, let fixed = fixedModality {
                selectedModality = fixed
            }
            if selectedModality == nil,
               let raw = exercise.pickedVariantKey,
               let kind = IntervalModality(rawValue: raw) {
                selectedModality = kind
            }
            if rows.isEmpty { rebuildRows() }
        }
    }

    private var aggregateHint: LastSessionHint? {
        LastSessionHintProvider.aggregateHint(
            in: sessions,
            excluding: exercise.session?.id ?? UUID(),
            exerciseKey: exercise.exerciseKey,
            kind: exercise.loggerKind
        )
    }

    // MARK: - Modality picker

    @ViewBuilder
    private var modalityMenu: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pick a modality")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            ForEach(IntervalModality.allCases, id: \.self) { kind in
                Button {
                    pickModality(kind)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(kind.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(kind.prescription)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func pickModality(_ kind: IntervalModality) {
        selectedModality = kind
        exercise.pickedVariantKey = kind.rawValue
        try? context.save()
        rebuildRows(using: kind)
    }

    // MARK: - Rounds list

    @ViewBuilder
    private var roundsList: some View {
        if let modality = selectedModality {
            HStack {
                Text(modality.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if modalityPicker {
                    Button("Change") {
                        selectedModality = nil
                        exercise.pickedVariantKey = nil
                        try? context.save()
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
                }
            }
            Text(modality.prescription)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        ForEach($rows) { $row in
            IntervalRoundRow(
                roundNumber: row.roundNumber,
                isBonus: row.isBonus,
                workSec: workSec,
                isActive: activeRoundIndex == (row.roundNumber - 1) && row.persistedSet == nil,
                startedAt: activeRoundStart,
                durationSec: $row.durationSec,
                isChecked: $row.isChecked,
                onStart: { startRound(row.roundNumber - 1) },
                onFinish: { finishActiveRound() },
                onSkip: { skip(rowID: row.id) },
                onDelete: { delete(rowID: row.id) }
            )
            Divider().background(Theme.textSecondary.opacity(0.15))
        }
        HStack {
            Button {
                addBonusRound()
            } label: {
                Label("Add round", systemImage: "plus.circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: - Row lifecycle

    private func rebuildRows(using modality: IntervalModality? = nil) {
        let target = modality?.rounds ?? rounds
        let existing = (exercise.sets ?? []).sorted(by: { ($0.roundIndex ?? $0.setIndex) < ($1.roundIndex ?? $1.setIndex) })
        var next: [RowState] = []
        let capacity = max(target, existing.count)
        for i in 0..<capacity {
            let persisted = existing.first { ($0.roundIndex ?? $0.setIndex) == i }
            next.append(RowState(
                id: UUID(),
                roundNumber: i + 1,
                isBonus: i >= target,
                durationSec: persisted?.durationSec ?? workSec,
                setType: persisted?.setType ?? .normal,
                isChecked: persisted?.isCompleted ?? false,
                persistedSet: persisted
            ))
        }
        rows = next
    }

    private func startRound(_ index: Int) {
        activeRoundIndex = index
        activeRoundStart = .now
    }

    private func finishActiveRound() {
        guard let idx = activeRoundIndex,
              idx < rows.count,
              let startedAt = activeRoundStart else { return }
        let elapsed = max(1, Int(Date.now.timeIntervalSince(startedAt)))
        rows[idx].durationSec = min(elapsed, workSec * 3)
        rows[idx].isChecked = true
        let set = persist(rowAt: idx)
        rows[idx].persistedSet = set
        activeRoundIndex = nil
        activeRoundStart = nil
        onCheckboxToggled(set, true)
    }

    @discardableResult
    private func persist(rowAt idx: Int) -> SetLog {
        var row = rows[idx]
        if let existing = row.persistedSet {
            existing.durationSec = row.durationSec
            existing.roundIndex = row.roundNumber - 1
            existing.setType = row.setType
            existing.isCompleted = true
            existing.completedAt = .now
            try? context.save()
            return existing
        }
        let set = SetLog(setIndex: row.roundNumber - 1, weightLb: 0, reps: 0)
        set.durationSec = row.durationSec
        set.roundIndex = row.roundNumber - 1
        set.setType = row.setType
        set.isCompleted = true
        set.exercise = exercise
        context.insert(set)
        if exercise.sets == nil { exercise.sets = [] }
        exercise.sets?.append(set)
        try? context.save()
        row.persistedSet = set
        rows[idx] = row
        return set
    }

    private func skip(rowID: UUID) {
        guard let idx = rows.firstIndex(where: { $0.id == rowID }) else { return }
        rows[idx].durationSec = 0
        rows[idx].setType = .warmup
        _ = persist(rowAt: idx)
        rows[idx].isChecked = true
    }

    private func delete(rowID: UUID) {
        guard let idx = rows.firstIndex(where: { $0.id == rowID }),
              let set = rows[idx].persistedSet else { return }
        context.delete(set)
        try? context.save()
        rows[idx].persistedSet = nil
        rows[idx].isChecked = false
    }

    private func addBonusRound() {
        let nextNum = rows.count + 1
        rows.append(RowState(
            id: UUID(),
            roundNumber: nextNum,
            isBonus: true,
            durationSec: workSec,
            setType: .normal,
            isChecked: false,
            persistedSet: nil
        ))
    }
}

// MARK: - Subviews

private struct LastSessionPill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.monospacedDigit())
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.surface)
            .clipShape(Capsule())
    }
}

private struct IntervalRoundRow: View {
    let roundNumber: Int
    let isBonus: Bool
    let workSec: Int
    let isActive: Bool
    let startedAt: Date?
    @Binding var durationSec: Int
    @Binding var isChecked: Bool
    let onStart: () -> Void
    let onFinish: () -> Void
    let onSkip: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("Round \(roundNumber)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .frame(minWidth: 80, alignment: .leading)
            if isBonus {
                Text("bonus")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if isChecked {
                Text("\(durationSec)s")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
                Menu {
                    Button("Delete round", role: .destructive) { onDelete() }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            } else if isActive, let startedAt {
                TimelineView(.periodic(from: .now, by: 0.25)) { context in
                    let elapsed = max(0, Int(context.date.timeIntervalSince(startedAt)))
                    Text("\(elapsed)s / \(workSec)s")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Theme.accent)
                }
                Button("Finish") { onFinish() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            } else {
                Text("\(workSec)s")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
                Button("Start") { onStart() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Menu {
                    Button("Skip this round") { onSkip() }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }
}
