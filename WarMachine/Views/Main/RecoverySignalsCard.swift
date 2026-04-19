import SwiftUI
import Charts

struct RecoverySignalsCard: View {
    @State private var rhr: [DailyMetric] = []
    @State private var hrv: [DailyMetric] = []
    @State private var sleep: [DailyMetric] = []
    @State private var loaded = false

    private let days = 7

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recovery")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("\(days) days")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                metricRow(title: "Resting HR",
                          series: rhr,
                          latest: Format.heartRate(rhr.last?.value),
                          deltaUnit: "bpm")
                Divider().padding(.vertical, 2)
                metricRow(title: "HRV",
                          series: hrv,
                          latest: Format.hrv(hrv.last?.value),
                          deltaUnit: "ms")
                Divider().padding(.vertical, 2)
                metricRow(title: "Sleep",
                          series: sleep,
                          latest: sleep.last.map { String(format: "%.1f h", $0.value) } ?? "—",
                          deltaUnit: "h",
                          deltaFormat: "%.1f")
            }
        }
        .task {
            guard !loaded else { return }
            loaded = true
            await load()
        }
    }

    private func metricRow(title: String,
                           series: [DailyMetric],
                           latest: String,
                           deltaUnit: String,
                           deltaFormat: String = "%.0f") -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Text(latest)
                    .font(.body.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            sparkline(series: series)
                .frame(width: 120, height: 32)
            deltaBadge(series: series, unit: deltaUnit, format: deltaFormat)
                .frame(width: 60, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func sparkline(series: [DailyMetric]) -> some View {
        if series.count >= 2 {
            Chart(series) { m in
                LineMark(
                    x: .value("Day", m.day),
                    y: .value("Value", m.value)
                )
                .foregroundStyle(Theme.accent)
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartPlotStyle { $0.background(Color.clear) }
        } else {
            Text("No data")
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func deltaBadge(series: [DailyMetric], unit: String, format: String) -> some View {
        if let info = Self.deltaInfo(for: series) {
            HStack(spacing: 3) {
                Image(systemName: info.symbol).font(.caption2)
                Text(String(format: format, abs(info.delta)))
                    .font(.caption2.monospacedDigit())
                Text(unit).font(.caption2)
            }
            .foregroundStyle(Theme.textSecondary)
        } else {
            Text("—")
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private static func deltaInfo(for series: [DailyMetric]) -> (delta: Double, symbol: String)? {
        guard series.count >= 2, let latest = series.last?.value else { return nil }
        let prior = series.dropLast()
        let mean = prior.map(\.value).reduce(0, +) / Double(prior.count)
        let delta = latest - mean
        let symbol: String
        if abs(delta) < 0.5 {
            symbol = "minus"
        } else if delta > 0 {
            symbol = "arrow.up"
        } else {
            symbol = "arrow.down"
        }
        return (delta, symbol)
    }

    private func load() async {
        do {
            async let rhrSeries = HealthKitService.shared.restingHRSeries(days: days)
            async let hrvSeries = HealthKitService.shared.hrvSeries(days: days)
            async let sleepSeries = HealthKitService.shared.sleepHoursSeries(days: days)
            let (r, h, s) = try await (rhrSeries, hrvSeries, sleepSeries)
            await MainActor.run {
                rhr = r
                hrv = h
                sleep = s
            }
        } catch {
            // Leave series empty — "No data" renders.
        }
    }
}
