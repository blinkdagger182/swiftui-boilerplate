import SwiftUI
import Photos

struct PhotoGridView: View {
    // MARK: - Dependencies
    @ObservedObject private var photoManager: PhotoManager
    
    // MARK: - Properties
    private let columns: [GridItem]
    private let spacing: CGFloat
    private let onPhotoSelected: (PHAsset) -> Void
    
    @State private var selectedAssets: Set<String> = []
    @State private var loadedImages: [String: UIImage] = [:]
    @State private var isMultiSelectMode = false
    
    // MARK: - Initialization
    init(
        photoManager: PhotoManager = PhotoManager.shared,
        columns: Int = 3,
        spacing: CGFloat = 2,
        onPhotoSelected: @escaping (PHAsset) -> Void
    ) {
        self.photoManager = photoManager
        self.spacing = spacing
        self.onPhotoSelected = onPhotoSelected
        
        // Create grid layout
        self.columns = Array(
            repeating: GridItem(.flexible(), spacing: spacing),
            count: columns
        )
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(photoManager.recentPhotos, id: \.localIdentifier) { asset in
                    PhotoGridCell(
                        asset: asset,
                        loadedImage: loadedImages[asset.localIdentifier],
                        isSelected: selectedAssets.contains(asset.localIdentifier),
                        isMultiSelectMode: isMultiSelectMode
                    )
                    .onAppear {
                        loadThumbnail(for: asset)
                    }
                    .onTapGesture {
                        handlePhotoTap(asset)
                    }
                    .onLongPressGesture {
                        enterMultiSelectMode(selecting: asset)
                    }
                }
            }
            .padding(.horizontal, 1)
        }
        .overlay(
            Group {
                if photoManager.isLoading && photoManager.recentPhotos.isEmpty {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
        )
        .toolbar {
            if isMultiSelectMode {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            selectedAssets.removeAll()
                            isMultiSelectMode = false
                        } label: {
                            Label("Cancel", systemImage: "xmark")
                        }
                        
                        Button {
                            selectAll()
                        } label: {
                            Label("Select All", systemImage: "checkmark.circle")
                        }
                    } label: {
                        Text("\(selectedAssets.count) selected")
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func loadThumbnail(for asset: PHAsset) {
        // Skip if already loaded
        guard loadedImages[asset.localIdentifier] == nil else { return }
        
        // Calculate thumbnail size based on screen
        let scale = UIScreen.main.scale
        let cellWidth = UIScreen.main.bounds.width / CGFloat(columns.count) - spacing
        let size = CGSize(width: cellWidth * scale, height: cellWidth * scale)
        
        // Load thumbnail
        Task {
            if let thumbnail = await photoManager.loadThumbnail(for: asset, size: size) {
                await MainActor.run {
                    loadedImages[asset.localIdentifier] = thumbnail
                }
            }
        }
    }
    
    private func handlePhotoTap(_ asset: PHAsset) {
        if isMultiSelectMode {
            toggleSelection(for: asset)
        } else {
            onPhotoSelected(asset)
        }
    }
    
    private func toggleSelection(for asset: PHAsset) {
        if selectedAssets.contains(asset.localIdentifier) {
            selectedAssets.remove(asset.localIdentifier)
            
            // Exit multi-select mode if no items selected
            if selectedAssets.isEmpty {
                isMultiSelectMode = false
            }
        } else {
            selectedAssets.insert(asset.localIdentifier)
        }
    }
    
    private func enterMultiSelectMode(selecting asset: PHAsset) {
        isMultiSelectMode = true
        selectedAssets.insert(asset.localIdentifier)
    }
    
    private func selectAll() {
        for asset in photoManager.recentPhotos {
            selectedAssets.insert(asset.localIdentifier)
        }
    }
}

// MARK: - Photo Grid Cell
struct PhotoGridCell: View {
    // MARK: - Properties
    let asset: PHAsset
    let loadedImage: UIImage?
    let isSelected: Bool
    let isMultiSelectMode: Bool
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            
            if isMultiSelectMode {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.white)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .padding(6)
                .transition(.scale)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(
            RoundedRectangle(cornerRadius: 1)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
        .cornerRadius(1)
    }
}

#Preview {
    NavigationView {
        PhotoGridView { asset in
            print("Selected asset: \(asset.localIdentifier)")
        }
    }
} 