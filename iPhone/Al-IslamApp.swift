import SwiftUI
import WatchConnectivity
import WidgetKit

@main
struct IslamicPillarsApp: App {
    @StateObject private var settings = Settings.shared
    @StateObject private var quranData = QuranData.shared
    @StateObject private var quranPlayer = QuranPlayer.shared
    @StateObject private var namesData = NamesViewModel.shared
    
    @State private var isLaunching = true
    
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
                        
                        SurahsView()
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
            .onAppear {
                withAnimation {
                    settings.fetchPrayerTimes()
                }
            }
        }
        .onChange(of: settings.lastReadSurah) { _ in
            sendMessageToWatch()
        }
        .onChange(of: settings.lastReadAyah) { _ in
            sendMessageToWatch()
        }
        .onChange(of: settings.favoriteSurahs) { _ in
            sendMessageToWatch()
        }
        .onChange(of: settings.bookmarkedAyahs) { _ in
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
            settings.fetchPrayerTimes(force: true)
            sendMessageToWatch()
        }
        .onChange(of: settings.hanafiMadhab) { _ in
            settings.fetchPrayerTimes(force: true)
            sendMessageToWatch()
        }
        .onChange(of: settings.travelingMode) { _ in
            settings.fetchPrayerTimes(force: true)
            sendMessageToWatch()
        }
        .onChange(of: settings.hijriOffset) { _ in
            settings.updateDates()
            sendMessageToWatch()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func sendMessageToWatch() {
        guard WCSession.default.isPaired else {
            print("No Apple Watch is paired")
            return
        }
        
        let settingsData = settings.dictionaryRepresentation()
        let message = ["settings": settingsData]

        if WCSession.default.isReachable {
            print("Watch is reachable. Sending message to watch: \(message)")

            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending message to watch: \(error.localizedDescription)")
            }
        } else {
            print("Watch is not reachable. Transferring user info to watch: \(message)")
            WCSession.default.transferUserInfo(message)
        }
    }
}
