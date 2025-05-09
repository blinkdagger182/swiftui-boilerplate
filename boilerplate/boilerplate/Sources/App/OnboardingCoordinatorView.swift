import SwiftUI

// MARK: - Route Enum

enum OnboardingRoute: Hashable {
    case welcome
    case features
    case permissions
}

// MARK: - Coordinator

final class CoordinatorManager: ObservableObject {
    static let shared = CoordinatorManager()
    
    @Published var onboardingPath: [OnboardingRoute] = []
    
    func goToNextOnboardingStep(from current: OnboardingRoute) {
        switch current {
        case .welcome:
            onboardingPath.append(.features)
        case .features:
            onboardingPath.append(.permissions)
        case .permissions:
            onboardingPath.removeAll() // Or trigger transition to main app
        }
    }
}

// MARK: - Root Coordinator View

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

// MARK: - Onboarding Entry View

struct OnboardingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🧼 Welcome to cln.")
                .font(.largeTitle)
                .bold()
            Text("Your gallery deserves better. Let's walk you through.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            NavigationLink(value: OnboardingRoute.welcome) {
                Text("Get Started")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

// MARK: - Step 1

struct OnboardingWelcomeView: View {
    @EnvironmentObject private var coordinator: CoordinatorManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("👋 Welcome!")
                .font(.title)
            Text("cln. helps you swipe through photos and clean up your gallery fast.")
                .multilineTextAlignment(.center)
            Button("Next") {
                coordinator.goToNextOnboardingStep(from: .welcome)
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

// MARK: - Step 2

struct OnboardingFeaturesView: View {
    @EnvironmentObject private var coordinator: CoordinatorManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("✨ Features")
                .font(.title)
            Text("• Swipe to delete\n• Smart albums\n• Undo anytime")
                .multilineTextAlignment(.leading)
            Button("Next") {
                coordinator.goToNextOnboardingStep(from: .features)
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

// MARK: - Step 3

struct OnboardingPermissionsView: View {
    @EnvironmentObject private var coordinator: CoordinatorManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🔐 Permissions")
                .font(.title)
            Text("We need access to your Photos to work our magic.")
                .multilineTextAlignment(.center)
            Button("Finish") {
                coordinator.goToNextOnboardingStep(from: .permissions)
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    OnboardingCoordinatorView()
        .environmentObject(CoordinatorManager.shared)
}
