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

    init() {
        // Activate WatchConnectivity so settings sync (and watch app-installed detection) work both ways.
        _ = WatchConnectivityManager.shared
    }

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
                .onAppear { settings.fetchPrayerTimes() }
                //.statusBarHidden()
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
        .onChange(of: scenePhase) { phase in
            quranPlayer.saveLastListenedSurah()
            quranPlayer.saveLastListenedAyah()
            settings.refreshQuranWidgets()
            if phase == .active {
                // Play the adhan in-app on time while open (the scheduled notification covers the closed
                // case and can be delivered late by the system, especially on Mac/Catalyst).
                ForegroundAdhanPlayer.shared.reschedule()
            } else {
                ForegroundAdhanPlayer.shared.stop()
                // Send any just-made setting change before the app is suspended, so it can't be lost (and
                // can't be reverted by a stale synced value on the next launch).
                WatchConnectivityManager.shared.flushPendingSync()
            }
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        ZStack {
            if rootStage == .launch {
                LaunchScreen(isLaunching: $isLaunching)
                    .zIndex(3)
                    .transition(.opacity)
            }

            if rootStage == .splash {
                SplashScreen()
                    .zIndex(2)
                    .transition(.opacity)
            }

            if rootStage == .main {
                MainTabView()
                    .zIndex(1)
                    .transition(.opacity)
            }
        }
        .animation(rootTransitionAnimation, value: rootStage)
    }
}

private struct MainTabView: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var quranData: QuranData
    @EnvironmentObject private var quranPlayer: QuranPlayer

    private enum AppTab: Hashable { case adhan, quran, islam, settings }
    @State private var selectedTab: AppTab = .adhan

    var body: some View {
        tabs
            .task { await prewarmAllQuran() }
    }

    /// As soon as the main UI (the Adhan tab) is on screen, warm EVERY surah's Arabic text / tajweed caches —
    /// and with them the shared Arabic font's CoreText glyph cache — in the background, so the first switch to
    /// the Quran tab is already fully warm. Runs on the main actor (it reads `settings`) but yields + sleeps
    /// between surahs so the Adhan tab stays responsive while it fills in. Runs once per session (shared flag).
    @MainActor
    private func prewarmAllQuran() async {
        await quranData.waitUntilCoreLoaded()
        if Task.isCancelled || QuranData.didBroadPrewarm { return }

        // Warm the most-likely-first surahs (reading position, a bookmark, a favorite, al-Fatihah/al-Baqarah)
        // before the rest, so the surah a user is most likely to open is ready first.
        let priority = [
            settings.lastReadSurah > 0 ? settings.lastReadSurah : 1,
            settings.bookmarkedAyahs.first?.surah,
            settings.favoriteSurahs.first,
            1, 2
        ].compactMap { $0 }

        var seen = Set<Int>()
        for id in priority where seen.insert(id).inserted {
            if Task.isCancelled { return }
            if let surah = quranData.surah(id) {
                SurahView.prewarm(surah: surah, settings: settings)
                await Task.yield()
            }
        }

        // Skip the full sweep on memory-constrained devices (same gate the Quran tab uses) — priority warming
        // above still ran.
        guard !AppPerformance.shouldAvoidBroadPrewarm else { return }

        for surah in quranData.quran where seen.insert(surah.id).inserted {
            if Task.isCancelled { return }
            SurahView.prewarm(surah: surah, settings: settings)
            await Task.yield()
            try? await Task.sleep(nanoseconds: 12_000_000)   // throttle: keep the Adhan tab responsive
        }
        QuranData.didBroadPrewarm = true
    }

    @ViewBuilder
    private var tabs: some View {
        if #available(iOS 18.0, *) {
            TabView(selection: $selectedTab) {
                Tab("Adhan", systemImage: "mecca", value: AppTab.adhan) {
                    AdhanView()
                }

                Tab("Quran", systemImage: "character.book.closed.ar", value: AppTab.quran) {
                    QuranView()
                }

                Tab("Islam", systemImage: "moon.stars", value: AppTab.islam) {
                    IslamView()
                }

                Tab("Settings", systemImage: "gearshape", value: AppTab.settings, role: .search) {
                    SettingsView()
                }
            }
        } else {
            TabView(selection: $selectedTab) {
                AdhanView()
                    .tabItem {
                        Image(systemName: "safari")
                        Text("Adhan")
                    }
                    .tag(AppTab.adhan)

                QuranView()
                    .tabItem {
                        Image(systemName: "character.book.closed.ar")
                        Text("Quran")
                    }
                    .tag(AppTab.quran)

                IslamView()
                    .tabItem {
                        Image(systemName: "moon.stars")
                        Text("Islam")
                    }
                    .tag(AppTab.islam)

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
                    .tag(AppTab.settings)
            }
        }
    }
}
