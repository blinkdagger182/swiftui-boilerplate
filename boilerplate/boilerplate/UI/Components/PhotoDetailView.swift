import SwiftUI
import Photos

struct PhotoDetailView: View {
    // MARK: - Dependencies
    @ObservedObject private var photoManager: PhotoManager
    @ObservedObject private var imageProcessor: ImageProcessorService
    @ObservedObject private var storageManager: LocalStorageManager
    @ObservedObject private var analyticsService: AnalyticsService
    
    // MARK: - Properties
    let asset: PHAsset
    
    @State private var fullSizeImage: UIImage?
    @State private var isLoading = false
    @State private var cleanedImage: UIImage?
    @State private var cleaningSuggestions: [CleaningSuggestion] = []
    @State private var showProcessingSheet = false
    @State private var showSuccessAlert = false
    @State private var processingError: Error?
    @State private var showErrorAlert = false
    
    @State private var originalImageSize: Double = 0
    @State private var cleanedImageSize: Double = 0
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    init(
        asset: PHAsset,
        photoManager: PhotoManager = PhotoManager.shared,
        imageProcessor: ImageProcessorService = ImageProcessorService.shared,
        storageManager: LocalStorageManager = LocalStorageManager.shared,
        analyticsService: AnalyticsService = AnalyticsService.shared
    ) {
        self.asset = asset
        self.photoManager = photoManager
        self.imageProcessor = imageProcessor
        self.storageManager = storageManager
        self.analyticsService = analyticsService
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            if let image = fullSizeImage {
                // Main image view
                Image(uiImage: cleanedImage ?? image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            } else {
                // Loading placeholder
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Photo Details")
        .overlay(
            VStack {
                Spacer()
                
                if !cleaningSuggestions.isEmpty {
                    suggestionView
                }
                
                buttonRow
            }
        )
        .task {
            await loadFullImage()
            await analyzeImage()
        }
        .sheet(isPresented: $showProcessingSheet) {
            processingView
        }
        .alert("Photo Cleaned Successfully", isPresented: $showSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your photo has been cleaned and saved. You saved \(formatBytes(originalImageSize - cleanedImageSize)) of space!")
        }
        .alert("Error Cleaning Photo", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(processingError?.localizedDescription ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Subviews
    
    private var suggestionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cleaning Recommendations")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(cleaningSuggestions, id: \.description) { suggestion in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text(getSuggestionText(suggestion))
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.75))
        )
        .padding()
    }
    
    private var buttonRow: some View {
        HStack(spacing: 20) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: {
                startCleaningProcess()
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Clean Photo")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(
                    Capsule()
                        .fill(Color.blue)
                )
            }
            .disabled(isLoading || cleanedImage != nil)
            
            Spacer()
            
            Button(action: {
                // Share functionality would go here
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .edgesIgnoringSafeArea(.bottom)
        )
    }
    
    private var processingView: some View {
        VStack(spacing: 25) {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Cleaning Photo")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Removing metadata, optimizing quality, and reducing file size...")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ProgressView(value: imageProcessor.progress)
                .progressViewStyle(.linear)
                .frame(width: 250)
                .padding(.top)
            
            Text("\(Int(imageProcessor.progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                showProcessingSheet = false
            }) {
                Text("Cancel")
                    .foregroundColor(.red)
            }
            .disabled(imageProcessor.progress > 0.9)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Methods
    
    private func loadFullImage() async {
        isLoading = true
        defer { isLoading = false }
        
        if let image = await photoManager.loadFullSizeImage(for: asset) {
            fullSizeImage = image
            
            // Calculate original size
            if let imageData = image.jpegData(compressionQuality: 1.0) {
                originalImageSize = Double(imageData.count)
            }
        }
    }
    
    private func analyzeImage() async {
        guard let image = fullSizeImage else { return }
        cleaningSuggestions = await imageProcessor.analyzeImage(image)
    }
    
    private func startCleaningProcess() {
        guard let image = fullSizeImage else { return }
        
        showProcessingSheet = true
        
        let startTime = Date()
        
        Task {
            do {
                let cleaned = try await imageProcessor.cleanPhoto(image: image)
                cleanedImage = cleaned
                
                // Calculate cleaned size
                if let cleanedData = cleaned.jpegData(compressionQuality: 1.0) {
                    cleanedImageSize = Double(cleanedData.count)
                }
                
                // Record cleaning in history
                storageManager.recordPhotoClean(
                    originalSize: originalImageSize,
                    newSize: cleanedImageSize
                )
                
                // Track analytics
                let duration = Date().timeIntervalSince(startTime) * 1000
                analyticsService.trackPhotoProcessing(
                    count: 1,
                    success: true,
                    durationMs: duration
                )
                
                // Save cleaned image
                _ = await photoManager.saveEditedImage(cleaned, from: asset)
                
                showProcessingSheet = false
                showSuccessAlert = true
                
            } catch {
                processingError = error
                showProcessingSheet = false
                showErrorAlert = true
                
                // Track error
                analyticsService.trackError(error)
            }
        }
    }
    
    private func getSuggestionText(_ suggestion: CleaningSuggestion) -> String {
        switch suggestion {
        case .largeFileSize(let sizeMB):
            return String(format: "Large file size (%.1f MB). Cleaning can reduce size by up to 60%.", sizeMB)
        case .highResolution(let width, let height):
            return String(format: "High resolution image (%d x %d). Reducing resolution can save space.", width, height)
        case .containsMetadata:
            return "Contains metadata that can be removed to improve privacy."
        }
    }
    
    private func formatBytes(_ bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#Preview {
    // Mock asset for preview
    let mockAsset = PHAsset()
    
    return NavigationView {
        PhotoDetailView(asset: mockAsset)
    }
} 