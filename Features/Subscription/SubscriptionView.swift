import SwiftUI
import RevenueCat

struct SubscriptionView: View {
    // MARK: - Dependencies
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var analyticsService: AnalyticsService
    
    // MARK: - State
    @State private var selectedPlan: Int = 1 // Default to monthly
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Constants
    private let planOptions = ["Weekly", "Monthly", "Yearly"]
    private let savingsText = ["", "Save 30%", "Save 70%"]
    private let planIds = ["weekly_sub", "monthly_sub", "annual_sub"]
    private let planPrices = ["$2.99", "$7.99", "$29.99"]
    private let billingPeriods = ["per week", "per month", "per year"]
    
    // MARK: - Features
    private let features = [
        "Remove metadata from photos",
        "Unlimited photo cleaning",
        "Batch cleaning mode",
        "Priority support",
        "No ads"
    ]
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Title and tagline
                VStack(spacing: 8) {
                    Text("Photo Cleaner Pro")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Unlock all premium features")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Plan selector
                planSelectorView
                
                // Features list
                featuresListView
                
                // Purchase button
                subscribeButtonView
                
                // Restore purchases
                Button("Restore Purchases") {
                    restorePurchases()
                }
                .font(.subheadline)
                .padding(.bottom)
                
                // Terms and conditions
                termsView
            }
            .padding()
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            analyticsService.trackScreen(.subscription)
        }
    }
    
    // MARK: - Subviews
    
    private var planSelectorView: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(0..<planOptions.count, id: \.self) { index in
                    planOption(
                        title: planOptions[index],
                        price: planPrices[index],
                        period: billingPeriods[index],
                        savings: savingsText[index],
                        isSelected: selectedPlan == index
                    )
                    .onTapGesture {
                        selectedPlan = index
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    private func planOption(
        title: String,
        price: String,
        period: String,
        savings: String,
        isSelected: Bool
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(price)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(period)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if !savings.isEmpty {
                Text(savings)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.green)
                    )
            }
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(isSelected ? .blue : .gray)
                .padding(.leading, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
                )
        )
    }
    
    private var featuresListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's Included")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text(feature)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.bottom)
        }
    }
    
    private var subscribeButtonView: some View {
        Button(action: {
            purchase()
        }) {
            HStack {
                Text("Subscribe Now")
                    .fontWeight(.bold)
                
                Image(systemName: "arrow.right")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
            )
            .foregroundColor(.white)
        }
        .padding(.vertical)
    }
    
    private var termsView: some View {
        VStack(spacing: 8) {
            Text("By subscribing, you agree to our Terms and Privacy Policy")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func purchase() {
        isLoading = true
        
        Task {
            do {
                let selectedPlanId = planIds[selectedPlan]
                let result = try await subscriptionManager.purchase(productId: selectedPlanId)
                
                await MainActor.run {
                    isLoading = false
                    
                    if result {
                        // Track successful purchase
                        analyticsService.trackEvent(.subscriptionChanged, properties: [
                            "plan": planOptions[selectedPlan],
                            "product_id": selectedPlanId
                        ])
                        
                        dismiss()
                    } else {
                        errorMessage = "Purchase could not be completed"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                    
                    // Track error
                    analyticsService.trackError(error, additionalInfo: [
                        "context": "subscription_purchase",
                        "plan": planOptions[selectedPlan]
                    ])
                }
            }
        }
    }
    
    private func restorePurchases() {
        isLoading = true
        
        Task {
            do {
                let result = try await subscriptionManager.restorePurchases()
                
                await MainActor.run {
                    isLoading = false
                    
                    if result {
                        // Track successful restore
                        analyticsService.trackEvent(.subscriptionChanged, properties: [
                            "action": "restore_purchases",
                            "success": true
                        ])
                        
                        dismiss()
                    } else {
                        errorMessage = "No purchases to restore"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                    
                    // Track error
                    analyticsService.trackError(error, additionalInfo: [
                        "context": "restore_purchases"
                    ])
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        SubscriptionView()
            .environmentObject(SubscriptionManager.shared)
            .environmentObject(AnalyticsService.shared)
    }
} 