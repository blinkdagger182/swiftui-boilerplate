import SwiftUI
import Photos

struct MainScreenView: View {
    // MARK: - Dependencies
    @ObservedObject private var photoManager: PhotoManager
    @ObservedObject private var storageManager: LocalStorageManager
    @ObservedObject private var analyticsService: AnalyticsService
    
    // MARK: - State
    @State private var selectedTab = 0
    @State private var showPhotoDetail = false
    @State private var selectedAsset: PHAsset?
    @State private var showPermissionAlert = false
    @State private var cleaningStats: CleaningStats?
    @State private var isLoading = false
    
    // MARK: - Initialization
    init(
        photoManager: PhotoManager = PhotoManager.shared,
        storageManager: LocalStorageManager = LocalStorageManager.shared,
        analyticsService: AnalyticsService = AnalyticsService.shared
    ) {
        self.photoManager = photoManager
        self.storageManager = storageManager
        self.analyticsService = analyticsService
    }
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationView {
                homeView
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Photos Tab
            NavigationView {
                photosView
            }
            .tabItem {
                Label("Photos", systemImage: "photo.on.rectangle")
            }
            .tag(1)
            
            // Stats Tab
            NavigationView {
                statsView
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            .tag(2)
            
            // Settings Tab
            NavigationView {
                settingsView
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
        .navigationViewStyle(.stack)
        .onAppear {
            checkPhotoPermission()
            loadCleaningStats()
            trackTabView()
        }
        .onChange(of: selectedTab) { _ in
            trackTabView()
        }
        .sheet(isPresented: $showPhotoDetail) {
            if let asset = selectedAsset {
                NavigationView {
                    PhotoDetailView(asset: asset)
                }
            }
        }
        .alert("Photo Access Required", isPresented: $showPermissionAlert) {
            Button("Open Settings", action: openSettings)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Photo Cleaner needs access to your photos to work. Please grant access in Settings.")
        }
    }
    
    // MARK: - Home View
    private var homeView: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                if isLoading {
                    ProgressView()
                        .padding()
                } else {
                    // Quick Actions
                    actionSection
                    
                    // Recent Activity
                    recentSection
                    
                    // Cleaning Stats Summary
                    statsSection
                }
            }
            .padding()
        }
        .navigationTitle("Photo Cleaner")
        .refreshable {
            await refreshData()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .padding(.bottom, 8)
            
            Text("Welcome to Photo Cleaner")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Clean your photos to save space and protect privacy")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
            
            HStack(spacing: 16) {
                // Smart Clean Button
                VStack {
                    Button(action: {
                        selectedTab = 1 // Navigate to Photos tab
                    }) {
                        Image(systemName: "sparkles.rectangle.stack")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Text("Smart Clean")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                // Batch Clean Button
                VStack {
                    Button(action: {
                        selectedTab = 1 // Navigate to Photos tab
                    }) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    
                    Text("Batch Clean")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                // Scanner Button
                VStack {
                    Button(action: {
                        // Scanner would go here
                    }) {
                        Image(systemName: "doc.viewfinder")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                    
                    Text("Scan")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                // Settings Button
                VStack {
                    Button(action: {
                        selectedTab = 3 // Navigate to Settings tab
                    }) {
                        Image(systemName: "gear")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.gray)
                            .cornerRadius(12)
                    }
                    
                    Text("Settings")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Photos")
                .font(.headline)
            
            if photoManager.recentPhotos.isEmpty {
                Text("No recent photos found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(photoManager.recentPhotos.prefix(5), id: \.localIdentifier) { asset in
                            recentPhotoView(for: asset)
                                .onTapGesture {
                                    selectedAsset = asset
                                    showPhotoDetail = true
                                }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(height: 120)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cleaning Stats")
                .font(.headline)
            
            if let stats = cleaningStats {
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(stats.totalPhotosCleaned)")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Photos Cleaned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    VStack(spacing: 4) {
                        Text(stats.spaceSavedFormatted)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Space Saved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                Text("No cleaning stats available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // Helper for recent photos
    private func recentPhotoView(for asset: PHAsset) -> some View {
        AsyncPhotoView(asset: asset, size: CGSize(width: 120, height: 120))
            .frame(width: 100, height: 100)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
    
    // MARK: - Photos View
    private var photosView: some View {
        Group {
            if photoManager.authorizationStatus == .authorized || photoManager.authorizationStatus == .limited {
                if photoManager.isLoading {
                    ProgressView()
                } else if photoManager.recentPhotos.isEmpty {
                    Text("No photos found")
                        .foregroundColor(.secondary)
                } else {
                    PhotoGridView { asset in
                        selectedAsset = asset
                        showPhotoDetail = true
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 70))
                        .foregroundColor(.gray)
                    
                    Text("Photo Access Required")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("To show and clean your photos, we need permission to access your photo library.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button("Grant Permission") {
                        Task {
                            _ = await photoManager.requestAccess()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
                .padding()
            }
        }
        .navigationTitle("Your Photos")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await photoManager.fetchRecentPhotos()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
    
    // MARK: - Stats View
    private var statsView: some View {
        VStack {
            if let stats = cleaningStats {
                VStack(spacing: 24) {
                    // Cleaning Summary
                    VStack(spacing: 12) {
                        Text("Cleaning Summary")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 30) {
                            statItem(
                                value: "\(stats.totalPhotosCleaned)",
                                label: "Photos Cleaned",
                                icon: "photo.stack"
                            )
                            
                            statItem(
                                value: stats.spaceSavedFormatted,
                                label: "Space Saved",
                                icon: "externaldrive"
                            )
                        }
                        
                        if let lastDate = stats.lastCleanDate {
                            Text("Last cleaned: \(lastDate, formatter: dateFormatter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                    )
                    
                    // Placeholder for a chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cleaning History")
                            .font(.headline)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .overlay(
                                Text("Chart would display here")
                                    .foregroundColor(.secondary)
                            )
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                    )
                }
                .padding()
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.gray)
                    
                    Text("No Stats Available")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Start cleaning photos to see your stats here.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding()
            }
        }
        .navigationTitle("Statistics")
        .refreshable {
            loadCleaningStats()
        }
    }
    
    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.blue)
                .padding(.bottom, 4)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 120)
    }
    
    // MARK: - Settings View
    private var settingsView: some View {
        List {
            Section("Appearance") {
                NavigationLink(destination: Text("Theme Settings")) {
                    Label("Theme", systemImage: "paintbrush")
                }
                
                NavigationLink(destination: Text("Appearance Settings")) {
                    Label("App Icon", systemImage: "app")
                }
            }
            
            Section("Cleaning Options") {
                NavigationLink(destination: Text("Quality Settings")) {
                    Label("Cleaning Quality", systemImage: "slider.horizontal.3")
                }
                
                Toggle(isOn: .constant(true)) {
                    Label("Save to Album", systemImage: "photo.on.rectangle")
                }
                
                Toggle(isOn: .constant(true)) {
                    Label("Face Detection", systemImage: "face.dashed")
                }
            }
            
            Section("Account") {
                NavigationLink(destination: Text("Subscription")) {
                    Label("Subscription", systemImage: "creditcard")
                }
                
                NavigationLink(destination: Text("Data & Privacy")) {
                    Label("Privacy", systemImage: "hand.raised")
                }
            }
            
            Section("Support") {
                NavigationLink(destination: Text("Help Center")) {
                    Label("Help Center", systemImage: "questionmark.circle")
                }
                
                NavigationLink(destination: Text("About")) {
                    Label("About", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Settings")
    }
    
    // MARK: - Methods
    
    private func checkPhotoPermission() {
        photoManager.checkAuthorizationStatus()
        
        if photoManager.authorizationStatus == .notDetermined {
            Task {
                _ = await photoManager.requestAccess()
            }
        } else if photoManager.authorizationStatus == .denied || photoManager.authorizationStatus == .restricted {
            showPermissionAlert = true
        } else {
            Task {
                await photoManager.fetchRecentPhotos()
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func loadCleaningStats() {
        isLoading = true
        cleaningStats = storageManager.getCleaningStats()
        isLoading = false
    }
    
    private func refreshData() async {
        isLoading = true
        defer { isLoading = false }
        
        if photoManager.authorizationStatus == .authorized || photoManager.authorizationStatus == .limited {
            await photoManager.fetchRecentPhotos()
        }
        
        loadCleaningStats()
    }
    
    private func trackTabView() {
        var screen: Screen
        switch selectedTab {
        case 0:
            screen = .home
        case 1:
            screen = .photoGallery
        case 2:
            screen = .about // Using "about" for stats since there's no direct match
        case 3:
            screen = .settings
        default:
            screen = .home
        }
        
        analyticsService.trackScreen(screen)
    }
    
    // MARK: - Helpers
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - AsyncPhotoView
struct AsyncPhotoView: View {
    // MARK: - Properties
    let asset: PHAsset
    let size: CGSize
    let contentMode: PHImageContentMode
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    // MARK: - Initialization
    init(
        asset: PHAsset,
        size: CGSize,
        contentMode: PHImageContentMode = .aspectFill
    ) {
        self.asset = asset
        self.size = size
        self.contentMode = contentMode
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.gray)
                        }
                    }
            }
        }
        .task {
            await loadImage()
        }
    }
    
    // MARK: - Methods
    private func loadImage() async {
        isLoading = true
        defer { isLoading = false }
        
        let thumbnail = await PhotoManager.shared.loadThumbnail(
            for: asset,
            size: size,
            contentMode: contentMode
        )
        
        await MainActor.run {
            self.image = thumbnail
        }
    }
}

#Preview {
    MainScreenView()
} 