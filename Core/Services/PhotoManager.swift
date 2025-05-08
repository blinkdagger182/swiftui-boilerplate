import Foundation
import Photos
import SwiftUI
import Combine

@MainActor
class PhotoManager: ObservableObject {
    // MARK: - Singleton
    static let shared = PhotoManager()
    
    // MARK: - Published Properties
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var recentPhotos: [PHAsset] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    // MARK: - Properties
    private let imageManager = PHCachingImageManager()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Public Methods
    
    /// Request access to the photo library
    func requestAccess() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            self.authorizationStatus = status
        }
        
        if status == .authorized || status == .limited {
            await fetchRecentPhotos()
            return true
        }
        return false
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    /// Fetch recent photos from the library
    func fetchRecentPhotos() async {
        isLoading = true
        defer { isLoading = false }
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 100
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        await MainActor.run {
            self.recentPhotos = assets
        }
    }
    
    /// Load a thumbnail image for a given asset
    func loadThumbnail(for asset: PHAsset, size: CGSize, contentMode: PHImageContentMode = .aspectFill) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            
            imageManager.requestImage(
                for: asset,
                targetSize: size,
                contentMode: contentMode,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    /// Load a full-size image for a given asset
    func loadFullSizeImage(for asset: PHAsset) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            
            imageManager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    /// Save an edited image to the photo library
    func saveEditedImage(_ image: UIImage, from originalAsset: PHAsset) async -> Bool {
        guard authorizationStatus == .authorized else { return false }
        
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                request.creationDate = Date()
            } completionHandler: { success, error in
                if let error = error {
                    Task { @MainActor in
                        self.error = error
                    }
                }
                continuation.resume(returning: success)
            }
        }
    }
    
    /// Delete a photo from the library
    func deletePhoto(_ asset: PHAsset) async -> Bool {
        guard authorizationStatus == .authorized else { return false }
        
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets([asset] as NSArray)
            } completionHandler: { success, error in
                if let error = error {
                    Task { @MainActor in
                        self.error = error
                    }
                }
                continuation.resume(returning: success)
            }
        }
    }
    
    /// Cancel all pending image requests
    func cancelAllImageRequests() {
        imageManager.stopCachingImagesForAllAssets()
    }
} 