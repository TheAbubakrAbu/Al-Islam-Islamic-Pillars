import StoreKit
import SwiftUI

private struct AppReviewPromptModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("timeSpent") private var timeSpent: Double = 0
    @AppStorage("shouldShowRateAlert") private var shouldShowRateAlert: Bool = true

    @State private var startTime: Date?
    @State private var reviewTask: Task<Void, Never>?

    private let requiredTimeInterval: TimeInterval = 180

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard shouldShowRateAlert else { return }
                startTracking()
            }
            .onChange(of: scenePhase) { newPhase in
                handleScenePhaseChange(newPhase)
            }
            .onDisappear {
                reviewTask?.cancel()
            }
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            guard shouldShowRateAlert else { return }
            startTracking()
        case .background, .inactive:
            stopTracking()
        @unknown default:
            break
        }
    }

    private func startTracking() {
        startTime = Date()
        scheduleReviewPrompt()
    }

    private func stopTracking() {
        reviewTask?.cancel()

        guard let startTime else { return }
        timeSpent += Date().timeIntervalSince(startTime)
        self.startTime = nil
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
        guard let windowScene = activeWindowScene else { return }

        SKStoreReviewController.requestReview(in: windowScene)
        shouldShowRateAlert = false
        reviewTask?.cancel()
    }

    private var activeWindowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
    }
}

extension View {
    func appReviewPrompt() -> some View {
        modifier(AppReviewPromptModifier())
    }
}
