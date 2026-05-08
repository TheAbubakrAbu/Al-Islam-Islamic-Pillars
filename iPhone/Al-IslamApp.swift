import SwiftUI
import WidgetKit

@main
struct AlIslamApp: App {
    @StateObject private var settings = Settings.shared
    @StateObject private var quranData = QuranData.shared
    @StateObject private var quranPlayer = QuranPlayer.shared
    @StateObject private var namesData = NamesViewModel.shared

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    @State private var isLaunching = true

    private enum RootStage: Equatable {
        case launch
        case splash
        case main
    }

    private var rootStage: RootStage {
        if isLaunching {
            return .launch
        }
        return settings.firstLaunch ? .splash : .main
    }

    private var rootTransitionAnimation: Animation {
        .easeInOut(duration: 0.42)
    }

    var body: some Scene {
        WindowGroup {
            rootContent
                .environmentObject(settings)
                .environmentObject(quranData)
                .environmentObject(quranPlayer)
                .environmentObject(namesData)
                .accentColor(settings.accentColor.color)
                .tint(settings.accentColor.color)
                .preferredColorScheme(settings.colorScheme)
                .appReviewPrompt()
                .onAppear(perform: refreshPrayerTimes)
        }
        .onChange(of: settings.accentColor) { _ in
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: settings.prayerCalculation) { _ in
            settings.fetchPrayerTimes(force: true)
        }
        .onChange(of: settings.hanafiMadhab) { _ in
            settings.fetchPrayerTimes(force: true)
        }
        .onChange(of: settings.travelingMode) { _ in
            settings.fetchPrayerTimes(force: true)
        }
        .onChange(of: settings.hijriOffset) { _ in
            settings.updateDates()
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: scenePhase) { _ in
            quranPlayer.saveLastListenedSurah()
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        ZStack {
            if rootStage == .launch {
                LaunchScreen(isLaunching: $isLaunching)
                    .zIndex(3)
                    .transition(.rootHandoff)
            }

            if rootStage == .splash {
                SplashScreen()
                    .zIndex(2)
                    .transition(.rootHandoff)
            }

            if rootStage == .main {
                MainTabView()
                    .zIndex(1)
                    .transition(.rootHandoff)
            }
        }
        .animation(rootTransitionAnimation, value: rootStage)
    }

    private func refreshPrayerTimes() {
        withAnimation {
            settings.fetchPrayerTimes()
        }
    }
}

private struct MainTabView: View {
    @EnvironmentObject private var quranPlayer: QuranPlayer

    var body: some View {
        TabView {
            AdhanView()
                .withNowPlayingInset()
                .tabItem {
                    Image(systemName: "safari")
                    Text("Adhan")
                }

            QuranView()
                .tabItem {
                    Image(systemName: "character.book.closed.ar")
                    Text("Quran")
                }

            IslamView()
                .withNowPlayingInset()
                .tabItem {
                    Image(systemName: "moon.stars")
                    Text("Islam")
                }

            SettingsView()
                .withNowPlayingInset()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
    }
}

private struct NowPlayingInsetModifier: ViewModifier {
    @EnvironmentObject private var quranPlayer: QuranPlayer

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                if quranPlayer.isPlaying || quranPlayer.isPaused {
                    NowPlayingView()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(Color.white.opacity(0.00001))
            .animation(.easeInOut, value: quranPlayer.isPlaying || quranPlayer.isPaused)
        }
    }
}

private extension View {
    func withNowPlayingInset() -> some View {
        modifier(NowPlayingInsetModifier())
    }
}

private extension AnyTransition {
    static var rootHandoff: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 1.015)),
            removal: .opacity.combined(with: .scale(scale: 0.985))
        )
    }
}
