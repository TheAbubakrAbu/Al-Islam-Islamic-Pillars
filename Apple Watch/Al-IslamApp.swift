import SwiftUI
import WatchConnectivity
import WidgetKit

@main
struct AlIslamApp: App {
    @StateObject private var settings = Settings.shared
    @StateObject private var quranData = QuranData.shared
    @StateObject private var quranPlayer = QuranPlayer.shared
    @StateObject private var namesData = NamesViewModel.shared
        
    @State private var isLaunching = true
    
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
                        
                        QuranView()
                        
                        PillarsView()
                                                
                        SettingsView()
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
            }
        }
        .onChange(of: settings.lastReadSurah) { _ in
            sendMessageToPhone()
        }
        .onChange(of: settings.lastReadAyah) { _ in
            sendMessageToPhone()
        }
        .onChange(of: settings.favoriteSurahs) { newSurahs in
            sendMessageToPhone()
        }
        .onChange(of: settings.bookmarkedAyahs) { newBookmarks in
            sendMessageToPhone()
        }
        .onChange(of: settings.favoriteLetters) { _ in
            sendMessageToPhone()
        }
        .onChange(of: settings.accentColor) { _ in
            sendMessageToPhone()
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: settings.prayerCalculation) { _ in
            settings.fetchPrayerTimes(force: true) {
                sendMessageToPhone()
            }
        }
        .onChange(of: settings.hanafiMadhab) { _ in
            settings.fetchPrayerTimes(force: true) {
                sendMessageToPhone()
            }
        }
        .onChange(of: settings.travelingMode) { _ in
            settings.fetchPrayerTimes(force: true) {
                sendMessageToPhone()
            }
        }
        .onChange(of: settings.hijriOffset) { _ in
            settings.updateDates()
            sendMessageToPhone()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func sendMessageToPhone() {
        let settingsData = settings.dictionaryRepresentation()
        let message = ["settings": settingsData]

        if WCSession.default.isReachable {
            logger.debug("Phone is reachable. Sending message to phone: \(message)")
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                logger.debug("Error sending message to phone: \(error.localizedDescription)")
            }
        } else {
            logger.debug("Phone is not reachable. Transferring user info to phone: \(message)")
            WCSession.default.transferUserInfo(message)
        }
    }
}
