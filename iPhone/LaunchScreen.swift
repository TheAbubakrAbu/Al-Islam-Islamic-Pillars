import SwiftUI

struct LaunchScreen: View {
    @EnvironmentObject var settings: Settings
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.customColorScheme) private var customColorScheme

    @Binding var isLaunching: Bool

    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var gradientSize: CGFloat = 0.8
    @State private var glowOpacity: Double = 0.0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0.0
    @State private var logoRotation: Double = -8
    @State private var logoYOffset: CGFloat = 18
    @State private var textOffset: CGFloat = 10
    @State private var shimmerOffset: CGFloat = -220
    @State private var glassFloat: CGFloat = 0
    @State private var glassTilt: Double = 0
    @State private var glassOpacity: Double = 0.0
    @State private var leftGlassOffset: CGFloat = 0
    @State private var rightGlassOffset: CGFloat = 0
    @State private var contentBlur: CGFloat = 0

    var body: some View {
        ZStack {
            LaunchScreenBackground(
                backgroundColor: backgroundColor,
                accentColor: settings.accentColor.color,
                isDarkMode: currentColorScheme == .dark,
                gradientSize: gradientSize,
                glowOpacity: glowOpacity,
                ringScale: ringScale,
                ringOpacity: ringOpacity
            )

            companionCards
            logoCard
        }
        .onAppear {
            Task { @MainActor in
                await runLaunchAnimation()
            }
        }
        .blur(radius: contentBlur)
    }

    private var currentColorScheme: ColorScheme {
        settings.colorScheme ?? systemColorScheme
    }

    private var backgroundColor: Color {
        switch currentColorScheme {
        case .light:
            return .white
        case .dark:
            return .black
        @unknown default:
            return .white
        }
    }

    private var companionCards: some View {
        ZStack {
            LaunchCompanionCard(
                imageName: "Al-Adhan",
                accentColor: settings.accentColor.color,
                isDarkMode: currentColorScheme == .dark,
                width: 120,
                height: 120,
                cornerRadius: 32,
                imageInset: 10,
                opacity: glassOpacity * 0.58
            )
            .rotationEffect(.degrees(-glassTilt * 0.8))
            .offset(x: -74 + leftGlassOffset, y: glassFloat + 4)

            LaunchCompanionCard(
                imageName: "Al-Quran",
                accentColor: settings.accentColor.color,
                isDarkMode: currentColorScheme == .dark,
                width: 120,
                height: 120,
                cornerRadius: 32,
                imageInset: 10,
                opacity: glassOpacity
            )
            .rotationEffect(.degrees(glassTilt))
            .offset(x: 80 + rightGlassOffset, y: glassFloat + 4)
        }
    }

    private var logoCard: some View {
        VStack {
            VStack {
                LaunchLogoCard(
                    accentColor: settings.accentColor.color,
                    isDarkMode: currentColorScheme == .dark,
                    shimmerOffset: shimmerOffset
                )
                .rotationEffect(.degrees(logoRotation))
                .offset(y: logoYOffset)
                .padding()
            }
            .foregroundColor(settings.accentColor.color)
            .scaleEffect(size)
            .opacity(opacity)
        }
    }

    @MainActor
    private func runLaunchAnimation() async {
        triggerHapticFeedback(.soft)

        withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
            size = 0.94
            opacity = 1.0
            gradientSize = 3.4
            glowOpacity = 1.0
            ringScale = 1.08
            ringOpacity = 1.0
            logoRotation = 0
            logoYOffset = 0
            textOffset = 0
            glassFloat = 2
            glassTilt = 0
            glassOpacity = 0.0
            leftGlassOffset = 0
            rightGlassOffset = 0
        }

        withAnimation(.easeInOut(duration: 0.8)) {
            shimmerOffset = 220
        }

        try? await Task.sleep(nanoseconds: 800_000_000)

        triggerHapticFeedback(.soft)
        withAnimation(.easeOut(duration: 0.5)) {
            size = 0.88
            gradientSize = 2.8
            ringScale = 1.18
            ringOpacity = 0.0
            glowOpacity = 0.72
            glassFloat = 0
            glassTilt = 0
            glassOpacity = 0.0
            leftGlassOffset = 0
            rightGlassOffset = 0
        }

        await QuranData.shared.waitUntilLoaded()

        withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
            glassFloat = -10
            glassTilt = 7
            glassOpacity = 1.0
            leftGlassOffset = -34
            rightGlassOffset = 34
        }

        try? await Task.sleep(nanoseconds: 650_000_000)

        withAnimation {
            triggerHapticFeedback(.soft)
            isLaunching = false
        }
    }

    private func triggerHapticFeedback(_ feedbackType: HapticFeedbackType) {
        guard settings.hapticOn else { return }

        #if !os(watchOS)
        switch feedbackType {
        case .soft:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        #else
        WKInterfaceDevice.current().play(.click)
        #endif
    }

    enum HapticFeedbackType {
        case soft
        case light
        case medium
        case heavy
    }
}

