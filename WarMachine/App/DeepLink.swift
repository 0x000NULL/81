import SwiftUI

enum DeepLink: Equatable {
    case gtg
    case weeklyVerse
}

private struct DeepLinkKey: EnvironmentKey {
    static let defaultValue: DeepLink? = nil
}

extension EnvironmentValues {
    var deepLink: DeepLink? {
        get { self[DeepLinkKey.self] }
        set { self[DeepLinkKey.self] = newValue }
    }
}
