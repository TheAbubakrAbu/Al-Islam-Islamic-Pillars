import SwiftUI
import WatchConnectivity
import WidgetKit
import StoreKit

@main
struct AlIslamApp: App {
    @StateObject private var settings = Settings.shared
    @StateObject private var quranData = QuranData.shared
    @StateObject private var quranPlayer = QuranPlayer.shared
    @StateObject private var namesData = NamesViewModel.shared
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var isLaunching = true
    
    @AppStorage("timeSpent") private var timeSpent: Double = 0
    @AppStorage("shouldShowRateAlert") private var shouldShowRateAlert: Bool = true
    @State private var startTime: Date?
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        _ = WatchConnectivityManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isLaunching {
                    LaunchScreen(isLaunching: $isLaunching)
                } else {
                    TabView {
                        PrayerView()
                            .tabItem {
                                Image(systemName: "safari")
                                Text("Adhan")
                            }
                        
                        QuranView()
                            .tabItem {
                                Image(systemName: "character.book.closed.ar")
                                Text("Quran")
                            }
                        
                        PillarsView()
                            .tabItem {
                                Image(systemName: "moon.stars")
                                Text("Islam")
                            }
                        
                        ArabicView()
                            .tabItem {
                                Image(systemName: "textformat.size.ar")
                                Text("Arabic")
                            }
                        
                        SettingsView()
                            .tabItem {
                                Image(systemName: "gearshape")
                                Text("Settings")
                            }
                    }
                }
            }
            .environmentObject(settings)
            .environmentObject(quranData)
            .environmentObject(quranPlayer)
            .environmentObject(namesData)
            .accentColor(settings.accentColor.color)
            .tint(settings.accentColor.color)
            .preferredColorScheme(settings.colorScheme)
            .transition(.opacity)
            .animation(.easeInOut, value: isLaunching)
            .onAppear {
                withAnimation {
                    settings.fetchPrayerTimes()
                }
                
                if shouldShowRateAlert {
                    startTime = Date()
                    
                    let remainingTime = max(180 - timeSpent, 0)
                    if remainingTime == 0 {
                        guard let windowScene = UIApplication.shared.connectedScenes
                            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                            return
                        }
                        SKStoreReviewController.requestReview(in: windowScene)
                        shouldShowRateAlert = false
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                            guard let windowScene = UIApplication.shared.connectedScenes
                                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                                return
                            }
                            SKStoreReviewController.requestReview(in: windowScene)
                            shouldShowRateAlert = false
                        }
                    }
                }
            }
            .onDisappear {
                if shouldShowRateAlert, let startTime = startTime {
                    timeSpent += Date().timeIntervalSince(startTime)
                }
            }
        }
        .onChange(of: settings.lastReadSurah) { _ in
            sendMessageToWatch()
        }
        .onChange(of: settings.lastReadAyah) { _ in
            sendMessageToWatch()
        }
        .onChange(of: settings.favoriteSurahs) { newSurahs in
            sendMessageToWatch()
        }
        .onChange(of: settings.bookmarkedAyahs) { newBookmarks in
            sendMessageToWatch()
        }
        .onChange(of: settings.favoriteLetters) { _ in
            sendMessageToWatch()
        }
        .onChange(of: settings.accentColor) { _ in
            sendMessageToWatch()
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: settings.prayerCalculation) { _ in
            settings.fetchPrayerTimes(force: true) {
                sendMessageToWatch()
            }
        }
        .onChange(of: settings.hanafiMadhab) { _ in
            settings.fetchPrayerTimes(force: true) {
                sendMessageToWatch()
            }
        }
        .onChange(of: settings.travelingMode) { _ in
            settings.fetchPrayerTimes(force: true) {
                sendMessageToWatch()
            }
        }
        .onChange(of: settings.hijriOffset) { _ in
            settings.updateDates()
            sendMessageToWatch()
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: scenePhase) { _ in
            quranPlayer.saveLastListenedSurah()
        }
    }
    
    private func sendMessageToWatch() {
        guard WCSession.default.isPaired else {
            logger.debug("No Apple Watch is paired")
            return
        }
        
        let settingsData = settings.dictionaryRepresentation()
        let message = ["settings": settingsData]

        if WCSession.default.isReachable {
            logger.debug("Watch is reachable. Sending message to watch: \(message)")

            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                logger.debug("Error sending message to watch: \(error.localizedDescription)")
            }
        } else {
            logger.debug("Watch is not reachable. Transferring user info to watch: \(message)")
            WCSession.default.transferUserInfo(message)
        }
    }
}
