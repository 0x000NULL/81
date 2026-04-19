import SwiftUI

struct NumberStepper: View {
    @Binding var value: Double
    let step: Double
    let range: ClosedRange<Double>
    let formatter: (Double) -> String

    init(value: Binding<Double>,
         step: Double = 5,
         range: ClosedRange<Double> = 0...9999,
         formatter: @escaping (Double) -> String = { Format.weight($0) }) {
        self._value = value
        self.step = step
        self.range = range
        self.formatter = formatter
    }

    var body: some View {
        HStack(spacing: 16) {
            Button {
                value = max(range.lowerBound, value - step)
            } label: {
                Image(systemName: "minus")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
            .accessibilityLabel("Decrease")

            Text(formatter(value))
                .font(.title3.monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
                .frame(minWidth: 80)

            Button {
                value = min(range.upperBound, value + step)
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
            .accessibilityLabel("Increase")
        }
    }
}

struct IntegerStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    init(value: Binding<Int>, range: ClosedRange<Int> = 0...9999, step: Int = 1) {
        self._value = value
        self.range = range
        self.step = step
    }

    var body: some View {
        HStack(spacing: 16) {
            Button {
                value = max(range.lowerBound, value - step)
            } label: {
                Image(systemName: "minus")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
            .accessibilityLabel("Decrease")

            Text("\(value)")
                .font(.title3.monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
                .frame(minWidth: 60)

            Button {
                value = min(range.upperBound, value + step)
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
            .accessibilityLabel("Increase")
        }
    }
}
