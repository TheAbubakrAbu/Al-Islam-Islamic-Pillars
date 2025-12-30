import SwiftUI
import StoreKit

private struct AppReviewPromptModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("timeSpent") private var timeSpent: Double = 0
    @AppStorage("shouldShowRateAlert") private var shouldShowRateAlert: Bool = true
    
    @State private var startTime: Date?
    @State private var reviewTask: Task<Void, Never>?
    
    private let requiredTimeInterval: TimeInterval = 180 // 3 minutes
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if shouldShowRateAlert {
                    startTracking()
                }
            }
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .active:
                    if shouldShowRateAlert {
                        startTracking()
                    }
                    
                case .background, .inactive:
                    stopTracking()
                    
                @unknown default:
                    break
                }
            }
            .onDisappear {
                reviewTask?.cancel()
            }
    }
    
    private func startTracking() {
        startTime = Date()
        scheduleReviewPrompt()
    }
    
    private func stopTracking() {
        reviewTask?.cancel()
        
        if let startTime = startTime {
            timeSpent += Date().timeIntervalSince(startTime)
            self.startTime = nil
        }
    }
    
    private func scheduleReviewPrompt() {
        let remainingTime = max(requiredTimeInterval - timeSpent, 0)
        
        reviewTask?.cancel()
        reviewTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                requestReview()
            }
        }
    }
    
    private func requestReview() {
        guard shouldShowRateAlert else { return }
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }
        
        SKStoreReviewController.requestReview(in: windowScene)
        shouldShowRateAlert = false
        reviewTask?.cancel()
    }
}

extension View {
    func appReviewPrompt() -> some View {
        modifier(AppReviewPromptModifier())
    }
}
