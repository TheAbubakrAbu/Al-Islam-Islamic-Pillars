import SwiftUI

struct PrayerCountdown: View {
    @EnvironmentObject var settings: Settings
    
    @Environment(\.scenePhase) private var scenePhase

    @State private var progress : Double = 0
    private let timer = Timer
        .publish(every: 60, on: .main, in: .common)
        .autoconnect()

    private var current : Prayer? { settings.currentPrayer }
    private var next : Prayer? { settings.nextPrayer }
    
    private func calcProgress() -> Double {
        guard var start = current?.time, var end = next?.time else { return 0 }

        let now = Date()
        if start > now { start.addTimeInterval(-86_400) }

        if end <= start { end.addTimeInterval(86_400) }

        let total = end.timeIntervalSince(start)
        let remaining = end.timeIntervalSince(now)
        return max(0, min(1, 1 - remaining / total))
    }

    private func updateProgress() {
        progress = calcProgress()
    }

    var body: some View {
        if let current = current, let next = next {
            Group {
                Section(header: Text("CURRENT PRAYER")) {
                    CurrentPrayerCell(prayer: current)
                }

                Section(header: Text("UPCOMING PRAYER")) {
                    UpcomingPrayerCell(prayer: next, progress: progress)
                        .onReceive(timer) { _ in updateProgress() }
                }
            }
            .onAppear(perform: updateProgress)
            .onChange(of: scenePhase)      { _ in updateProgress() }
            .onChange(of: settings.prayers) { _ in updateProgress() }
        }
    }
}

private struct CurrentPrayerCell: View {
    @EnvironmentObject var settings: Settings
    
    let prayer: Prayer

    var body: some View {
        ZStack {
            Color.white.opacity(0.0001)
            
            VStack(alignment: .leading, spacing: 5) {
                title
                subtitle
                
                Text("Started at \(prayer.time, style: .time)")
                    .font(.headline)
                
                if settings.showCurrentInfo {
                    Divider()
                        .background(settings.accentColor.color)
                    
                    rakahInfo
                    sunnahInfo
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onTapGesture {
            settings.hapticFeedback()
            
            withAnimation { settings.showCurrentInfo.toggle() }
        }
    }

    private var title: some View {
        HStack {
            Image(systemName: prayer.image)
            Text(prayer.nameTransliteration)
        }
        #if !os(watchOS)
        .font(.title)
        #else
        .font(.title3)
        #endif
        .foregroundColor(prayer.nameTransliteration == "Shurooq" ? .primary : settings.accentColor.color)
    }

    private var subtitle: some View {
        Text("\(prayer.nameEnglish) / \(prayer.nameArabic)")
            .font(.title3)
            .foregroundColor(prayer.nameTransliteration == "Shurooq" ? .primary.opacity(0.7) : settings.accentColor.color.opacity(0.7))
    }

    @ViewBuilder private var rakahInfo: some View {
        if prayer.rakah != "0" {
            Text("Prayer Rakahs: \(prayer.rakah)")
                #if !os(watchOS)
                .font(.caption)
                #else
                .font(.caption2)
                #endif
                .foregroundColor(.primary)
        } else {
            Text("Shurooq is not a prayer, but marks the end of Fajr")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder private var sunnahInfo: some View {
        if prayer.sunnahBefore != "0" {
            Text("Sunnah Rakahs Before: \(prayer.sunnahBefore)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        if prayer.sunnahAfter != "0" {
            Text("Sunnah Rakahs After: \(prayer.sunnahAfter)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

private struct UpcomingPrayerCell: View {
    @EnvironmentObject var settings: Settings
    
    let prayer: Prayer
    let progress: Double

    var body: some View {
        ZStack {
            Color.white.opacity(0.0001)
            
            VStack(alignment: .trailing, spacing: 5) {
                title
                subtitle
                
                if settings.showNextInfo {
                    Divider()
                        .background(settings.accentColor.color)
                    
                    rakahInfo
                    sunnahInfo
                }
                
                ProgressView(value: progress)
                    .tint(settings.accentColor.color)
                    .padding(.top, 4)
                timeInfo
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .onTapGesture {
            settings.hapticFeedback()
            
            withAnimation { settings.showNextInfo.toggle() }
        }
    }

    private var title: some View {
        HStack {
            Text(prayer.nameTransliteration)
            Image(systemName: prayer.image)
        }
        #if !os(watchOS)
        .font(.title)
        #else
        .font(.title3)
        #endif
        .foregroundColor(prayer.nameTransliteration == "Shurooq" ? .primary : settings.accentColor.color)
    }

    private var subtitle: some View {
        Text("\(prayer.nameEnglish) / \(prayer.nameArabic)")
            .font(.title3)
            .foregroundColor(prayer.nameTransliteration == "Shurooq" ? .primary.opacity(0.7) : settings.accentColor.color.opacity(0.7))
    }

    @ViewBuilder private var rakahInfo: some View {
        if prayer.rakah != "0" {
            Text("Prayer Rakahs: \(prayer.rakah)")
                #if !os(watchOS)
                .font(.caption)
                #else
                .font(.caption2)
                #endif
                .foregroundColor(.primary)
        } else {
            Text("Shurooq is not a prayer, but marks the end of Fajr")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder private var sunnahInfo: some View {
        if prayer.sunnahBefore != "0" {
            Text("Sunnah Rakahs Before: \(prayer.sunnahBefore)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        if prayer.sunnahAfter != "0" {
            Text("Sunnah Rakahs After: \(prayer.sunnahAfter)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var timeInfo: some View {
        HStack {
            Text("Time Left: \(prayer.time, style: .timer)")
            
            Spacer(minLength: 12)
            
            Text("Starts at \(prayer.time, style: .time)")
        }
        .font(.headline)
    }
}
