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
    
    @AppStorage("firstLaunchSheet") var firstLaunchSheet: Bool = true
    @State var showAdhanSheet: Bool = false
    
    @State private var isLaunching = true
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isLaunching {
                    LaunchScreen(isLaunching: $isLaunching)
                } else {
                    TabView {
                        VStack {
                            AdhanView()
                            
                            if quranPlayer.isPlaying || quranPlayer.isPaused {
                                NowPlayingView(quranView: false)
                                    .animation(.easeInOut, value: quranPlayer.isPlaying)
                                    .padding(.bottom, 9)
                            }
                        }
                        .tabItem {
                            Image(systemName: "safari")
                            Text("Adhan")
                        }
                        
                        QuranView()
                            .tabItem {
                                Image(systemName: "character.book.closed.ar")
                                Text("Quran")
                            }
                        
                        VStack {
                            IslamView()
                            
                            NowPlayingView(quranView: false)
                                .animation(.easeInOut, value: quranPlayer.isPlaying)
                                .padding(.bottom, 9)
                        }
                        .tabItem {
                            Image(systemName: "moon.stars")
                            Text("Islam")
                        }
                        
                        VStack {
                            SettingsView()
                            
                            NowPlayingView(quranView: false)
                                .animation(.easeInOut, value: quranPlayer.isPlaying)
                                .padding(.bottom, 9)
                        }
                        .tabItem {
                            Image(systemName: "gearshape")
                            Text("Settings")
                        }
                    }
                    .onAppear {
                        if firstLaunchSheet {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                withAnimation {
                                    showAdhanSheet = true
                                }
                            }
                        }
                    }
                    .sheet(
                        isPresented: $showAdhanSheet,
                        onDismiss: {
                            firstLaunchSheet = false
                        }) {
                        AdhanSetupSheet()
                            .environmentObject(settings)
                            .accentColor(settings.accentColor.color)
                            .tint(settings.accentColor.color)
                            .preferredColorScheme(settings.colorScheme)
                            .transition(.opacity)
                    }
                }
            }
            //.statusBar(hidden: true)
            .environmentObject(settings)
            .environmentObject(quranData)
            .environmentObject(quranPlayer)
            .environmentObject(namesData)
            .accentColor(settings.accentColor.color)
            .tint(settings.accentColor.color)
            .preferredColorScheme(settings.colorScheme)
            .transition(.opacity)
            .animation(.easeInOut, value: isLaunching)
            .animation(.easeInOut, value: settings.firstLaunch)
            .appReviewPrompt()
            .onAppear {
                withAnimation {
                    settings.fetchPrayerTimes()
                }
            }
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
}
