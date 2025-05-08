import Foundation
import Combine

// MARK: - Feature Flags Service
@MainActor
final class FeatureFlagsService: ObservableObject {
    // MARK: - Singleton
    static let shared = FeatureFlagsService()
    
    // MARK: - Published Properties
    @Published private(set) var flags: [FeatureFlag: Bool] = [:]
    @Published private(set) var isLoading = false
    
    // MARK: - Properties
    private let userDefaultsPrefix = "feature_flag_"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Local Toggle for Development
    private let useLocalFlagsForDevelopment: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    // MARK: - Initialization
    private init() {
        // Initialize with default values
        resetToDefaults()
        
        #if DEBUG
        // In debug mode, use mock refresh with a delay to simulate remote fetching
        print("🚩 Using local feature flags for development")
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Check if a feature is enabled
    func isEnabled(_ feature: FeatureFlag) -> Bool {
        return flags[feature] ?? feature.defaultValue
    }
    
    /// Toggle a feature (only works in development/debug mode)
    func toggleFeature(_ feature: FeatureFlag) {
        guard useLocalFlagsForDevelopment else {
            print("⚠️ Cannot toggle features in production mode")
            return
        }
        
        flags[feature] = !(flags[feature] ?? feature.defaultValue)
        saveToUserDefaults(feature: feature, value: flags[feature]!)
        
        print("🚩 Feature \(feature.rawValue) toggled to \(flags[feature] ?? false)")
    }
    
    /// Manually override a feature flag (only works in development/debug mode)
    func overrideFeature(_ feature: FeatureFlag, enabled: Bool) {
        guard useLocalFlagsForDevelopment else {
            print("⚠️ Cannot override features in production mode")
            return
        }
        
        flags[feature] = enabled
        saveToUserDefaults(feature: feature, value: enabled)
        
        print("🚩 Feature \(feature.rawValue) manually set to \(enabled)")
    }
    
    /// Fetch feature flags from remote server
    func fetchRemoteFlags() async {
        guard !useLocalFlagsForDevelopment else {
            await mockRemoteFetch()
            return
        }
        
        isLoading = true
        
        // Simulated network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // This would be a real API call in production
        // For now, we'll just use the local defaults
        resetToDefaults()
        
        isLoading = false
    }
    
    /// Reset all feature flags to their default values
    func resetToDefaults() {
        for feature in FeatureFlag.allCases {
            let savedValue = UserDefaults.standard.object(forKey: userDefaultsKey(for: feature)) as? Bool
            flags[feature] = savedValue ?? feature.defaultValue
        }
    }
    
    // MARK: - Private Methods
    
    private func mockRemoteFetch() async {
        isLoading = true
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Update with mock remote values
        for feature in FeatureFlag.allCases {
            if UserDefaults.standard.object(forKey: userDefaultsKey(for: feature)) == nil {
                // Only set default if not already set in UserDefaults
                flags[feature] = feature.defaultValue
                saveToUserDefaults(feature: feature, value: feature.defaultValue)
            }
        }
        
        isLoading = false
    }
    
    private func userDefaultsKey(for feature: FeatureFlag) -> String {
        return "\(userDefaultsPrefix)\(feature.rawValue)"
    }
    
    private func saveToUserDefaults(feature: FeatureFlag, value: Bool) {
        UserDefaults.standard.set(value, forKey: userDefaultsKey(for: feature))
    }
}

// MARK: - Feature Flag Enum
enum FeatureFlag: String, CaseIterable {
    case premiumFeatures = "premium_features"
    case darkMode = "dark_mode"
    case newOnboarding = "new_onboarding"
    case analyticsEnabled = "analytics_enabled"
    case betaFeatures = "beta_features"
    
    var defaultValue: Bool {
        switch self {
        case .premiumFeatures:
            return false
        case .darkMode:
            return true
        case .newOnboarding:
            return true
        case .analyticsEnabled:
            return true
        case .betaFeatures:
            return false
        }
    }
    
    var displayName: String {
        switch self {
        case .premiumFeatures:
            return "Premium Features"
        case .darkMode:
            return "Dark Mode"
        case .newOnboarding:
            return "New Onboarding Experience"
        case .analyticsEnabled:
            return "Analytics Collection"
        case .betaFeatures:
            return "Beta Features"
        }
    }
    
    var description: String {
        switch self {
        case .premiumFeatures:
            return "Enable premium features for all users"
        case .darkMode:
            return "Enable dark mode support"
        case .newOnboarding:
            return "Use the new onboarding flow"
        case .analyticsEnabled:
            return "Collect anonymous usage analytics"
        case .betaFeatures:
            return "Enable experimental features"
        }
    }
} 