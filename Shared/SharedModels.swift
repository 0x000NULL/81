import Foundation

struct GtgWidgetSnapshot: Codable {
    var date: Date
    var count: Int
    var target: Int

    static let empty = GtgWidgetSnapshot(date: .now, count: 0, target: 30)
}

extension GtgWidgetSnapshot {
    static func load() -> GtgWidgetSnapshot {
        guard let data = AppGroup.defaults.data(forKey: AppGroup.gtgSnapshotKey),
              let snap = try? JSONDecoder().decode(GtgWidgetSnapshot.self, from: data) else {
            return .empty
        }
        return snap
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        AppGroup.defaults.set(data, forKey: AppGroup.gtgSnapshotKey)
    }
}
