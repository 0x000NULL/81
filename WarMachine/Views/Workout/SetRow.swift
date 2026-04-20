import SwiftUI
import SwiftData

/// A single row in a checkbox-per-set logger. Works for `weightReps`,
/// `bodyweightReps`, `distanceLoad`, and `durationHold`. The caller is
/// responsible for seeding initial inputs and for persisting via
/// `onToggleCheck`.
///
/// The row is stateless with respect to persistence — if `persisted` is
/// nil, the row is "pending" (user can edit inputs). If non-nil, the row
/// renders compactly and edits are disabled until unchecked.
struct SetRow: View {
    struct Kinds: OptionSet {
        let rawValue: Int
        static let weight     = Kinds(rawValue: 1 << 0)
        static let reps       = Kinds(rawValue: 1 << 1)
        static let yards      = Kinds(rawValue: 1 << 2)
        static let load       = Kinds(rawValue: 1 << 3)
        static let duration   = Kinds(rawValue: 1 << 4)
        static let sideChip   = Kinds(rawValue: 1 << 5)  // L/R label for per-side holds

        static let weightReps: Kinds     = [.weight, .reps]
        static let bodyweightReps: Kinds = [.reps]
        static let distanceLoad: Kinds   = [.yards, .load]
        static let durationHold: Kinds   = [.duration, .sideChip]
    }

    let setNumber: Int          // 1-based display number
    let sideLabel: String?      // "L" / "R" for hold rows; nil otherwise
    let isBonus: Bool
    let kinds: Kinds
    let hint: LastSessionHint?
    let showPRBadge: Bool
    let usesBarbell: Bool
    let barbellLb: Double

    @Binding var weightLb: Double
    @Binding var reps: Int
    @Binding var yards: Int
    @Binding var loadLb: Double
    @Binding var durationSec: Int
    @Binding var setType: SetType
    @Binding var isChecked: Bool

    let onToggleCheck: (Bool) -> Void
    let onPrefillFromHint: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSkip: () -> Void

    @State private var showingPlateCalc = false
    @State private var showingRPEInput = false
    @Binding var rpe: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            topRow
            if !isChecked {
                inputsRow
                if showingRPEInput {
                    rpeRow
                }
            }
        }
        .padding(.vertical, 6)
        .opacity(setType == .warmup && isChecked ? 0.55 : 1.0)
        .sheet(isPresented: $showingPlateCalc) {
            PlateCalculatorSheet(targetLb: $weightLb)
                .preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    private var rpeRow: some View {
        HStack(spacing: 12) {
            Text("RPE")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            Slider(
                value: Binding(
                    get: { rpe ?? 7 },
                    set: { rpe = $0 }
                ),
                in: 1...10,
                step: 0.5
            )
            .tint(Theme.accent)
            Text(rpe.map { String(format: "%.1f", $0) } ?? "—")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 32, alignment: .trailing)
        }
    }

    @ViewBuilder
    private var topRow: some View {
        HStack(spacing: 12) {
            setChip
            if isChecked {
                Text(completedText)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
                if showPRBadge {
                    PRPill()
                }
                Spacer()
            } else {
                if let hint {
                    Button(action: onPrefillFromHint) {
                        Text("Last: \(hint.summary)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                if kinds.contains(.weight) || kinds.contains(.reps) {
                    Button {
                        showingRPEInput.toggle()
                    } label: {
                        Image(systemName: showingRPEInput ? "gauge.with.needle.fill" : "gauge.with.needle")
                            .foregroundStyle(showingRPEInput ? Theme.accent : Theme.textSecondary)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(showingRPEInput ? "Hide RPE" : "Add RPE")
                }
            }
            checkbox
            SetTypeMenu(
                setType: $setType,
                isPersisted: isChecked,
                onEdit: onEdit,
                onDelete: onDelete,
                onSkip: onSkip
            )
        }
    }

    @ViewBuilder
    private var inputsRow: some View {
        HStack(spacing: 16) {
            if kinds.contains(.weight) {
                VStack(alignment: .leading, spacing: 4) {
                    Button {
                        if usesBarbell { showingPlateCalc = true }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Weight")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                            if usesBarbell {
                                Image(systemName: "square.stack.3d.up")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(usesBarbell ? "Weight (tap for plate calculator)" : "Weight")
                    NumberStepper(value: $weightLb, step: 5, range: 0...1000)
                }
            }
            if kinds.contains(.reps) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    IntegerStepper(value: $reps, range: 0...200)
                }
            }
            if kinds.contains(.yards) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Yards")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    IntegerStepper(value: $yards, range: 0...500, step: 5)
                }
            }
            if kinds.contains(.load) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Load")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    NumberStepper(value: $loadLb, step: 5, range: 0...500)
                }
            }
            if kinds.contains(.duration) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hold")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    IntegerStepper(value: $durationSec, range: 0...600, step: 5)
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var setChip: some View {
        HStack(spacing: 4) {
            if let sym = setType.systemImage, setType != .normal {
                Image(systemName: sym)
                    .font(.caption)
                    .foregroundStyle(setType == .warmup ? Theme.textSecondary : Theme.accent)
            }
            Text("\(setNumber)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            if let sideLabel {
                Text(sideLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            if isBonus {
                Text("bonus")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(minWidth: 44, alignment: .leading)
    }

    @ViewBuilder
    private var checkbox: some View {
        Button {
            let next = !isChecked
            isChecked = next
            onToggleCheck(next)
        } label: {
            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                .font(.title2)
                .foregroundStyle(isChecked ? Theme.accent : Theme.textSecondary)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isChecked ? "Uncheck set \(setNumber)" : "Check set \(setNumber)")
    }

    private var completedText: String {
        var parts: [String] = []
        if kinds.contains(.weight) { parts.append("\(Int(weightLb)) lb") }
        if kinds.contains(.reps)   { parts.append("× \(reps)") }
        if kinds.contains(.yards)  { parts.append("\(yards)y") }
        if kinds.contains(.load)   { parts.append("@ \(Int(loadLb)) lb") }
        if kinds.contains(.duration) { parts.append("\(durationSec)s") }
        if let sideLabel, kinds.contains(.sideChip) {
            parts.insert(sideLabel, at: 0)
        }
        return parts.joined(separator: " ")
    }
}

private struct PRPill: View {
    var body: some View {
        Text("PR")
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Theme.accent)
            .foregroundStyle(Theme.bg)
            .clipShape(Capsule())
    }
}
