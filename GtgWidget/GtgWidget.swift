import WidgetKit
import SwiftUI

@main
struct GtgWidget: Widget {
    let kind: String = "GtgWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GtgProvider()) { entry in
            GtgWidgetEntryView(entry: entry)
                .containerBackground(Color(red: 0.09, green: 0.09, blue: 0.09), for: .widget)
        }
        .configurationDisplayName("GTG Pull-ups")
        .description("Grease-the-groove tracker.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct GtgEntry: TimelineEntry {
    let date: Date
    let snapshot: GtgWidgetSnapshot
}

struct GtgProvider: TimelineProvider {
    func placeholder(in context: Context) -> GtgEntry {
        GtgEntry(date: .now, snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (GtgEntry) -> Void) {
        let snap = GtgWidgetSnapshot.load()
        completion(GtgEntry(date: .now, snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GtgEntry>) -> Void) {
        let snap = GtgWidgetSnapshot.load()
        let entry = GtgEntry(date: .now, snapshot: snap)
        // Refresh at midnight for the next day
        let nextMidnight = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

struct GtgWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: GtgEntry

    var body: some View {
        Link(destination: URL(string: "warmachine://gtg")!) {
            switch family {
            case .systemMedium:
                mediumBody
            default:
                smallBody
            }
        }
    }

    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("GTG", systemImage: "figure.strengthtraining.traditional")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(entry.snapshot.count)")
                .font(.system(size: 44, weight: .bold).monospacedDigit())
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
            Text("of \(entry.snapshot.target)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            ProgressView(value: min(1, Double(entry.snapshot.count) / Double(max(1, entry.snapshot.target))))
                .tint(Color(red: 0.45, green: 0.50, blue: 0.30))
        }
    }

    private var mediumBody: some View {
        HStack(alignment: .firstTextBaseline, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Label("GTG pull-ups", systemImage: "figure.strengthtraining.traditional")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("\(entry.snapshot.count)")
                    .font(.system(size: 56, weight: .bold).monospacedDigit())
                    .foregroundStyle(.white)
                Text("of \(entry.snapshot.target) today")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Gauge(value: min(1, Double(entry.snapshot.count) / Double(max(1, entry.snapshot.target)))) {
                EmptyView()
            } currentValueLabel: {
                Text("\(Int(min(100, Double(entry.snapshot.count) * 100 / Double(max(1, entry.snapshot.target)))))%")
                    .font(.caption)
            }
            .gaugeStyle(.accessoryCircular)
            .tint(Color(red: 0.45, green: 0.50, blue: 0.30))
        }
    }
}
