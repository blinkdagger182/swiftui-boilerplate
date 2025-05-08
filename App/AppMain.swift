import SwiftUI
import RevenueCat

@main
struct AppMain: App {
    // MARK: - Properties
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    // MARK: - Services
    @StateObject private var coordinatorManager = CoordinatorManager.shared
    @StateObject private var featureFlagsService = FeatureFlagsService.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var toastService = ToastService.shared
    @StateObject private var updateService = UpdateService.shared
    @StateObject private var photoManager = PhotoManager.shared
    @StateObject private var imageProcessor = ImageProcessorService.shared
    @StateObject private var storageManager = LocalStorageManager.shared
    @StateObject private var backgroundTaskService = BackgroundTaskService.shared
    @StateObject private var analyticsService = AnalyticsService.shared
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                SplashView()
                    .environmentObject(updateService)
                    .environmentObject(subscriptionManager)
                    .environmentObject(coordinatorManager)
                    .environmentObject(featureFlagsService)
                    .environmentObject(toastService)
                    .environmentObject(photoManager)
                    .environmentObject(imageProcessor)
                    .environmentObject(storageManager)
                    .environmentObject(backgroundTaskService)
                    .environmentObject(analyticsService)
            } else {
                OnboardingCoordinatorView()
                    .environmentObject(coordinatorManager)
                    .environmentObject(featureFlagsService)
                    .environmentObject(toastService)
                    .environmentObject(analyticsService)
            }
        }
    }
    
    // MARK: - Init
    init() {
        // Set up appearance
        configureAppAppearance()
        
        // Register for background task
        backgroundTaskService.registerBackgroundTasks()
    }
    
    // MARK: - Private Methods
    private func configureAppAppearance() {
        // Configure global UI appearance
        let appearance = UINavigationBar.appearance()
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
    }
} 