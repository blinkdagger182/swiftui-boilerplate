import SwiftUI

struct OnboardingView: View {
    // MARK: - Dependencies
    @EnvironmentObject private var analyticsService: AnalyticsService
    @ObservedObject private var photoManager: PhotoManager
    
    // MARK: - Properties
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Binding var currentPage: Int
    
    private let totalPages = 3
    
    // MARK: - State
    @State private var animateIcon = false
    
    // MARK: - Initialization
    init(
        currentPage: Binding<Int>,
        photoManager: PhotoManager = PhotoManager.shared
    ) {
        self._currentPage = currentPage
        self.photoManager = photoManager
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            // Skip button
            HStack {
                Spacer()
                
                Button("Skip") {
                    completeOnboarding()
                }
                .padding()
                .foregroundColor(.gray)
            }
            
            // Page indicator
            HStack {
                ForEach(0..<totalPages, id: \.self) { page in
                    Circle()
                        .fill(page == currentPage ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.top)
            
            Spacer()
            
            // Page content
            switch currentPage {
            case 0:
                welcomePage
            case 1:
                featuresPage
            case 2:
                permissionsPage
            default:
                welcomePage
            }
            
            Spacer()
            
            // Navigation buttons
            HStack {
                // Back button (hidden on first page)
                Button(action: {
                    withAnimation {
                        if currentPage > 0 {
                            currentPage -= 1
                        }
                    }
                }) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.title)
                        .foregroundColor(currentPage > 0 ? .blue : .gray.opacity(0.5))
                }
                .disabled(currentPage == 0)
                .padding()
                
                Spacer()
                
                // Next button
                Button(action: {
                    withAnimation {
                        if currentPage < totalPages - 1 {
                            currentPage += 1
                        } else {
                            completeOnboarding()
                        }
                    }
                }) {
                    HStack {
                        Text(currentPage < totalPages - 1 ? "Continue" : "Get Started")
                        
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
                }
                .padding()
            }
        }
        .onAppear {
            // Track onboarding start
            analyticsService.trackScreen(.onboarding)
        }
    }
    
    // MARK: - Page Views
    
    private var welcomePage: some View {
        VStack(spacing: 30) {
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .scaleEffect(animateIcon ? 1.2 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        animateIcon = true
                    }
                }
            
            Text("Welcome to Photo Cleaner")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Clean your photos to save space and protect your privacy.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
        }
        .padding()
    }
    
    private var featuresPage: some View {
        VStack(spacing: 40) {
            Text("Smart Features")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            featureRow(icon: "sparkles", title: "Optimize Photos", description: "Reduce file size without losing quality")
            
            featureRow(icon: "eye.slash", title: "Remove Metadata", description: "Protect your privacy by removing location data")
            
            featureRow(icon: "chart.bar", title: "Track Savings", description: "See how much space you've saved")
        }
        .padding()
    }
    
    private var permissionsPage: some View {
        VStack(spacing: 30) {
            Text("One Last Step")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding(.vertical)
            
            Text("We'll need access to your photos to help you clean them.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            
            Button(action: {
                requestPhotoAccess()
            }) {
                Text("Grant Photo Access")
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
            }
            .padding(.top, 30)
        }
        .padding()
    }
    
    // MARK: - Helper Views
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func completeOnboarding() {
        hasSeenOnboarding = true
        analyticsService.trackEvent(.userInteraction, properties: ["action": "completed_onboarding"])
    }
    
    private func requestPhotoAccess() {
        Task {
            let granted = await photoManager.requestAccess()
            if granted {
                analyticsService.trackEvent(.userInteraction, properties: ["action": "granted_photo_access"])
            } else {
                analyticsService.trackEvent(.userInteraction, properties: ["action": "denied_photo_access"])
            }
        }
    }
}

// MARK: - Coordinator View
struct OnboardingCoordinatorView: View {
    @State private var currentPage: Int = 0
    @EnvironmentObject private var analyticsService: AnalyticsService
    
    var body: some View {
        OnboardingView(currentPage: $currentPage)
            .environmentObject(analyticsService)
    }
}

#Preview {
    OnboardingCoordinatorView()
        .environmentObject(AnalyticsService.shared)
} 