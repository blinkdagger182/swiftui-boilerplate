import Foundation
import SwiftUI

@MainActor
class UpdateService: ObservableObject {
    // MARK: - Singleton
    static let shared = UpdateService()
    
    // MARK: - Published Properties
    @Published var shouldForceUpdate = false
    @Published var shouldShowOptionalUpdate = false
    @Published var updateNotes: String?
    @Published var isLoading = false
    
    // MARK: - Properties
    private let supabaseURL = URL(string: "https://uetswhrdkmokxtnzsaeq.supabase.co")!
    private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVldHN3aHJka21va3h0bnpzYWVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM5MTQ1NjcsImV4cCI6MjA1OTQ5MDU2N30.1ceVlgsfTFJn6EkTitEsH97e6SAatJWsh6gHu8c25z4"
    
    private let platform = "ios"
    private let dismissedVersionKey = "dismissedVersion"
    private var currentAppVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var dismissedVersion: String {
        get {
            UserDefaults.standard.string(forKey: dismissedVersionKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: dismissedVersionKey)
        }
    }
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Check app version and alert if updates are needed
    func checkAppVersion() async {
        isLoading = true
        defer { isLoading = false }
        
        // Construct API URL for Supabase
        var components = URLComponents(url: supabaseURL, resolvingAgainstBaseURL: true)!
        components.path = "/rest/v1/app_versions"
        components.queryItems = [
            URLQueryItem(name: "platform", value: "eq.\(platform)"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "version_code.desc"),
            URLQueryItem(name: "limit", value: "1")
        ]
        
        guard let url = components.url else {
            print("❌ Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Parse version data
            let responseArray = try JSONDecoder().decode([VersionResponse].self, from: data)
            
            guard let latestVersion = responseArray.first else {
                print("⚠️ No version info found")
                return
            }
            
            // Compare versions
            let currentVersionComponents = currentAppVersion.split(separator: ".").compactMap { Int($0) }
            let latestVersionComponents = latestVersion.versionName.split(separator: ".").compactMap { Int($0) }
            
            // Pad arrays to same length with zeros
            let maxLength = max(currentVersionComponents.count, latestVersionComponents.count)
            let paddedCurrent = padVersion(currentVersionComponents, toLength: maxLength)
            let paddedLatest = padVersion(latestVersionComponents, toLength: maxLength)
            
            // Compare version components
            let needsUpdate = compareVersions(paddedCurrent, paddedLatest) < 0
            
            if needsUpdate {
                updateNotes = latestVersion.releaseNotes
                
                if latestVersion.forceUpdate {
                    shouldForceUpdate = true
                } else if dismissedVersion != latestVersion.versionName {
                    shouldShowOptionalUpdate = true
                }
            }
            
        } catch {
            print("❌ Error checking version: \(error.localizedDescription)")
        }
    }
    
    /// Dismiss optional update for current version
    func dismissOptionalUpdate() {
        // Get latest version from response
        if let updateNotes = updateNotes, let versionMatch = updateNotes.matches(of: /Version (\d+\.\d+\.\d+)/).first,
           let wholeMatch = versionMatch.output.1.substring {
            dismissedVersion = String(wholeMatch)
        }
        
        shouldShowOptionalUpdate = false
    }
    
    // MARK: - Private Helper Methods
    
    private func padVersion(_ version: [Int], toLength length: Int) -> [Int] {
        var result = version
        while result.count < length {
            result.append(0)
        }
        return result
    }
    
    private func compareVersions(_ v1: [Int], _ v2: [Int]) -> Int {
        for (index, component) in v1.enumerated() {
            if index >= v2.count {
                return component > 0 ? 1 : 0
            }
            
            if component < v2[index] {
                return -1
            } else if component > v2[index] {
                return 1
            }
        }
        return 0
    }
}

// MARK: - Version Response
struct VersionResponse: Codable {
    let id: Int
    let createdAt: String
    let platform: String
    let versionName: String
    let versionCode: Int
    let releaseNotes: String
    let forceUpdate: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case platform
        case versionName = "version_name"
        case versionCode = "version_code"
        case releaseNotes = "release_notes"
        case forceUpdate = "force_update"
    }
} 