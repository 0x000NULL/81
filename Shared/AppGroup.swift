import Foundation

enum AppGroup {
    static let suiteName = "group.BA256NPZGA.warmachine"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static let gtgSnapshotKey = "gtg.snapshot.v1"
}
