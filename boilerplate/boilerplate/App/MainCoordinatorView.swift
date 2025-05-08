import SwiftUI

struct MainCoordinatorView: View {
    @EnvironmentObject private var coordinator: CoordinatorManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    var body: some View {
        NavigationStack(path: $coordinator.mainPath) {
            HomeView()
                .navigationDestination(for: MainRoute.self) { route in
                    switch route {
                    case .home:
                        HomeView()
                    case .settings:
                        SettingsView()
                    case .profile:
                        ProfileView()
                    case .subscription:
                        PaywallView()
                    }
                }
        }
        .sheet(item: $coordinator.sheetItem) { item in
            item.content
        }
        .fullScreenCover(item: $coordinator.fullScreenCoverItem) { item in
            item.content
        }
    }
}

// Simple placeholder views - they would be moved to their own files in actual implementation
struct HomeView: View {
    @EnvironmentObject private var coordinator: CoordinatorManager
    
    var body: some View {
        VStack {
            Text("Home Screen")
                .font(.title)
                .padding()
            
            Button("Go to Settings") {
                coordinator.navigate(to: .settings)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            Button("Go to Profile") {
                coordinator.navigate(to: .profile)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            Button("Go to Subscription") {
                coordinator.navigate(to: .subscription)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle("Home")
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings Screen")
            .font(.title)
            .navigationTitle("Settings")
    }
}

struct ProfileView: View {
    var body: some View {
        Text("Profile Screen")
            .font(.title)
            .navigationTitle("Profile")
    }
}

#Preview {
    MainCoordinatorView()
        .environmentObject(CoordinatorManager.shared)
        .environmentObject(SubscriptionManager.shared)
} 