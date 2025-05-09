import Foundation
import SwiftUI

// MARK: - Route Protocols
protocol Route: Hashable {}

// MARK: - Coordinator Manager
@MainActor
class CoordinatorManager: ObservableObject {
    // MARK: - Singleton
    static let shared = CoordinatorManager()
    
    // MARK: - Published Properties
    @Published var mainPath: [MainRoute] = []
    @Published var onboardingPath: [OnboardingRoute] = []
    @Published var sheetItem: AnyIdentifiable?
    @Published var fullScreenCoverItem: AnyIdentifiable?
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Navigation Methods
    func navigate(to route: MainRoute) {
        mainPath.append(route)
    }
    
    func navigateOnboarding(to route: OnboardingRoute) {
        onboardingPath.append(route)
    }
    
    func resetToRoot() {
        mainPath = []
    }
    
    func resetOnboardingToRoot() {
        onboardingPath = []
    }
    
    func goBack() {
        if !mainPath.isEmpty {
            mainPath.removeLast()
        }
    }
    
    func goBackOnboarding() {
        if !onboardingPath.isEmpty {
            onboardingPath.removeLast()
        }
    }
    
    // Sheet/FullScreenCover Presentation
    func presentSheet<Content: View & Identifiable>(content: Content) {
        sheetItem = AnyIdentifiable(content)
    }
    
    func presentFullScreenCover<Content: View & Identifiable>(content: Content) {
        fullScreenCoverItem = AnyIdentifiable(content)
    }
    
    func dismissSheet() {
        sheetItem = nil
    }
    
    func dismissFullScreenCover() {
        fullScreenCoverItem = nil
    }
}

// MARK: - Route Enums
enum MainRoute: Route {
    case home
    case settings
    case profile
    case subscription
}

enum OnboardingRoute: Route {
    case welcome
    case features
    case permissions
}

// MARK: - AnyIdentifiable for Type-Erasing Views for Sheets
struct AnyIdentifiable: Identifiable {
    let id: String
    let content: AnyView
    
    init<T: View & Identifiable>(_ content: T) {
        self.id = String(describing: content.id)
        self.content = AnyView(content)
    }
} 