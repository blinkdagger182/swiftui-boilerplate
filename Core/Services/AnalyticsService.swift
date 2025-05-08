import Foundation
import Combine

@MainActor
class AnalyticsService: ObservableObject {
    // MARK: - Singleton
    static let shared = AnalyticsService()
    
    // MARK: - Properties
    private var isEnabled = true
    private var userId: String?
    private var sessionStartTime: Date?
    private var currentScreen: Screen?
    
    // Storage for events waiting to upload
    private var pendingEvents: [AnalyticEvent] = []
    private let eventUploadThreshold = 20
    
    // MARK: - Initialization
    private init() {
        sessionStartTime = Date()
        // Load user consent from UserDefaults
        isEnabled = UserDefaults.standard.bool(forKey: "analytics_enabled")
        
        // Start upload timer
        startUploadTimer()
    }
    
    // MARK: - Public Methods
    
    /// Set user consent for analytics
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "analytics_enabled")
        
        if enabled {
            trackEvent(.appSettings, properties: ["analytics_enabled": true])
        } else {
            clearPendingEvents()
        }
    }
    
    /// Set the user identifier
    func setUserId(_ id: String) {
        userId = id
        trackEvent(.userIdentified)
    }
    
    /// Track screen view
    func trackScreen(_ screen: Screen) {
        guard isEnabled else { return }
        
        currentScreen = screen
        trackEvent(.screenView, properties: ["screen_name": screen.rawValue])
    }
    
    /// Track a user action or event
    func trackEvent(_ eventType: EventType, properties: [String: Any] = [:]) {
        guard isEnabled else { return }
        
        var eventProperties = properties
        
        // Add standard properties
        eventProperties["event_time"] = ISO8601DateFormatter().string(from: Date())
        eventProperties["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        eventProperties["device_model"] = UIDevice.current.model
        eventProperties["os_version"] = UIDevice.current.systemVersion
        
        if let userId = userId {
            eventProperties["user_id"] = userId
        }
        
        if let currentScreen = currentScreen {
            eventProperties["current_screen"] = currentScreen.rawValue
        }
        
        let event = AnalyticEvent(
            type: eventType.rawValue,
            properties: eventProperties,
            timestamp: Date()
        )
        
        // Store in the pending events queue
        pendingEvents.append(event)
        
        // Check if we should upload
        if pendingEvents.count >= eventUploadThreshold {
            uploadEvents()
        }
    }
    
    /// Track error occurrence
    func trackError(_ error: Error, additionalInfo: [String: Any] = [:]) {
        guard isEnabled else { return }
        
        var properties = additionalInfo
        properties["error_description"] = error.localizedDescription
        properties["error_domain"] = (error as NSError).domain
        properties["error_code"] = (error as NSError).code
        
        trackEvent(.error, properties: properties)
    }
    
    /// Track photo processing event
    func trackPhotoProcessing(count: Int, success: Bool, durationMs: Double) {
        guard isEnabled else { return }
        
        let properties: [String: Any] = [
            "photo_count": count,
            "success": success,
            "duration_ms": durationMs,
            "processing_type": "cleaning"
        ]
        
        trackEvent(.photoProcessed, properties: properties)
    }
    
    // MARK: - Private Methods
    
    private func startUploadTimer() {
        // Create timer to upload events every 2 minutes
        Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            self?.uploadEvents()
        }
    }
    
    private func uploadEvents() {
        guard isEnabled, !pendingEvents.isEmpty else { return }
        
        // In a real implementation, this would send to a backend service
        // For the boilerplate, we'll just log to console and clear
        print("📊 Analytics: Uploading \(pendingEvents.count) events")
        
        // Simulate network call
        Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000) // 500ms
                pendingEvents.removeAll()
            } catch {
                print("❌ Analytics upload error: \(error)")
            }
        }
    }
    
    private func clearPendingEvents() {
        pendingEvents.removeAll()
    }
}

// MARK: - Analytics Types

/// Types of events that can be tracked
enum EventType: String {
    case appLaunch = "app_launch"
    case appBackground = "app_background"
    case appForeground = "app_foreground"
    case appTerminate = "app_terminate"
    case screenView = "screen_view"
    case userInteraction = "user_interaction"
    case photoProcessed = "photo_processed"
    case photoSaved = "photo_saved"
    case photoDeleted = "photo_deleted"
    case subscriptionChanged = "subscription_changed"
    case featureFlagChanged = "feature_flag_changed"
    case appSettings = "app_settings"
    case userIdentified = "user_identified"
    case error = "error"
}

/// Screens that can be tracked
enum Screen: String {
    case splash = "splash"
    case onboarding = "onboarding"
    case home = "home"
    case photoGallery = "photo_gallery"
    case photoDetail = "photo_detail"
    case settings = "settings"
    case subscription = "subscription"
    case about = "about"
}

/// Structure representing an analytic event
struct AnalyticEvent {
    let id = UUID()
    let type: String
    let properties: [String: Any]
    let timestamp: Date
} 