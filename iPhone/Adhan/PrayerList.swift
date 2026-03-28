import SwiftUI

struct PrayerList: View {
    @EnvironmentObject private var settings: Settings

    @State private var expandedPrayer: Prayer?
    @State private var fullPrayers = false
    @State private var animatingBellPrayerName: String?
    @State private var bellAnimationActive = false
    @State private var selectedDate = Date()

    @AppStorage("prayerDisplayMode") private var prayerDisplayModeRawValue: String = PrayerDisplayMode.list.rawValue

    enum PrayerDisplayMode: String, CaseIterable, Identifiable {
        case list = "Prayer List"
        case grid = "Prayer Grid"
        case split = "Prayer Split"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .list: return "LIST"
            case .grid: return "GRID"
            case .split: return "SPLIT"
            }
        }
    }

    private var prayerDisplayMode: PrayerDisplayMode {
        PrayerDisplayMode(rawValue: prayerDisplayModeRawValue) ?? .list
    }

    private var displayedPrayers: [Prayer] {
        if settings.changedDate {
            return fullPrayers ? (settings.dateFullPrayers ?? []) : (settings.datePrayers ?? [])
        }

        guard let prayers = settings.prayers else { return [] }
        return fullPrayers ? prayers.fullPrayers : prayers.prayers
    }

    var body: some View {
        if settings.prayers != nil {
            prayerListSection
        }
    }

    private var prayerListSection: some View {
        Section(header: sectionHeader) {
            prayerContentStack
        }
    }

    @ViewBuilder
    private var prayerContentStack: some View {
        prayerModeContent(prayers: displayedPrayers)
        travelModeFooter
        dateSelectionFooter
    }

    private var sectionHeader: some View {
        HStack {
            Text("PRAYER TIMES")

            #if !os(watchOS)
            Spacer()

            Picker("", selection: $prayerDisplayModeRawValue.animation(.easeInOut)) {
                ForEach(PrayerDisplayMode.allCases) { mode in
                    Text(mode.displayName).tag(mode.rawValue)
                }
            }
            .font(.caption2)
            .pickerStyle(MenuPickerStyle())
            .padding(.vertical, -12)
            #endif
        }
    }

    @ViewBuilder
    private func prayerModeContent(prayers: [Prayer]) -> some View {
        switch prayerDisplayMode {
        case .list:
            listContent(prayers: prayers)
        case .grid:
            gridContent(prayers: prayers)
        case .split:
            splitContent(prayers: prayers)
        }
    }

    @ViewBuilder
    private func listContent(prayers: [Prayer]) -> some View {
        ForEach(prayers) { prayer in
            listRow(for: prayer, in: prayers)
        }
        .onChange(of: settings.travelingMode) { _ in
            withAnimation {
                fullPrayers = false
            }
        }
    }

    private func listRow(for prayer: Prayer, in prayers: [Prayer]) -> some View {
        let isExpanded = expandedPrayer == prayer
        let isCurrent = isCurrentPrayer(prayer)
        let listIconColor = prayer.nameTransliteration == "Shurooq" ? Color.primary : settings.accentColor.color
        let bellRowColor = prayer.nameTransliteration == "Shurooq" ? Color.primary : .primary

        return VStack(alignment: .leading, spacing: 8) {
            PrayerListRowCard(
                prayer: prayer,
                isCurrent: isCurrent,
                iconColor: listIconColor,
                trailingContent: {
                    #if !os(watchOS)
                    prayerBell(for: prayer, rowColor: bellRowColor)
                    #endif
                }
            )
            .padding(.bottom, rowBottomPadding(isExpanded: isExpanded, isCurrent: isCurrent))

            if isExpanded {
                PrayerDetailBlock(prayer: prayer, referenceText: prayerReferenceText(for: prayer))
                    .clipShape(Rectangle())
                    .buttonStyle(.plain)
            }
        }
        .onTapGesture {
            settings.hapticFeedback()
            withAnimation {
                expandedPrayer = isExpanded ? nil : prayer
            }
        }
    }

    @ViewBuilder
    private func gridContent(prayers: [Prayer]) -> some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 12),
            count: prayers.count == 4 ? 2 : 3
        )

        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(prayers) { prayer in
                PrayerGridTile(
                    prayer: prayer,
                    color: legacyGridPrayerColor(for: prayer, in: prayers)
                )
            }
        }
        .padding(.horizontal, -20)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }

    @ViewBuilder
    private func splitContent(prayers: [Prayer]) -> some View {
        let midpoint = Int(floor(Double(prayers.count) / 2.0))
        let firstHalf = Array(prayers.prefix(midpoint))
        let secondHalf = Array(prayers.suffix(prayers.count - midpoint))

        HStack(spacing: 0) {
            VStack(spacing: 4) {
                ForEach(firstHalf) { prayer in
                    SplitPrayerRow(prayer: prayer, color: prayerColor(for: prayer, in: prayers))
                }
            }

            Divider()
                .background(settings.accentColor.color)
                .padding(.horizontal, 8)

            VStack(spacing: 4) {
                ForEach(secondHalf) { prayer in
                    SplitPrayerRow(prayer: prayer, color: prayerColor(for: prayer, in: prayers))
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }

    @ViewBuilder
    private var travelModeFooter: some View {
        if settings.travelingMode {
            VStack {
                #if !os(watchOS)
                travelingModeDescription
                #endif

                footerActionButton(fullPrayers ? "View Qasr Prayers" : "View Full Prayers") {
                    fullPrayers.toggle()
                }

                #if os(watchOS)
                travelingModeDescription
                #endif
            }
        }
    }

    @ViewBuilder
    private var dateSelectionFooter: some View {
        #if !os(watchOS)
        VStack {
            DatePicker("Showing prayers for", selection: $selectedDate.animation(.easeInOut), displayedComponents: .date)
                .datePickerStyle(DefaultDatePickerStyle())
                .padding(4)

            if !Calendar.current.isDate(selectedDate, inSameDayAs: Date()) {
                footerActionButton("Show prayers for today") {
                    selectedDate = Date()
                }
            }
        }
        .onChange(of: selectedDate) { value in
            updateDisplayedDate(to: value)
        }
        #endif
    }

    private var travelingModeDescription: some View {
        Text("Traveling mode is on. If you are traveling more than 48 mi, then you can pray Qasr, where you combine prayers. You can customize and learn more in settings.")
            .font(.caption)
            .foregroundColor(.secondary)
    }

    private func footerActionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Text(title)
            .font(.subheadline)
            .foregroundColor(settings.accentColor.color)
            .padding(.vertical, 8)
            .onTapGesture {
                settings.hapticFeedback()
                withAnimation {
                    action()
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .conditionalGlassEffect()
    }

    private func updateDisplayedDate(to value: Date) {
        if let result = settings.getPrayerTimesNormalAndFull(for: value) {
            settings.datePrayers = result.normal
            settings.dateFullPrayers = result.full
        } else {
            settings.datePrayers = []
            settings.dateFullPrayers = []
        }

        settings.changedDate = !Calendar.current.isDate(value, inSameDayAs: Date())
    }

    private func isCurrentPrayer(_ prayer: Prayer) -> Bool {
        settings.currentPrayer?.nameTransliteration.contains(prayer.nameTransliteration) ?? false
    }

    private func rowBottomPadding(isExpanded: Bool, isCurrent: Bool) -> CGFloat {
        guard isExpanded else { return 0 }
        return isCurrent ? 8 : 0
    }

    private func prayerColor(for prayer: Prayer, in prayers: [Prayer]) -> Color {
        guard let prayerIndex = prayers.firstIndex(where: { $0.id == prayer.id }) else {
            return .secondary
        }

        guard let currentPrayerIndex = prayers.firstIndex(where: { $0.nameTransliteration == settings.currentPrayer?.nameTransliteration }) else {
            return .secondary
        }

        if prayerIndex < currentPrayerIndex {
            return .secondary
        }
        if prayerIndex == currentPrayerIndex {
            return settings.accentColor.color
        }
        return .primary
    }

    private func legacyGridPrayerColor(for prayer: Prayer, in prayers: [Prayer]) -> Color {
        guard let currentPrayer = settings.currentPrayer else {
            return .secondary
        }

        if currentPrayer.nameTransliteration.contains(prayer.nameTransliteration) {
            return settings.accentColor.color
        }

        guard let currentPrayerIndex = prayers.firstIndex(where: { $0.id == currentPrayer.id }),
              let prayerIndex = prayers.firstIndex(where: { $0.id == prayer.id }) else {
            return .secondary
        }

        return prayerIndex < currentPrayerIndex ? .secondary : .primary
    }

    private func prayerReferenceText(for prayer: Prayer) -> String? {
        if prayer.nameTransliteration == "Fajr" {
            return "Prophet Muhammad (peace be upon him) said: \"The time for Fajr prayer is from the appearance of dawn until the sun begins to rise\" (Sahih Muslim 612)."
        }
        if prayer.nameTransliteration.contains("Dhuhr") {
            return "Prophet Muhammad (peace be upon him) said: \"The time for Dhuhr is when the sun has passed its zenith and a person’s shadow is equal in length to his height, until the time for Asr begins\" (Muslim 612)."
        }
        if prayer.nameTransliteration == "Jumuah" {
            return "Prophet Muhammad (peace be upon him) said: \"The Friday prayer is obligatory upon every Muslim in the time of Dhuhr, except for a child, a woman, or an ill person\" (Abu Dawood 1067)."
        }
        if prayer.nameTransliteration == "Asr" {
            return "Prophet Muhammad (peace be upon him) said: \"The time for Asr prayer lasts until the sun turns yellow\" (Muslim 612)."
        }
        if prayer.nameTransliteration.contains("Maghrib") {
            return "Prophet Muhammad (peace be upon him) said: \"The time for Maghrib lasts until the twilight has faded\" (Muslim 612)."
        }
        if prayer.nameTransliteration == "Isha" {
            return "Prophet Muhammad (peace be upon him) said: \"The time for Isha lasts until the middle of the night\" (Muslim 612)."
        }
        return nil
    }

    private func triggerBellAnimation(for prayer: Prayer) {
        animatingBellPrayerName = prayer.nameTransliteration

        withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) {
            bellAnimationActive = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.18)) {
                bellAnimationActive = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            if animatingBellPrayerName == prayer.nameTransliteration {
                animatingBellPrayerName = nil
            }
        }
    }

    private func bellScale(for prayer: Prayer) -> CGFloat {
        animatingBellPrayerName == prayer.nameTransliteration && bellAnimationActive ? 1.2 : 1.0
    }

    private func bellRotation(for prayer: Prayer) -> Angle {
        animatingBellPrayerName == prayer.nameTransliteration && bellAnimationActive ? .degrees(18) : .degrees(0)
    }

    @ViewBuilder
    private func prayerBell(for prayer: Prayer, rowColor: Color) -> some View {
        let mode = settings.notificationMode(for: prayer)

        Button {
            settings.hapticFeedback()
            triggerBellAnimation(for: prayer)
            settings.cycleNotificationMode(for: prayer)
        } label: {
            Image(systemName: mode.symbolName)
                .font(.subheadline)
                .frame(width: 18, height: 18)
                .foregroundColor(mode == .off ? rowColor : settings.accentColor.color)
                .scaleEffect(bellScale(for: prayer))
                .rotationEffect(bellRotation(for: prayer))
        }
        .buttonStyle(.plain)
        .padding(4)
        .conditionalGlassEffect()
        .padding(.leading, 6)
        #if !os(watchOS)
        .contextMenu {
            Button {
                settings.hapticFeedback()
                settings.setNotificationMode(.preNotification, for: prayer)
            } label: {
                Label("Prenotification", systemImage: Settings.PrayerNotificationMode.preNotification.symbolName)
            }

            Button {
                settings.hapticFeedback()
                settings.setNotificationMode(.atTime, for: prayer)
            } label: {
                Label("Notification", systemImage: Settings.PrayerNotificationMode.atTime.symbolName)
            }

            Button {
                settings.hapticFeedback()
                settings.setNotificationMode(.off, for: prayer)
            } label: {
                Label("No Notification", systemImage: Settings.PrayerNotificationMode.off.symbolName)
            }
        }
        #endif
    }
}

private struct PrayerListRowCard<TrailingContent: View>: View {
    @EnvironmentObject private var settings: Settings

    let prayer: Prayer
    let isCurrent: Bool
    let iconColor: Color
    @ViewBuilder let trailingContent: () -> TrailingContent

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(isCurrent ? settings.accentColor.color.opacity(0.25) : .white.opacity(0.00001))
                #if !os(watchOS)
                .padding(.vertical, backgroundVerticalPadding)
                .padding(.horizontal, -12)
                #else
                .padding(.horizontal, -10)
                #endif

            HStack {
                HStack {
                    Image(systemName: prayer.image)
                        .font(.title3)
                        .foregroundColor(iconColor)
                        .frame(width: 32, alignment: .center)
                        .padding(.trailing, 2)

                    VStack(alignment: .leading) {
                        Text(prayer.nameTransliteration)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Text(prayer.time, style: .time)
                        #if !os(watchOS)
                        .font(.subheadline)
                        #else
                        .font(.caption)
                        #endif
                        .foregroundColor(.primary)
                }
                .clipShape(Rectangle())
                .buttonStyle(.plain)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

                trailingContent()
            }
        }
    }

    #if !os(watchOS)
    private var backgroundVerticalPadding: CGFloat {
        if #available(iOS 26.0, *) {
            return -10
        }
        return -4
    }
    #endif
}

