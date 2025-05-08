import Foundation
import UIKit
import Combine
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

@MainActor
class ImageProcessorService: ObservableObject {
    // MARK: - Singleton
    static let shared = ImageProcessorService()
    
    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var progress: Double = 0
    @Published var error: Error?
    
    // MARK: - Properties
    private let context = CIContext()
    private let processingQueue = DispatchQueue(label: "com.app.imageprocessing", qos: .userInitiated)
    
    // MARK: - Processing Methods
    
    /// Clean a photo by removing metadata, optimizing quality and reducing file size
    func cleanPhoto(image: UIImage) async throws -> UIImage {
        isProcessing = true
        progress = 0
        defer { 
            isProcessing = false 
            progress = 1.0
        }
        
        do {
            // Step 1: Remove metadata (25%)
            progress = 0.25
            let strippedImage = try await stripMetadata(from: image)
            
            // Step 2: Optimize quality (50%)
            progress = 0.5
            let optimizedImage = try await optimizeQuality(image: strippedImage)
            
            // Step 3: Compress (75%)
            progress = 0.75
            let compressedImage = try await compressImage(optimizedImage)
            
            // Completed
            progress = 1.0
            return compressedImage
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Strip metadata from an image
    private func stripMetadata(from image: UIImage) async throws -> UIImage {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                guard let cgImage = image.cgImage else {
                    continuation.resume(returning: image)
                    return
                }
                
                // Create a new CIImage without metadata
                let ciImage = CIImage(cgImage: cgImage)
                let strippedCIImage = ciImage.settingProperties([kCGImagePropertyOrientation as String: 1])
                
                // Convert back to UIImage
                guard let outputCGImage = self.context.createCGImage(strippedCIImage, from: strippedCIImage.extent) else {
                    continuation.resume(returning: image)
                    return
                }
                
                let strippedImage = UIImage(cgImage: outputCGImage)
                continuation.resume(returning: strippedImage)
            }
        }
    }
    
    /// Optimize image quality
    private func optimizeQuality(image: UIImage) async throws -> UIImage {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                guard let cgImage = image.cgImage, 
                      let ciImage = CIImage(image: image) else {
                    continuation.resume(returning: image)
                    return
                }
                
                // Apply noise reduction filter
                let noiseReductionFilter = CIFilter.noiseReduction()
                noiseReductionFilter.inputImage = ciImage
                noiseReductionFilter.noiseLevel = 0.02
                noiseReductionFilter.sharpness = 0.4
                
                guard let outputImage = noiseReductionFilter.outputImage,
                      let outputCGImage = self.context.createCGImage(outputImage, from: outputImage.extent) else {
                    continuation.resume(returning: image)
                    return
                }
                
                let optimizedImage = UIImage(cgImage: outputCGImage)
                continuation.resume(returning: optimizedImage)
            }
        }
    }
    
    /// Compress image to reduce file size
    private func compressImage(_ image: UIImage) async throws -> UIImage {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                // Start with a reasonable quality
                var compressionQuality: CGFloat = 0.7
                var compressedData = image.jpegData(compressionQuality: compressionQuality)
                
                // Target max size (1.5MB)
                let targetSize: Int = 1_500_000
                
                // Reduce quality until we hit target size or minimum quality
                while let data = compressedData, data.count > targetSize && compressionQuality > 0.3 {
                    compressionQuality -= 0.1
                    compressedData = image.jpegData(compressionQuality: compressionQuality)
                }
                
                if let data = compressedData, let compressedImage = UIImage(data: data) {
                    continuation.resume(returning: compressedImage)
                } else {
                    continuation.resume(returning: image)
                }
            }
        }
    }
    
    /// Batch clean multiple photos
    func batchCleanPhotos(images: [UIImage], progressCallback: ((Double) -> Void)? = nil) async throws -> [UIImage] {
        isProcessing = true
        progress = 0
        defer { 
            isProcessing = false 
            progress = 1.0 
        }
        
        var cleanedImages: [UIImage] = []
        let totalImages = Double(images.count)
        
        for (index, image) in images.enumerated() {
            do {
                let cleaned = try await cleanPhoto(image: image)
                cleanedImages.append(cleaned)
                
                // Update overall progress
                let currentProgress = Double(index + 1) / totalImages
                progress = currentProgress
                progressCallback?(currentProgress)
            } catch {
                // Continue with other images even if one fails
                self.error = error
            }
        }
        
        return cleanedImages
    }
    
    /// Analyze an image and provide suggestions for cleaning
    func analyzeImage(_ image: UIImage) async -> [CleaningSuggestion] {
        guard let cgImage = image.cgImage else { return [] }
        
        var suggestions: [CleaningSuggestion] = []
        
        // Check file size
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            let sizeInMB = Double(imageData.count) / 1_000_000
            if sizeInMB > 2.0 {
                suggestions.append(.largeFileSize(sizeMB: sizeInMB))
            }
        }
        
        // Check image dimensions
        let width = cgImage.width
        let height = cgImage.height
        if width > 4000 || height > 4000 {
            suggestions.append(.highResolution(width: width, height: height))
        }
        
        // Check metadata presence
        // (This is a simplified check - real implementation would be more thorough)
        let ciImage = CIImage(cgImage: cgImage)
        if let exifProperties = ciImage.properties["{Exif}"] as? [String: Any], !exifProperties.isEmpty {
            suggestions.append(.containsMetadata)
        }
        
        return suggestions
    }
}

// MARK: - Cleaning Suggestions
enum CleaningSuggestion {
    case largeFileSize(sizeMB: Double)
    case highResolution(width: Int, height: Int)
    case containsMetadata
    
    var description: String {
        switch self {
        case .largeFileSize(let sizeMB):
            return "Large file size (%.2f MB). Cleaning can reduce size by up to 60%%."
        case .highResolution(let width, let height):
            return "High resolution image (%d x %d). Reducing resolution can save space."
        case .containsMetadata:
            return "Contains metadata that can be removed to improve privacy."
        }
    }
}

// MARK: - Processing Error
enum ImageProcessingError: Error {
    case processingFailed
    case invalidImage
    case compressionFailed
    
    var localizedDescription: String {
        switch self {
        case .processingFailed:
            return "Failed to process the image"
        case .invalidImage:
            return "Invalid or corrupted image"
        case .compressionFailed:
            return "Failed to compress the image"
        }
    }
} 