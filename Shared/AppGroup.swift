import Foundation

enum AppGroup {
    static let suiteName = "group.com.warmachine.app"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static let gtgSnapshotKey = "gtg.snapshot.v1"
}
