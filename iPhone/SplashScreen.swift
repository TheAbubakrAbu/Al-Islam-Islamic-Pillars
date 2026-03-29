#if os(iOS)
import SwiftUI

struct SplashScreen: View {
    @EnvironmentObject private var settings: Settings
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.openURL) private var openURL

    @State private var openedAppStoreFromHero = false

    private var currentColorScheme: ColorScheme {
        settings.colorScheme ?? systemColorScheme
    }

    private var isDarkMode: Bool {
        currentColorScheme == .dark
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("These are the Al-Islamic apps: Adhan, Quran, and everything in between. What more do you need?")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)

                        Text("All the apps are privacy-focused, ensuring that all data remains on your device. Enjoy an ad-free, subscription-free, and cost-free experience. Al-Quran and Al-Adhan are extensions, and Al-Islam does everything Al-Quran and Al-Adhan do combined, with additional functionalities.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)

                        Text("Tap any app below to open it in the App Store.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                }

                Spacer()

                appHeroStack
                    .padding(.bottom, 8)

                Spacer()

                actionButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
            }
            .navigationTitle("Assalamu Alaikum")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }

    /// Same three-app layout as the end of `LaunchScreen`: Al-Adhan and Al-Quran flanking Al-Islam.
    private var appHeroStack: some View {
        ZStack {
            Button {
                openAppStoreFromHero(Self.alAdhanAppURL)
            } label: {
                VStack(spacing: 10) {
                    Text("Al-Adhan")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    LaunchCompanionCard(
                        imageName: "Al-Adhan",
                        accentColor: settings.accentColor.color,
                        isDarkMode: isDarkMode,
                        width: 120,
                        height: 120,
                        cornerRadius: 32,
                        imageInset: 10,
                        opacity: 1
                    )
                }
            }
            .buttonStyle(.plain)
            .rotationEffect(.degrees(-5.6))
            .offset(x: -108, y: -6)
            .accessibilityLabel("Al-Adhan on the App Store")

            Button {
                openAppStoreFromHero(Self.alQuranAppURL)
            } label: {
                VStack(spacing: 10) {
                    Text("Al-Quran")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    LaunchCompanionCard(
                        imageName: "Al-Quran",
                        accentColor: settings.accentColor.color,
                        isDarkMode: isDarkMode,
                        width: 120,
                        height: 120,
                        cornerRadius: 32,
                        imageInset: 10,
                        opacity: 1
                    )
                }
            }
            .buttonStyle(.plain)
            .rotationEffect(.degrees(7))
            .offset(x: 114, y: -6)
            .accessibilityLabel("Al-Quran on the App Store")

            Button {
                openAppStoreFromHero(Self.alIslamAppURL)
            } label: {
                VStack(spacing: 10) {
                    Text("Al-Islam")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    LaunchLogoCard(
                        title: "Al-Islam",
                        accentColor: settings.accentColor.color,
                        isDarkMode: isDarkMode,
                        shimmerOffset: 0
                    )
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(0.88)
            .accessibilityLabel("Al-Islam on the App Store")
        }
        .frame(height: 275)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                settings.hapticFeedback()
                withAnimation {
                    settings.firstLaunch = false
                }
            } label: {
                Text(openedAppStoreFromHero ? "Done" : "Skip for now")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .conditionalGlassEffect(
                rectangle: true,
                useColor: 0.38,
                customTint: openedAppStoreFromHero ? .green : .red
            )
            .accessibilityLabel(openedAppStoreFromHero ? "Done" : "Skip for now")
        }
    }

    private func openAppStoreFromHero(_ url: URL?) {
        settings.hapticFeedback()
        withAnimation(.easeInOut(duration: 0.25)) {
            openedAppStoreFromHero = true
        }
        openURLIfPossible(url)
    }

    private func openURLIfPossible(_ url: URL?) {
        guard let url else { return }
        openURL(url)
    }

    private static let alAdhanAppURL = URL(string: "https://apps.apple.com/us/app/al-adhan-prayer-times/id6475015493")
    private static let alIslamAppURL = URL(string: "https://apps.apple.com/us/app/al-islam-islamic-pillars/id6449729655?platform=iphone")
    private static let alQuranAppURL = URL(string: "https://apps.apple.com/us/app/al-quran-beginner-quran/id6474894373")
}

#Preview {
    SplashScreen()
        .environmentObject(Settings.shared)
}
#endif
