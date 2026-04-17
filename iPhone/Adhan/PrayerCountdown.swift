import SwiftUI

struct PrayerCountdown: View {
    @EnvironmentObject private var settings: Settings
    @Environment(\.scenePhase) private var scenePhase

    @State private var progress: Double = 0
    @State private var updateTimer: Timer?

    private let slowTimerInterval: TimeInterval = 60
    private let mediumTimerInterval: TimeInterval = 15
    private let fastTimerInterval: TimeInterval = 5
    private let urgentTimerInterval: TimeInterval = 1
    private let urgentThreshold: TimeInterval = 30
    private let fastThreshold: TimeInterval = 120
    private let mediumThreshold: TimeInterval = 600

    private var currentPrayer: Prayer? { settings.currentPrayer }
    private var nextPrayer: Prayer? { settings.nextPrayer }

    var body: some View {
        if let currentPrayer, let nextPrayer {
            countdownContent(current: currentPrayer, next: nextPrayer)
        }
    }

    private func countdownContent(current: Prayer, next: Prayer) -> some View {
        countdownSection(current: current, next: next)
            .onAppear {
                refreshProgressAndPrayerState()
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
            .onChange(of: scenePhase) { phase in
                handleScenePhaseChange(phase)
            }
            .onChange(of: settings.prayers) { _ in
                refreshProgressAndPrayerState()
                startTimer()
            }
            .onChange(of: currentPrayer) { _ in
                updateProgress()
                startTimer()
            }
            .onChange(of: nextPrayer) { _ in
                updateProgress()
                startTimer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                settings.hapticFeedback()
                withAnimation { settings.showPrayerInfo.toggle() }
            }
    }

    private func countdownSection(current: Prayer, next: Prayer) -> some View {
        Section(header: sectionHeader) {
            countdownBody(current: current, next: next)
        }
    }

    private func countdownBody(current: Prayer, next: Prayer) -> some View {
        Group {
            if #available(iOS 26, *) {
                VStack {
                    prayerSummary(current: current, next: next)
                    countdownProgress(next: next)
                    timeLeftRow(next: next)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.25)
            } else {
                VStack {
                    prayerSummary(current: current, next: next)
                    countdownProgress(next: next)
                    timeLeftRow(next: next)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.25)
                .padding(.vertical, 8)
            }
        }
    }

    private var sectionHeader: some View {
        HStack {
            Text("CURRENT")
            
            Spacer()
            
            Text("UPCOMING")
        }
    }

    @ViewBuilder
    private func prayerSummary(current: Prayer, next: Prayer) -> some View {
        VStack {
            summaryRow(current: current, next: next)
            
            if settings.showPrayerInfo {
                prayerInfoRow(current: current, next: next)
            }
        }
        .padding(.bottom, -2)
    }

    private func summaryRow(current: Prayer, next: Prayer) -> some View {
        HStack(alignment: .top) {
            CurrentPrayerCell(prayer: current)
            summaryDivider
            UpcomingPrayerCell(prayer: next)
        }
    }

    private var summaryDivider: some View {
        Divider()
            .background(settings.accentColor.color)
            .padding(.horizontal, 2)
    }

    private func prayerInfoRow(current: Prayer, next: Prayer) -> some View {
        VStack {
            Divider()
                .background(settings.accentColor.color)

            HStack(alignment: .top) {
                CurrentPrayerInfoView(prayer: current)
                UpcomingPrayerInfoView(prayer: next)
            }
        }
    }

    private func countdownProgress(next: Prayer) -> some View {
        ProgressView(value: progress)
            .tint(settings.accentColor.color)
            .conditionalGlassEffect()
            .padding(.vertical, 2)
            #if os(watchOS)
            .padding(.top, 4)
            #endif
    }

    private func timeLeftRow(next: Prayer) -> some View {
        Text("Time Left: \(next.time, style: .timer)")
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        if phase == .active {
            refreshProgressAndPrayerState()
            startTimer()
        } else {
            stopTimer()
        }
    }

    private func refreshProgressAndPrayerState() {
        settings.updateCurrentAndNextPrayer()
        updateProgress()
    }

    private func updateProgress() {
        progress = progressValue()
    }