private struct PrayerDetailBlock: View {
    @EnvironmentObject private var settings: Settings

    let prayer: Prayer
    let referenceText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(prayer.nameEnglish) - \(prayer.nameArabic)")
                .font(.title3)
                .foregroundColor(settings.accentColor.color)

            if prayer.nameTransliteration == "Shurooq" {
                Text("Shurooq is not a prayer, but marks the end of Fajr.")
                    .foregroundColor(.primary)
                    .font(.footnote)
            } else {
                if prayer.rakah != "0" {
                    Text("Prayer Rakahs: \(prayer.rakah)")
                        .foregroundColor(.primary)
                        .font(.body)
                }

                if prayer.sunnahBefore != "0" {
                    Text("Sunnah Rakahs Before: \(prayer.sunnahBefore)")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }

                if prayer.sunnahAfter != "0" {
                    Text("Sunnah Rakahs After: \(prayer.sunnahAfter)")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
            }

            if let referenceText {
                Text(referenceText)
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
    }
}

private struct PrayerGridTile: View {
    let prayer: Prayer
    let color: Color

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: prayer.image)
                    .font(.subheadline)
                    .foregroundColor(color)
                    .padding(.trailing, -2)

                Text(prayer.nameTransliteration)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            Text(prayer.time, style: .time)
                .font(.subheadline)
                .foregroundColor(color)
        }
    }
}

private struct SplitPrayerRow: View {
    let prayer: Prayer
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: prayer.image)
                .font(.subheadline)
                .frame(width: 20, alignment: .center)

            Text(prayer.nameTransliteration)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer()

            Text(prayer.time, style: .time)
                .fontWeight(.bold)
        }
        .foregroundColor(color)
    }
}

#Preview {
    AlIslamPreviewContainer {
        List {
            PrayerList()
        }
    }
}
