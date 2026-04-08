#if os(iOS)
import StoreKit
import SwiftUI

private struct AppReviewPromptModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("timeSpent") private var timeSpent: Double = 0
    @AppStorage("shouldShowRateAlert") private var shouldShowRateAlert: Bool = true

    @State private var startTime: Date?
    @State private var reviewTask: Task<Void, Never>?

    private let requiredTimeInterval: TimeInterval = 180

    // Hooks the review-tracking lifecycle into the wrapped view.
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

    // Starts or stops tracking as the app moves between active/inactive/background states.
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

    // Resets the active timer window and schedules the prompt once enough time is reached.
    private func startTracking() {
        startTime = Date()
        scheduleReviewPrompt()
    }

    // Stops the timer and accumulates this session's foreground time.
    private func stopTracking() {
        reviewTask?.cancel()

        guard let startTime else { return }
        timeSpent += Date().timeIntervalSince(startTime)
        self.startTime = nil
    }

    // Schedules a delayed review request based on remaining required usage time.
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

    // Presents Apple's in-app review sheet once and then disables future prompts.
    private func requestReview() {
        guard shouldShowRateAlert else { return }
        guard let windowScene = activeWindowScene else { return }

        SKStoreReviewController.requestReview(in: windowScene)
        shouldShowRateAlert = false
        reviewTask?.cancel()
    }

    // Returns the currently foreground-active window scene used by StoreKit.
    private var activeWindowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
    }
}

extension View {
    // Applies the app review prompt behavior to any view.
    func appReviewPrompt() -> some View {
        modifier(AppReviewPromptModifier())
    }
}
#endif
