import SwiftUI

struct PrayerCountdown: View {
    @EnvironmentObject var settings: Settings
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var progressToNextPrayer: Double = 0.0
    @State private var interval: TimeInterval = 60.0
    @State private var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    func calculateProgress() -> Double {
        if let currentPrayer = settings.currentPrayer, let nextPrayer = settings.nextPrayer {
            let now = Date()
            let calendar = Calendar.current

            let currentHour = calendar.component(.hour, from: currentPrayer.time)
            let nextHour = calendar.component(.hour, from: nextPrayer.time)
            let nowHour = calendar.component(.hour, from: now)

            // Adjust the currentPrayer and nextPrayer times based on the current time
            var currentPrayerAdjusted = currentPrayer.time
            var nextPrayerAdjusted = nextPrayer.time
            if currentHour > nowHour { // currentPrayer should be from "yesterday"
                currentPrayerAdjusted = calendar.date(byAdding: .day, value: -1, to: currentPrayer.time) ?? currentPrayer.time
            }
            if nextHour < nowHour { // nextPrayer should be for "tomorrow"
                nextPrayerAdjusted = calendar.date(byAdding: .day, value: 1, to: nextPrayer.time) ?? nextPrayer.time
            }

            let totalInterval = nextPrayerAdjusted.timeIntervalSince(currentPrayerAdjusted)
            let remainingInterval = nextPrayerAdjusted.timeIntervalSince(now)

            // Ensure remainingInterval is non-negative and totalInterval >= remainingInterval
            guard remainingInterval >= 0, totalInterval >= remainingInterval else {
                return 0
            }

            return 1 - (remainingInterval / totalInterval)
        }
        return 0
    }
    
    private func setupTimer() {
        progressToNextPrayer = calculateProgress()
    }
    
    var body: some View {
        if let currentPrayer = settings.currentPrayer, let nextPrayer = settings.nextPrayer {
            Section(header: Text("CURRENT PRAYER")) {
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: currentPrayer.image)
                            
                            Text(currentPrayer.nameTransliteration)
                        }
                        #if !os(watchOS)
                        .font(.title)
                        #else
                        .font(.title3)
                        #endif
                        .foregroundColor(currentPrayer.nameTransliteration == "Shurooq" ? .primary : settings.accentColor.color)
                        
                        Text("\(currentPrayer.nameEnglish) / \(currentPrayer.nameArabic)")
                            #if !os(watchOS)
                            .font(.title2)
                            #else
                            .font(.title3)
                            #endif
                            .foregroundColor(currentPrayer.nameTransliteration == "Shurooq" ? .primary.opacity(0.7) : settings.accentColor.color.opacity(0.7))
                        
                        Text("Started at \(currentPrayer.time, style: .time)")
                            .font(.headline)
                        
                        if currentPrayer.rakah != "0" {
                            Text("Prayer Rakahs: \(currentPrayer.rakah)")
                                #if !os(watchOS)
                                .font(.body)
                                #else
                                .font(.caption2)
                                #endif
                        } else {
                            Text("Shurooq is not a prayer, but marks the end of Fajr")
                                .foregroundColor(.secondary)
                                #if !os(watchOS)
                                .font(.caption)
                                #else
                                .font(.caption2)
                                #endif
                        }
                        
                        #if !os(watchOS)
                        if currentPrayer.sunnahBefore != "0" {
                            Text("Sunnah Rakahs Before: \(currentPrayer.sunnahBefore)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if currentPrayer.sunnahAfter != "0" {
                            Text("Sunnah Rakahs After: \(currentPrayer.sunnahAfter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        #endif
                    }
                    .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
            }
            
            Section(header: Text("UPCOMING PRAYER")) {
                HStack {
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        HStack {
                            Text(nextPrayer.nameTransliteration)
                            
                            Image(systemName: nextPrayer.image)
                        }
                        #if !os(watchOS)
                        .font(.title)
                        #else
                        .font(.title3)
                        #endif
                        .foregroundColor(nextPrayer.nameTransliteration == "Shurooq" ? .primary : settings.accentColor.color)
                        
                        Text("\(nextPrayer.nameEnglish) / \(nextPrayer.nameArabic)")
                            #if !os(watchOS)
                            .font(.title2)
                            #else
                            .font(.title3)
                            #endif
                            .foregroundColor(nextPrayer.nameTransliteration == "Shurooq" ? .primary.opacity(0.7) : settings.accentColor.color.opacity(0.7))
                        
                        if nextPrayer.rakah != "0" {
                            Text("Prayer Rakahs: \(nextPrayer.rakah)")
                                    #if !os(watchOS)
                                    .font(.body)
                                    #else
                                    .font(.caption2)
                                    #endif
                        } else {
                            Text("Shurooq is not a prayer, but marks the end of Fajr")
                                .foregroundColor(.secondary)
                                #if !os(watchOS)
                                .font(.caption)
                                #else
                                .font(.caption2)
                                #endif
                        }
                        
                        #if !os(watchOS)
                        if nextPrayer.sunnahBefore != "0" {
                            Text("Sunnah Rakahs Before: \(nextPrayer.sunnahBefore)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if nextPrayer.sunnahAfter != "0" {
                            Text("Sunnah Rakahs After: \(nextPrayer.sunnahAfter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        #endif
                        
                        ProgressView(value: progressToNextPrayer, total: 1)
                            .tint(settings.accentColor.color)
                            .onReceive(timer) { _ in
                                progressToNextPrayer = calculateProgress()
                                if progressToNextPrayer >= 1 {
                                    settings.fetchPrayerTimes()
                                    setupTimer()
                                }
                            }
                        
                        HStack(alignment: .center) {
                            Text("Time Left: \(nextPrayer.time, style: .timer)")
                            
                            Spacer()
                            
                            Text("Starts at \(nextPrayer.time, style: .time)")
                        }
                        .font(.headline)
                    }
                    .multilineTextAlignment(.trailing)
                }
            }
            .onAppear {
                setupTimer()
            }
            .onChange(of: scenePhase) { newScenePhase in
                if newScenePhase == .active {
                    setupTimer()
                }
            }
            .onChange(of: progressToNextPrayer) { value in
                if value >= 1 {
                    settings.fetchPrayerTimes()
                    setupTimer()
                }
            }
            .onChange(of: currentPrayer) { _ in
                setupTimer()
            }
            .onChange(of: nextPrayer) { _ in
                setupTimer()
            }
        }
    }
}
