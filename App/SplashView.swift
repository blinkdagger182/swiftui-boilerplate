import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var updateService: UpdateService
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var photoManager: PhotoManager
    @EnvironmentObject private var analyticsService: AnalyticsService
    
    @State private var isLoading = true
    @State private var showMainContent = false
    
    var body: some View {
        ZStack {
            // Splash content
            if isLoading {
                VStack(spacing: 20) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 80))
                        .foregroundColor(.primary)
                    
                    Text("Photo Cleaner")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    ProgressView()
                        .padding(.top, 20)
                }
            } else if showMainContent {
                // Main content shows here
                MainScreenView()
                    .transition(.opacity)
            }
            
            // Force update overlay - blocks all interaction
            if updateService.shouldForceUpdate, let notes = updateService.updateNotes {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                UpdatePromptView(
                    isForceUpdate: true,
                    notes: notes,
                    onDismiss: {}
                )
            }
            
            // Optional update overlay
            if !updateService.shouldForceUpdate && updateService.shouldShowOptionalUpdate, let notes = updateService.updateNotes {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                UpdatePromptView(
                    isForceUpdate: false,
                    notes: notes,
                    onDismiss: {
                        updateService.dismissOptionalUpdate()
                    }
                )
            }
        }
        .task {
            // Handle startup tasks
            await startupTasks()
        }
    }
    
    private func startupTasks() async {
        // Track app launch
        analyticsService.trackEvent(.appLaunch)
        
        // Simulate a short loading time
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Initialize RevenueCat
        let apiKey = "appl_dummyRevenueCatAPIKey" // Replace with your actual key in production
        subscriptionManager.configure(apiKey: apiKey)
        
        // Check for app updates
        await updateService.checkAppVersion()
        
        // Initialize photo library access
        photoManager.checkAuthorizationStatus()
        
        // Initialize other services
        await subscriptionManager.checkSubscriptionStatus()
        
        // Show main content if no force update is required
        if !updateService.shouldForceUpdate {
            withAnimation {
                isLoading = false
                showMainContent = true
            }
            
            // Track screen view for analytics
            analyticsService.trackScreen(.home)
        }
    }
}

#Preview {
    SplashView()
        .environmentObject(UpdateService.shared)
        .environmentObject(SubscriptionManager.shared)
        .environmentObject(PhotoManager.shared)
        .environmentObject(AnalyticsService.shared)
} 