private struct LaunchScreenBackground: View {
    let backgroundColor: Color
    let accentColor: Color
    let isDarkMode: Bool
    let gradientSize: CGFloat
    let glowOpacity: Double
    let ringScale: CGFloat
    let ringOpacity: Double

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    accentColor.opacity(isDarkMode ? 0.18 : 0.08),
                    .clear,
                    Color.cyan.opacity(isDarkMode ? 0.12 : 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    accentColor.opacity(0.45),
                    accentColor.opacity(0.12),
                    .clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 220
            )
            .scaleEffect(gradientSize * 1.15)
            .blur(radius: 12)
            .opacity(glowOpacity)

            LinearGradient(
                colors: [
                    accentColor.opacity(0.18),
                    accentColor.opacity(0.45),
                    Color.cyan.opacity(isDarkMode ? 0.18 : 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(Circle())
            .frame(width: 420, height: 420)
            .scaleEffect(gradientSize)
            .blur(radius: 6)

            Circle()
                .stroke(accentColor.opacity(0.18), lineWidth: 1.5)
                .frame(width: 210, height: 210)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            Circle()
                .stroke(Color.white.opacity(isDarkMode ? 0.12 : 0.2), lineWidth: 1)
                .frame(width: 260, height: 260)
                .scaleEffect(ringScale * 0.96)
                .opacity(ringOpacity * 0.75)
        }
    }
}

private struct LaunchLogoCard: View {
    let accentColor: Color
    let isDarkMode: Bool
    let shimmerOffset: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                #if !os(watchOS)
                .fill(.ultraThinMaterial.opacity(isDarkMode ? 0.45 : 0.7))
                #endif
                .frame(width: 170, height: 170)
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.55),
                                    accentColor.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: accentColor.opacity(0.22), radius: 24, y: 10)
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isDarkMode ? 0.18 : 0.34),
                                    Color.white.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 54)
                        .blur(radius: 0.3)
                        .padding(12)
                }

            Image("Al-Islam")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(24)
                .frame(maxWidth: 146, maxHeight: 146)
                .overlay(alignment: .topLeading) {
                    LinearGradient(
                        colors: [
                            .white.opacity(0.0),
                            .white.opacity(0.32),
                            .white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .rotationEffect(.degrees(22))
                    .offset(x: shimmerOffset)
                    .blendMode(.screen)
                    .mask(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .frame(width: 146, height: 146)
                    )
                }
        }
    }
}

private struct LaunchCompanionCard: View {
    let imageName: String
    let accentColor: Color
    let isDarkMode: Bool
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let imageInset: CGFloat
    let opacity: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                #if !os(watchOS)
                .fill(.ultraThinMaterial.opacity(isDarkMode ? 0.22 : 0.38))
                #else
                .fill(Color.white.opacity(isDarkMode ? 0.08 : 0.16))
                #endif
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(isDarkMode ? 0.12 : 0.24), lineWidth: 1)
                )

            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(max(18, cornerRadius - 8))
                .padding(imageInset)
        }
        .frame(width: width, height: height)
        .opacity(opacity)
    }
}
