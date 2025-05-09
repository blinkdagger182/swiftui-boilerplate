import SwiftUI

struct UpdatePromptView: View {
    @EnvironmentObject private var updateService: UpdateService
    @Environment(\.openURL) private var openURL
    
    var isForceUpdate: Bool
    var notes: String
    var onDismiss: () -> Void
    
    // App Store URL - replace with your actual app URL in production
    private let appStoreURL = URL(string: "https://apps.apple.com/app/id123456789")!
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding(.top, 20)
            
            Text(isForceUpdate ? "Update Required" : "Update Available")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("What's new:")
                    .font(.headline)
                
                Text(notes)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                
                if isForceUpdate {
                    Text("This update is required to continue using the app.")
                        .font(.callout)
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                if !isForceUpdate {
                    Button("Later") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
                
                Button(isForceUpdate ? "Update Now" : "Update") {
                    openURL(appStoreURL)
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .padding()
        .frame(width: 300, height: 400)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 10)
        )
    }
}

#Preview {
    UpdatePromptView(
        isForceUpdate: false,
        notes: "Version 1.2.0\n- New features added\n- Bug fixes\n- Performance improvements",
        onDismiss: {}
    )
    .environmentObject(UpdateService.shared)
    .preferredColorScheme(.light)
} 