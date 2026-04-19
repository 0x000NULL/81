import SwiftUI

enum Theme {
    static let bg = Color(red: 0.04, green: 0.04, blue: 0.04)
    static let surface = Color(red: 0.09, green: 0.09, blue: 0.09)
    static let textPrimary = Color(red: 0.95, green: 0.95, blue: 0.95)
    static let textSecondary = Color(red: 0.60, green: 0.60, blue: 0.60)
    static let accent = Color(red: 0.45, green: 0.50, blue: 0.30)
    static let destructive = Color(red: 0.70, green: 0.30, blue: 0.30)
    static let verseBody = Color(red: 0.88, green: 0.86, blue: 0.82)

    enum Radius {
        static let card: CGFloat = 12
        static let button: CGFloat = 8
    }

    enum Spacing {
        static let inline: CGFloat = 8
        static let `default`: CGFloat = 16
        static let section: CGFloat = 24
    }
}
