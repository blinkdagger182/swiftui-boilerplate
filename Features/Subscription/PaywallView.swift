import SwiftUI
import RevenueCat

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var coordinator: CoordinatorManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var offering: Offering?
    @State private var selectedPackage: Package?
    @State private var isLoading: Bool = true
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    // For UI animation
    @State private var animatingBackground = false
    
    var body: some View {
        ZStack {
            // Animated background
            LinearGradient(
                gradient: Gradient(colors: [.indigo.opacity(0.7), .purple.opacity(0.7)]),
                startPoint: animatingBackground ? .topLeading : .bottomTrailing,
                endPoint: animatingBackground ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(Animation.easeInOut(duration: 5.0).repeatForever(autoreverses: true), value: animatingBackground)
            .onAppear {
                animatingBackground = true
            }
            
            // Content
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    headerView
                    
                    // Features list
                    featuresListView
                    
                    // Plans
                    if let offering = offering {
                        packagesView(offering: offering)
                    } else if isLoading {
                        loadingView
                    } else {
                        errorView
                    }
                    
                    // Restore purchases
                    restorePurchasesButton
                    
                    // Privacy & Terms
                    legalLinksView
                }
                .padding()
            }
            
            // Loading overlay
            if subscriptionManager.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .navigationTitle("Premium Features")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .onAppear {
            Task {
                isLoading = true
                offering = await subscriptionManager.getCurrentOffering()
                isLoading = false
                
                if subscriptionManager.isPremium {
                    dismiss()
                }
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK")) {
                    errorMessage = ""
                }
            )
        }
        .onChange(of: subscriptionManager.errorMessage) { newValue in
            if let error = newValue {
                errorMessage = error
                showError = true
                subscriptionManager.clearError()
            }
        }
    }
    
    // MARK: - Sub Views
    
    private var headerView: some View {
        VStack(spacing: 15) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.white)
                .padding()
            
            Text("Unlock Premium")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Get unlimited access to all features")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 30)
    }
    
    private var featuresListView: some View {
        VStack(alignment: .leading, spacing: 15) {
            FeatureItem(icon: "checkmark.circle.fill", text: "Full access to all premium features")
            FeatureItem(icon: "checkmark.circle.fill", text: "No advertisements")
            FeatureItem(icon: "checkmark.circle.fill", text: "Priority customer support")
            FeatureItem(icon: "checkmark.circle.fill", text: "Regular updates with new features")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
        )
        .padding(.horizontal)
    }
    
    private func packagesView(offering: Offering) -> some View {
        VStack(spacing: 12) {
            ForEach(offering.availablePackages, id: \.identifier) { package in
                PackageView(
                    package: package,
                    isSelected: selectedPackage?.identifier == package.identifier,
                    onSelect: {
                        withAnimation {
                            selectedPackage = package
                        }
                        
                        Task {
                            await purchasePackage(package)
                        }
                    }
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
                .padding()
            
            Text("Loading subscription options...")
                .foregroundColor(.white)
        }
        .frame(height: 200)
    }
    
    private var errorView: some View {
        VStack {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.white)
                .padding()
            
            Text("Failed to load subscription options")
                .foregroundColor(.white)
            
            Button("Retry") {
                Task {
                    isLoading = true
                    offering = await subscriptionManager.getCurrentOffering()
                    isLoading = false
                }
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
            .foregroundColor(.white)
            .padding(.top)
        }
        .frame(height: 200)
    }
    
    private var restorePurchasesButton: some View {
        Button("Restore Purchases") {
            Task {
                await subscriptionManager.restorePurchases()
                
                if subscriptionManager.isPremium {
                    dismiss()
                }
            }
        }
        .font(.footnote)
        .foregroundColor(.white.opacity(0.8))
        .padding(.top)
    }
    
    private var legalLinksView: some View {
        HStack(spacing: 20) {
            Link("Privacy Policy", destination: URL(string: "https://www.example.com/privacy")!)
            Link("Terms of Use", destination: URL(string: "https://www.example.com/terms")!)
        }
        .font(.caption)
        .foregroundColor(.white.opacity(0.7))
        .padding(.bottom, 20)
    }
    
    // MARK: - Methods
    
    private func purchasePackage(_ package: Package) async {
        subscriptionManager.isLoading = true
        
        do {
            let purchaseResult = try await Purchases.shared.purchase(package: package)
            
            if purchaseResult.customerInfo.entitlements[subscriptionManager.errorMessage] != nil {
                dismiss()
            }
            
            subscriptionManager.isLoading = false
        } catch {
            subscriptionManager.isLoading = false
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Helper Views

struct FeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.system(size: 18, weight: .bold))
            
            Text(text)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct PackageView: View {
    let package: Package
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(packageTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(packageDescription)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Text(package.localizedPriceString)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private var packageTitle: String {
        switch package.packageType {
        case .monthly:
            return "Monthly"
        case .annual:
            return "Annual"
        case .lifetime:
            return "Lifetime"
        default:
            return package.identifier
        }
    }
    
    private var packageDescription: String {
        switch package.packageType {
        case .monthly:
            return "Billed monthly"
        case .annual:
            return "Save 40%, billed annually"
        case .lifetime:
            return "One-time purchase"
        default:
            return ""
        }
    }
}

#Preview {
    NavigationStack {
        PaywallView()
            .environmentObject(SubscriptionManager.shared)
            .environmentObject(CoordinatorManager.shared)
    }
} 