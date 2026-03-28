import SwiftUI

struct PrayerCountdown: View {
    @EnvironmentObject var settings: Settings
    
    @Environment(\.scenePhase) private var scenePhase

    @State private var progress : Double = 0
    @State private var updateTimer: Timer?
    private let timerInterval: TimeInterval = 30  // Update every 30 seconds

    private var current: Prayer? { settings.currentPrayer }
    private var next   : Prayer? { settings.nextPrayer }
    
    private func calcProgress() -> Double {
        guard var start = current?.time, var end = next?.time else { return 0 }

        let now = Date()
        
        // Adjust for day boundaries (if current prayer is after midnight compared to now)
        if start > now { start.addTimeInterval(-86_400) }

        // Ensure end is after start (can span into next day)
        if end <= start { end.addTimeInterval(86_400) }

        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }  // Avoid division by zero
        
        let remaining = end.timeIntervalSince(now)
        return max(0, min(1, 1 - remaining / total))
    }

    private func updateProgress() {
        progress = calcProgress()
    }
    
    private func startTimer() {
        stopTimer()
        updateTimer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { _ in
            DispatchQueue.main.async {
                // Update progress
                updateProgress()
                // Update current/next prayers in case they changed
                settings.updateCurrentAndNextPrayer()
            }
        }
    }
    
    private func stopTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
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
                            CurrentPrayerCell(prayer: current)
                            
                            Divider().background(settings.accentColor.color)
                                .padding(.bottom, 15)
                                .padding(.top, 6)
                            
                            UpcomingPrayerCell(prayer: next)
                        }
                        .padding(.bottom, -8)

                        if settings.showPrayerInfo {
                            VStack {
                                Divider()
                                    .background(settings.accentColor.color)
                                
                                HStack(alignment: .top) {
                                    CurrentPrayerInfoView(prayer: current)
                                    
                                    UpcomingPrayerInfoView(prayer: next)
                                }
                            }
                        }
                        
                        ProgressView(value: progress)
                            .tint(settings.accentColor.color)
                            .conditionalGlassEffect()
                            .padding(.vertical, 2)
                        
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
            .onAppear {
                updateProgress()
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    updateProgress()
                    settings.updateCurrentAndNextPrayer()
                    startTimer()
                } else {
                    stopTimer()
                }
            }
            .onChange(of: settings.prayers) { _ in
                updateProgress()
                settings.updateCurrentAndNextPrayer()
            }
            .onChange(of: current) { _ in
                updateProgress()
            }
            .onChange(of: next) { _ in
                updateProgress()
            }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            title
            
            #if !os(watchOS)
            subtitle
            #endif
            
            Text("Started at \(prayer.time, style: .time)")
                .font(.headline)
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
                .font(.title)
        }
        .foregroundColor(prayer.nameTransliteration == "Shurooq" ? .primary : settings.accentColor.color)
    }

    private var subtitle: some View {
        Text("\(prayer.nameEnglish) / \(prayer.nameArabic)")
            .font(.title3)
            .foregroundColor(prayer.nameTransliteration == "Shurooq" ? .primary.opacity(0.7) : settings.accentColor.color.opacity(0.7))
    }
}

private struct UpcomingPrayerCell: View {
    @EnvironmentObject var settings: Settings
    
    let prayer: Prayer

    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            title
            
            #if !os(watchOS)
            subtitle
            #endif
            
            Text("Starts at \(prayer.time, style: .time)")
                .font(.headline)
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
}

private struct CurrentPrayerInfoView: View {
    let prayer: Prayer

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            PrayerRakahInfoView(prayer: prayer, captionFont: .caption, alignment: .leading)
            PrayerSunnahInfoView(prayer: prayer, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
    }
}

private struct UpcomingPrayerInfoView: View {
    let prayer: Prayer

    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            PrayerRakahInfoView(prayer: prayer, captionFont: .caption, alignment: .trailing)
            PrayerSunnahInfoView(prayer: prayer, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .multilineTextAlignment(.trailing)
    }
}

private struct PrayerRakahInfoView: View {
    let prayer: Prayer
    let captionFont: Font
    let alignment: Alignment

    var body: some View {
        Group {
            if prayer.rakah != "0" {
                Text("Prayer Rakahs: \(prayer.rakah)")
                    #if !os(watchOS)
                    .font(captionFont)
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
        .frame(maxWidth: .infinity, alignment: alignment)
    }
}

private struct PrayerSunnahInfoView: View {
    let prayer: Prayer
    let alignment: Alignment

    var body: some View {
        VStack(alignment: horizontalAlignment, spacing: 5) {
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
        .frame(maxWidth: .infinity, alignment: alignment)
    }

    private var horizontalAlignment: HorizontalAlignment {
        switch alignment {
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        default:
            return .center
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        List {
            PrayerCountdown()
        }
    }
}
