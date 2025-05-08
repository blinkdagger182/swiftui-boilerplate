import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
class LocalStorageManager: ObservableObject {
    // MARK: - Singleton
    static let shared = LocalStorageManager()
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Core Data
    private let modelName = "PhotoCleanerModel"
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("❌ CoreData error: \(error), \(error.userInfo)")
                self.error = error
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - User Defaults
    private let defaults = UserDefaults.standard
    
    // Commonly accessed user defaults keys
    enum DefaultsKey: String {
        case lastPhotoCleanDate
        case totalPhotosCleaned
        case spaceSaved
        case hasSeenTutorial
        case selectedTheme
        case autoCleanEnabled
        case cleaningQuality
        case useFaceDetection
        case lastSyncDate
    }
    
    // MARK: - Initialization
    private init() {
        // Initialize storage if needed
        setupDefaults()
    }
    
    // MARK: - Core Data Operations
    
    /// Save the CoreData context
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ Error saving context: \(error)")
                self.error = error
            }
        }
    }
    
    /// Create a background context for processing
    func createBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    /// Perform a task in a background context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = createBackgroundContext()
        context.perform {
            block(context)
            
            // Save if there are changes
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    print("❌ Background context save error: \(error)")
                }
            }
        }
    }
    
    // MARK: - UserDefaults Methods
    
    /// Setup default values for UserDefaults
    private func setupDefaults() {
        let defaultValues: [String: Any] = [
            DefaultsKey.totalPhotosCleaned.rawValue: 0,
            DefaultsKey.spaceSaved.rawValue: 0.0,
            DefaultsKey.hasSeenTutorial.rawValue: false,
            DefaultsKey.selectedTheme.rawValue: "system",
            DefaultsKey.autoCleanEnabled.rawValue: false,
            DefaultsKey.cleaningQuality.rawValue: "standard",
            DefaultsKey.useFaceDetection.rawValue: true
        ]
        
        defaults.register(defaults: defaultValues)
    }
    
    /// Get a value from UserDefaults
    func getValue<T>(for key: DefaultsKey) -> T? {
        return defaults.object(forKey: key.rawValue) as? T
    }
    
    /// Set a value in UserDefaults
    func setValue<T>(_ value: T, for key: DefaultsKey) {
        defaults.set(value, for: key.rawValue)
    }
    
    /// Increment a counter
    func incrementCounter(for key: DefaultsKey, by value: Int = 1) {
        let currentValue = getValue(for: key) as? Int ?? 0
        setValue(currentValue + value, for: key)
    }
    
    /// Add to a running total
    func addToTotal(for key: DefaultsKey, amount: Double) {
        let currentValue = getValue(for: key) as? Double ?? 0.0
        setValue(currentValue + amount, for: key)
    }
    
    /// Reset a specific value to default
    func resetValue(for key: DefaultsKey) {
        defaults.removeObject(forKey: key.rawValue)
    }
    
    /// Clear all app storage
    func clearAllData() {
        // Clear UserDefaults (preserving essential settings)
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
        
        // Reset CoreData
        let coordinator = persistentContainer.persistentStoreCoordinator
        
        for store in coordinator.persistentStores {
            do {
                try coordinator.remove(store)
            } catch {
                print("❌ Failed to remove persistent store: \(error)")
            }
        }
        
        // Reload persistent stores
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Failed to reload stores: \(error)")
            }
        }
        
        // Restore default values
        setupDefaults()
    }
    
    // MARK: - Photo History Methods
    
    /// Record a photo cleaning operation
    func recordPhotoClean(originalSize: Double, newSize: Double, timestamp: Date = Date()) {
        // Save to CoreData history
        let historyContext = createBackgroundContext()
        historyContext.perform {
            let entry = PhotoCleanHistory(context: historyContext)
            entry.timestamp = timestamp
            entry.originalSize = originalSize
            entry.newSize = newSize
            entry.spaceSaved = originalSize - newSize
            
            do {
                try historyContext.save()
            } catch {
                print("❌ Failed to save photo history: \(error)")
            }
        }
        
        // Update cumulative statistics
        incrementCounter(for: .totalPhotosCleaned)
        addToTotal(for: .spaceSaved, amount: originalSize - newSize)
        setValue(timestamp, for: .lastPhotoCleanDate)
    }
    
    /// Get cleaning statistics
    func getCleaningStats() -> CleaningStats {
        let totalCleaned = getValue(for: .totalPhotosCleaned) as? Int ?? 0
        let spaceSaved = getValue(for: .spaceSaved) as? Double ?? 0.0
        let lastCleanDate = getValue(for: .lastPhotoCleanDate) as? Date
        
        return CleaningStats(
            totalPhotosCleaned: totalCleaned,
            totalSpaceSaved: spaceSaved,
            lastCleanDate: lastCleanDate
        )
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    func set<T>(_ value: T, for key: String) {
        set(value, forKey: key)
    }
}

// MARK: - Models
struct CleaningStats {
    let totalPhotosCleaned: Int
    let totalSpaceSaved: Double
    let lastCleanDate: Date?
    
    var spaceSavedFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalSpaceSaved))
    }
}

// MARK: - CoreData Model Classes
// These would typically be generated by CoreData model editor

class PhotoCleanHistory: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var timestamp: Date
    @NSManaged var originalSize: Double
    @NSManaged var newSize: Double
    @NSManaged var spaceSaved: Double
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
        id = UUID()
    }
} 