    private func progressValue() -> Double {
        guard var start = currentPrayer?.time, var end = nextPrayer?.time else { return 0 }

        let now = Date()

        // Handle the common overnight boundary where the current prayer began the previous day.
        if start > now {
            start.addTimeInterval(-86_400)
        }

        if end <= start {
            end.addTimeInterval(86_400)
        }

        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }

        let remaining = end.timeIntervalSince(now)
        return max(0, min(1, 1 - remaining / total))
    }

    private func startTimer() {
        stopTimer()
        let interval = nextRefreshInterval()
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            DispatchQueue.main.async {
                refreshProgressAndPrayerState()
                startTimer()
            }
        }
        updateTimer?.tolerance = min(interval * 0.2, 5)
    }

    private func nextRefreshInterval() -> TimeInterval {
        guard let nextPrayer else { return slowTimerInterval }

        let remaining = nextPrayer.time.timeIntervalSinceNow
        if remaining <= urgentThreshold {
            return urgentTimerInterval
        }
        if remaining <= fastThreshold {
            return fastTimerInterval
        }
        if remaining <= mediumThreshold {
            return mediumTimerInterval
        }
        return slowTimerInterval
    }

    private func stopTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}

private struct CurrentPrayerCell: View {
    @EnvironmentObject private var settings: Settings

    let prayer: Prayer

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            title
            
            #if os(iOS)
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
            Text(prayer.nameTransliteration)
        }
        .modifier(PrayerTitleStyle(prayer: prayer))
    }

    private var subtitle: some View {
        PrayerSubtitleView(prayer: prayer, alignment: .leading)
    }
}

private struct UpcomingPrayerCell: View {
    @EnvironmentObject private var settings: Settings

    let prayer: Prayer

    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            title
            
            #if os(iOS)
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
        }
        .modifier(PrayerTitleStyle(prayer: prayer))
    }

    private var subtitle: some View {
        PrayerSubtitleView(prayer: prayer, alignment: .trailing)
    }
}

private struct PrayerTitleStyle: ViewModifier {
    @EnvironmentObject private var settings: Settings

    let prayer: Prayer

    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .font(.title3)
            #else
            .font(.subheadline)
            #endif
            .foregroundColor(prayer.nameTransliteration == "Shurooq" ? .primary : settings.accentColor.color)
    }
}

private struct PrayerSubtitleView: View {
    @EnvironmentObject private var settings: Settings

    let prayer: Prayer
    let alignment: TextAlignment

    private var isCombinedTravelPrayer: Bool {
        prayer.nameTransliteration.contains("/")
    }

    private var subtitleText: String {
        if isCombinedTravelPrayer {
            return prayer.nameArabic
        }
        return "\(prayer.nameEnglish) / \(prayer.nameArabic)"
    }

    private var subtitleColor: Color {
        prayer.nameTransliteration == "Shurooq" ? .primary.opacity(0.7) : settings.accentColor.color.opacity(0.7)
    }

    var body: some View {
        Text(subtitleText)
            .font(.title3)
            .foregroundColor(subtitleColor)
            .multilineTextAlignment(alignment)
    }
}

private struct CurrentPrayerInfoView: View {
    let prayer: Prayer

    var body: some View {
        PrayerInfoColumn(prayer: prayer, alignment: .leading)
    }
}

private struct UpcomingPrayerInfoView: View {
    let prayer: Prayer

    var body: some View {
        PrayerInfoColumn(prayer: prayer, alignment: .trailing)
    }
}

private struct PrayerInfoColumn: View {
    let prayer: Prayer
    let alignment: Alignment

    var body: some View {
        VStack(alignment: horizontalAlignment, spacing: 5) {
            PrayerRakahInfoView(prayer: prayer, captionFont: .caption, alignment: alignment)
            PrayerSunnahInfoView(prayer: prayer, alignment: alignment)
        }
        .frame(maxWidth: .infinity, alignment: alignment)
        .multilineTextAlignment(textAlignment)
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

    private var textAlignment: TextAlignment {
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

private struct PrayerRakahInfoView: View {
    let prayer: Prayer
    let captionFont: Font
    let alignment: Alignment

    var body: some View {
        Group {
            if prayer.rakah != "0" {
                Text("Prayer Rakahs: \(prayer.rakah)")
                    #if os(iOS)
                    .font(captionFont)
                    #else
                    .font(.caption2)
                    #endif
                    .foregroundColor(.primary)
            } else {
                Text("Shurooq is not a prayer, but marks the end of Fajr")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
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
