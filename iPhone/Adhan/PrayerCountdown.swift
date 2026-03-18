import SwiftUI

struct PrayerCountdown: View {
    @EnvironmentObject var settings: Settings
    
    @Environment(\.scenePhase) private var scenePhase

    @State private var progress : Double = 0
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var current: Prayer? { settings.currentPrayer }
    private var next   : Prayer? { settings.nextPrayer }
    
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
                Section(header: HStack {
                    Text("CURRENT")
                    
                    Spacer()
                    
                    Text("UPCOMING")
                }) {
                    VStack {
                        HStack(alignment: .top) {
                            CurrentPrayerCell(prayer: current, showHeader: true, showInfo: false)
                            
                            Divider().background(settings.accentColor.color)
                            
                            UpcomingPrayerCell(prayer: next, progress: progress, showHeader: true, showInfo: false)
                        }

                        if settings.showPrayerInfo {
                            Divider()
                                .background(settings.accentColor.color)

                            HStack(alignment: .top) {
                                CurrentPrayerCell(prayer: current, showHeader: false, showInfo: true)

                                UpcomingPrayerCell(prayer: next, progress: progress, showHeader: false, showInfo: true)
                            }
                        }
                        
                        ProgressView(value: progress)
                            .tint(settings.accentColor.color)
                            .padding(.top, 4)
                        
                        HStack {
                            Text("Time Left: \(next.time, style: .timer)")
                            
                            Spacer()
                        }
                        .font(.headline)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.25)
                }
            }
            .onReceive(timer) { _ in updateProgress() }
            .onAppear(perform: updateProgress)
            .onChange(of: scenePhase) { _ in updateProgress() }
            .onChange(of: settings.prayers) { _ in updateProgress() }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .onTapGesture {
                settings.hapticFeedback()
                
                withAnimation { settings.showPrayerInfo.toggle() }
            }
        }
    }
}

private struct CurrentPrayerCell: View {
    @EnvironmentObject var settings: Settings
    
    let prayer: Prayer
    var showHeader: Bool = true
    var showInfo: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if showHeader {
                title
                subtitle
                
                Text("Started at \(prayer.time, style: .time)")
                    .font(.headline)
            }
            
            if showInfo && settings.showPrayerInfo {
                rakahInfo
                sunnahInfo
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
    }

    private var title: some View {
        HStack {
            Image(systemName: prayer.image)
                #if !os(watchOS)
                .font(.title3)
                #else
                .font(.subheadline)
                #endif
            
            Text(prayer.nameTransliteration)
                #if !os(watchOS)
                .font(.title)
                #else
                .font(.title3)
                #endif
        }
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
    var showHeader: Bool = true
    var showInfo: Bool = true

    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            if showHeader {
                title
                subtitle
                
                Text("Starts at \(prayer.time, style: .time)")
                    .font(.headline)
            }
            
            if showInfo && settings.showPrayerInfo {
                rakahInfo
                sunnahInfo
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .multilineTextAlignment(.trailing)
    }

    private var title: some View {
        HStack {
            Text(prayer.nameTransliteration)
            
            Image(systemName: prayer.image)
                .font(.title3)
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

#Preview {
    AdhanView()
        .environmentObject(Settings.shared)
}
