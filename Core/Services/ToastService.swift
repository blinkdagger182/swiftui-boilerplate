import Foundation
import SwiftUI
import Combine

// MARK: - Toast Type
enum ToastType {
    case success
    case error
    case info
    case warning
    
    var color: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        case .info:
            return .blue
        case .warning:
            return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.circle.fill"
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Toast Item
struct ToastItem: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let title: String
    let message: String
    let duration: TimeInterval
    
    static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast Service
@MainActor
class ToastService: ObservableObject {
    // MARK: - Singleton
    static let shared = ToastService()
    
    // MARK: - Published Properties
    @Published var currentToast: ToastItem?
    @Published var isShowing = false
    
    // MARK: - Properties
    private var toastQueue: [ToastItem] = []
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        // Set up observation for isShowing
        $isShowing
            .removeDuplicates()
            .sink { [weak self] isShowing in
                if !isShowing {
                    self?.processQueue()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Show a success toast
    func showSuccess(title: String, message: String = "", duration: TimeInterval = 3.0) {
        show(type: .success, title: title, message: message, duration: duration)
    }
    
    /// Show an error toast
    func showError(title: String, message: String = "", duration: TimeInterval = 4.0) {
        show(type: .error, title: title, message: message, duration: duration)
    }
    
    /// Show an info toast
    func showInfo(title: String, message: String = "", duration: TimeInterval = 3.0) {
        show(type: .info, title: title, message: message, duration: duration)
    }
    
    /// Show a warning toast
    func showWarning(title: String, message: String = "", duration: TimeInterval = 3.5) {
        show(type: .warning, title: title, message: message, duration: duration)
    }
    
    /// Show a toast with the specified parameters
    func show(type: ToastType, title: String, message: String = "", duration: TimeInterval = 3.0) {
        let toastItem = ToastItem(type: type, title: title, message: message, duration: duration)
        
        toastQueue.append(toastItem)
        
        // If no toast is currently showing, process the queue immediately
        if !isShowing {
            processQueue()
        }
    }
    
    /// Dismiss the current toast
    func dismiss() {
        isShowing = false
        currentToast = nil
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Private Methods
    
    private func processQueue() {
        guard !toastQueue.isEmpty else { return }
        
        let toastItem = toastQueue.removeFirst()
        currentToast = toastItem
        isShowing = true
        
        // Schedule automatic dismissal
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: toastItem.duration, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let toast: ToastItem
    @State private var opacity: Double = 0
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 24))
                .foregroundColor(toast.type.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(.headline)
                
                if !toast.message.isEmpty {
                    Text(toast.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @ObservedObject var toastService: ToastService
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if toastService.isShowing, let toast = toastService.currentToast {
                VStack {
                    Spacer()
                    ToastView(toast: toast)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(), value: toastService.isShowing)
                        .onTapGesture {
                            toastService.dismiss()
                        }
                }
                .ignoresSafeArea()
                .zIndex(100)
            }
        }
    }
}

// MARK: - View Extension
extension View {
    func toastView(service: ToastService = ToastService.shared) -> some View {
        modifier(ToastModifier(toastService: service))
    }
} 