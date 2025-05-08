import Foundation
import UIKit
import BackgroundTasks

@MainActor
class BackgroundTaskService: ObservableObject {
    // MARK: - Singleton
    static let shared = BackgroundTaskService()
    
    // MARK: - Published Properties
    @Published var isPerformingBackgroundTask = false
    @Published var pendingTasks: [BackgroundTaskIdentifier: BackgroundTask] = [:]
    
    // MARK: - Properties
    private let backgroundTaskIdentifier = "com.app.photocleaning.processing"
    private let backgroundFetchIdentifier = "com.app.photocleaning.fetch"
    
    // MARK: - Initialization
    private init() {
        registerBackgroundTasks()
    }
    
    // MARK: - Public Methods
    
    /// Register background tasks with the system
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleProcessingTask(task as! BGProcessingTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundFetchIdentifier, using: nil) { task in
            self.handleAppRefresh(task as! BGAppRefreshTask)
        }
    }
    
    /// Schedule a background photo processing task
    func schedulePhotoProcessing() {
        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background processing task scheduled")
        } catch {
            print("❌ Could not schedule background processing: \(error)")
        }
    }
    
    /// Schedule background app refresh
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundFetchIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 15) // 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background refresh task scheduled")
        } catch {
            print("❌ Could not schedule app refresh: \(error)")
        }
    }
    
    /// Start a background task when the app is in the foreground
    func beginBackgroundTask(identifier: BackgroundTaskIdentifier, task: @escaping () async -> Void) {
        let backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask(identifier: identifier)
        }
        
        if backgroundTask == .invalid {
            print("❌ Failed to start background task")
            return
        }
        
        let newTask = BackgroundTask(id: backgroundTask, identifier: identifier)
        pendingTasks[identifier] = newTask
        
        Task {
            isPerformingBackgroundTask = true
            await task()
            endBackgroundTask(identifier: identifier)
        }
    }
    
    /// End a specific background task
    func endBackgroundTask(identifier: BackgroundTaskIdentifier) {
        guard let task = pendingTasks[identifier] else { return }
        
        UIApplication.shared.endBackgroundTask(task.id)
        pendingTasks.removeValue(forKey: identifier)
        
        if pendingTasks.isEmpty {
            isPerformingBackgroundTask = false
        }
    }
    
    // MARK: - Private Methods
    
    private func handleProcessingTask(_ task: BGProcessingTask) {
        // Schedule a new background task for next time before doing work
        schedulePhotoProcessing()
        
        task.expirationHandler = {
            // Cancel any work if this runs past the allowed time
            // This would need to handle stopping any in-progress work
            print("⚠️ Background processing task expired")
        }
        
        // Example async task
        Task {
            // Handle the actual background work - this should pull from a persistent queue
            // of photos that need processing
            
            do {
                // Simulate work with a delay
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                // Here you'd process photos from a queue
                // await processPhotoQueue()
                
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    private func handleAppRefresh(_ task: BGAppRefreshTask) {
        // Schedule the next refresh task
        scheduleAppRefresh()
        
        task.expirationHandler = {
            // Handle expiration by canceling any ongoing work
            print("⚠️ Background refresh task expired")
        }
        
        // Example task
        Task {
            do {
                // Refresh data as needed
                // await updatePhotoStats()
                // await syncUserPreferences()
                
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
}

// MARK: - Types

/// Unique identifier for background tasks
typealias BackgroundTaskIdentifier = String

/// Background task data structure
struct BackgroundTask {
    let id: UIBackgroundTaskIdentifier
    let identifier: BackgroundTaskIdentifier
} 