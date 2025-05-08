import SwiftUI

struct OnboardingCoordinatorView: View {
    @EnvironmentObject private var coordinator: CoordinatorManager
    
    var body: some View {
        NavigationStack(path: $coordinator.onboardingPath) {
            OnboardingView()
                .navigationDestination(for: OnboardingRoute.self) { route in
                    switch route {
                    case .welcome:
                        OnboardingWelcomeView()
                    case .features:
                        OnboardingFeaturesView()
                    case .permissions:
                        OnboardingPermissionsView()
                    }
                }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    OnboardingCoordinatorView()
        .environmentObject(CoordinatorManager.shared)
} 