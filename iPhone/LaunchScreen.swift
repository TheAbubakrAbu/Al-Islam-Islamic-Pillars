import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Scales launch / splash hero UI on iPad so glows and icons fill the canvas.
enum LaunchScreenLayout {
    static func scale(for containerSize: CGSize) -> CGFloat {
        let d = min(containerSize.width, containerSize.height)
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return max(1.38, min(d / 410, 2.45))
        }
        #endif
        return 1.0
    }
}

struct LaunchScreen: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer
    @EnvironmentObject var namesData: NamesViewModel
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
        GeometryReader { geo in
            let layoutScale = LaunchScreenLayout.scale(for: geo.size)
            ZStack {
                LaunchScreenBackground(
                    backgroundColor: backgroundColor,
                    accentColor: settings.accentColor.color,
                    isDarkMode: currentColorScheme == .dark,
                    gradientSize: gradientSize,
                    glowOpacity: glowOpacity,
                    ringScale: ringScale,
                    ringOpacity: ringOpacity,
                    layoutScale: layoutScale
                )

                #if os(iOS)
                companionCards(layoutScale: layoutScale)
                #endif
                
                logoCard(layoutScale: layoutScale)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
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

    private func companionCards(layoutScale: CGFloat) -> some View {
        ZStack {
            let card: CGFloat = 120 * layoutScale
            let cr = 32 * layoutScale
            let inset = 10 * layoutScale
            
            LaunchCompanionCard(
                imageName: "Al-Adhan",
                accentColor: settings.accentColor.color,
                isDarkMode: currentColorScheme == .dark,
                width: card,
                height: card,
                cornerRadius: cr,
                imageInset: inset,
                opacity: glassOpacity * 0.58
            )
            .rotationEffect(.degrees(-glassTilt * 0.8))
            .offset(x: (-74 + leftGlassOffset) * layoutScale, y: glassFloat + 4 * layoutScale)

            LaunchCompanionCard(
                imageName: "Al-Quran",
                accentColor: settings.accentColor.color,
                isDarkMode: currentColorScheme == .dark,
                width: card,
                height: card,
                cornerRadius: cr,
                imageInset: inset,
                opacity: glassOpacity
            )
            .rotationEffect(.degrees(glassTilt))
            .offset(x: (80 + rightGlassOffset) * layoutScale, y: glassFloat + 4 * layoutScale)
        }
    }

    private func logoCard(layoutScale: CGFloat) -> some View {
        VStack {
            VStack {
                LaunchLogoCard(
                    title: "Al-Islam",
                    accentColor: settings.accentColor.color,
                    isDarkMode: currentColorScheme == .dark,
                    shimmerOffset: shimmerOffset,
                    layoutScale: layoutScale
                )
                .rotationEffect(.degrees(logoRotation))
                .offset(y: logoYOffset)
                .padding(16 * layoutScale)
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

        async let settingsReady: Void = Settings.shared.waitUntilReady()
        async let quranReady: Void = {
            if QuranData.shared.shouldWaitForFullLaunchReadiness {
                await QuranData.shared.waitUntilLoaded()
            } else {
                await QuranData.shared.waitUntilCoreLoaded()
            }
        }()
        async let playerReady: Void = QuranPlayer.shared.waitUntilReady()
        async let namesReady: Void = NamesViewModel.shared.waitUntilLoaded()
        _ = await (settingsReady, quranReady, playerReady, namesReady)

        triggerHapticFeedback(.soft)
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

        #if os(iOS)
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

struct LaunchScreenBackground: View {
    let backgroundColor: Color
    let accentColor: Color
    let isDarkMode: Bool
    let gradientSize: CGFloat
    let glowOpacity: Double
    let ringScale: CGFloat
    let ringOpacity: Double
    var layoutScale: CGFloat = 1

    var body: some View {
        let s = layoutScale
        let radialEnd = 220 * s
        let disk: CGFloat = 420 * s
        let ringInner: CGFloat = 210 * s
        let ringOuter: CGFloat = 260 * s
        let blurMain = max(12, 10 * s)
        let blurDisk = max(6, 5 * s)

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
                startRadius: 20 * s,
                endRadius: radialEnd
            )
            .scaleEffect(gradientSize * 1.15)
            .blur(radius: blurMain)
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
            .contentShape(Circle())
            .frame(width: disk, height: disk)
            .scaleEffect(gradientSize)
            .blur(radius: blurDisk)

            Circle()
                .stroke(accentColor.opacity(0.18), lineWidth: max(1.5, 1.2 * s))
                .frame(width: ringInner, height: ringInner)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            Circle()
                .stroke(Color.white.opacity(isDarkMode ? 0.12 : 0.2), lineWidth: max(1, 0.9 * s))
                .frame(width: ringOuter, height: ringOuter)
                .scaleEffect(ringScale * 0.96)
                .opacity(ringOpacity * 0.75)
        }
    }
}

struct LaunchLogoCard: View {
    let title: String
    let accentColor: Color
    let isDarkMode: Bool
    let shimmerOffset: CGFloat
    var layoutScale: CGFloat = 1
    var showShimmer: Bool = true

    var body: some View {
        let s = layoutScale
        let outer: CGFloat = 170 * s
        let inner: CGFloat = 146 * s
        let cr: CGFloat = 34 * s
        let imgCr: CGFloat = 24 * s
        let glossCr: CGFloat = 26 * s

        ZStack {
            #if os(iOS)
            RoundedRectangle(cornerRadius: cr, style: .continuous)
                .fill(.ultraThinMaterial.opacity(isDarkMode ? 0.45 : 0.7))
                .frame(width: outer, height: outer)
                .overlay(
                    RoundedRectangle(cornerRadius: cr, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.55),
                                    accentColor.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(1.2, 1 * s)
                        )
                )
                .shadow(color: accentColor.opacity(0.22), radius: 24 * s, y: 10 * s)
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: glossCr, style: .continuous)
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
                        .frame(width: 110 * s, height: 54 * s)
                        .blur(radius: 0.3)
                        .padding(12 * s)
                }
            #endif

            Image(title)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(imgCr)
                .frame(maxWidth: inner, maxHeight: inner)
                .overlay(alignment: .topLeading) {
                    if showShimmer {
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
                            RoundedRectangle(cornerRadius: imgCr, style: .continuous)
                                .frame(width: inner, height: inner)
                        )
                    }
                }
        }
    }
}

struct LaunchCompanionCard: View {
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
                #if os(iOS)
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
