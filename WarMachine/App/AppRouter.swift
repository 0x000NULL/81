import SwiftUI
import SwiftData

struct AppRouter: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if profiles.isEmpty {
                OnboardingCoordinator(onComplete: {})
            } else {
                RootTabView()
            }
        }
        .preferredColorScheme(.dark)
    }
}
