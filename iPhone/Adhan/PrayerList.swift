import SwiftUI

struct PrayerList: View {
    @EnvironmentObject private var settings: Settings

    @State private var expandedPrayerKey: String?
    @State private var fullPrayers = false
    @State private var animatingBellPrayerName: String?
    @State private var bellAnimationActive = false
    @State private var selectedDate = Date()
    @State private var compareToday = true

    // New storage key (V2) so every existing user is reset to the new Tiles default, regardless of what
    // they had saved under the old "prayerDisplayMode" key.
    @AppStorage("prayerDisplayModeV2") private var prayerDisplayModeRawValue: String = PrayerDisplayMode.tiles.rawValue

    enum PrayerDisplayMode: String, CaseIterable, Identifiable {
        case list = "Prayer List"
        case grid = "Prayer Grid"
        case tiles = "Prayer Tiles"
        case split = "Prayer Split"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .list: return "LIST"
            case .grid: return "GRID"
            case .tiles: return "TILES"
            case .split: return "SPLIT"
            }
        }
    }

    private var prayerDisplayMode: PrayerDisplayMode {
        PrayerDisplayMode(rawValue: prayerDisplayModeRawValue) ?? .tiles
    }

    private static let selectedDateHeaderFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private func expansionKey(for prayer: Prayer) -> String {
        prayer.stableDisplayID
    }

    private func listDisplayName(for prayer: Prayer) -> String {
        prayer.nameTransliteration
    }

    private func togglePrayerExpansion(for prayer: Prayer, animated: Bool = true) {
        let prayerKey = expansionKey(for: prayer)
        settings.hapticFeedback()
        let update = {
            expandedPrayerKey = expandedPrayerKey == prayerKey ? nil : prayerKey
        }
        if animated {
            withAnimation {
                update()
            }
        } else {
            update()
        }
    }

    private func mergedWithOptional(_ base: [Prayer], for date: Date) -> [Prayer] {
        settings.prayersIncludingOptional(base, for: date)
    }

    private var displayedPrayers: [Prayer] {
        if settings.changedDate {
            let base = fullPrayers ? (settings.dateFullPrayers ?? []) : (settings.datePrayers ?? [])
            return mergedWithOptional(base, for: selectedDate)
        }

        guard let prayers = settings.prayers else { return [] }
        let base = fullPrayers ? prayers.fullPrayers : prayers.prayers
        return mergedWithOptional(base, for: prayers.day)
    }

    private var todayPrayers: [Prayer] {
        guard let prayers = settings.prayers else { return [] }
        let base = fullPrayers ? prayers.fullPrayers : prayers.prayers
        return mergedWithOptional(base, for: prayers.day)
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
        if settings.changedDate && compareToday {
            prayerGroupHeader("TODAY")
            prayerModeContent(prayers: todayPrayers, isComparisonBaseline: true)
                .opacity(0.45)

            prayerGroupHeader(selectedDateHeaderText)
        }

        prayerModeContent(prayers: displayedPrayers)
        travelModeFooter
        dateSelectionFooter
    }

    private var selectedDateHeaderText: String {
        Self.selectedDateHeaderFormatter.string(from: selectedDate).uppercased()
    }

    private func prayerGroupHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sectionHeader: some View {
        HStack {
            Text("PRAYER TIMES")

            #if os(iOS)
            Spacer()

            Picker("", selection: $prayerDisplayModeRawValue.animation(.easeInOut)) {
                Section {
                    ForEach(PrayerDisplayMode.allCases) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                } header: {
                    Text("Prayer Display")
                }
            }
            .font(.caption2)
            .pickerStyle(MenuPickerStyle())
            .padding(.vertical, -12)
            #endif
        }
    }

    @ViewBuilder
    private func prayerModeContent(prayers: [Prayer], isComparisonBaseline: Bool = false) -> some View {
        switch prayerDisplayMode {
        case .list:
            listContent(prayers: prayers, isComparisonBaseline: isComparisonBaseline)
        case .grid:
            gridContent(prayers: prayers, isComparisonBaseline: isComparisonBaseline)
        case .split:
            splitContent(prayers: prayers, isComparisonBaseline: isComparisonBaseline)
        case .tiles:
            tilesContent(prayers: prayers, isComparisonBaseline: isComparisonBaseline)
        }
    }

    @ViewBuilder
    private func listContent(prayers: [Prayer], isComparisonBaseline: Bool = false) -> some View {
        ForEach(prayers, id: \.stableDisplayID) { prayer in
            listRow(for: prayer, in: prayers, isComparisonBaseline: isComparisonBaseline)
        }
        .onChange(of: settings.travelingMode) { _ in
            withAnimation {
                fullPrayers = false
            }
        }
    }

    private func listRow(for prayer: Prayer, in prayers: [Prayer], isComparisonBaseline: Bool = false) -> some View {
        let prayerKey = expansionKey(for: prayer)
        let isExpanded = expandedPrayerKey == prayerKey
        let isCurrent = !isComparisonBaseline && isCurrentPrayer(prayer)
        let listIconColor = prayer.nameTransliteration == "Shurooq" ? Color.primary : settings.accentColor.color

        return Group {
            PrayerListRowCard(
                prayer: prayer,
                displayName: listDisplayName(for: prayer),
                isCurrent: isCurrent,
                iconColor: listIconColor,
                trailingContent: {
                    #if os(iOS)
                    prayerBell(for: prayer, rowColor: .primary)
                    #endif
                }
            )

            if isExpanded {
                expandedPrayerDetailContent(for: prayer)
                    .contentShape(Rectangle())
            }
        }
        .onTapGesture {
            togglePrayerExpansion(for: prayer)
        }
    }

    @ViewBuilder
    private func gridContent(prayers: [Prayer], isComparisonBaseline: Bool = false) -> some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 12),
            count: prayers.count == 4 ? 2 : 3
        )

        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(prayers, id: \.stableDisplayID) { prayer in
                let color: Color = isComparisonBaseline ? .secondary : legacyGridPrayerColor(for: prayer, in: prayers)

                PrayerGridTile(
                    prayer: prayer,
                    color: color,
                    trailingContent: {
                        EmptyView()
                    }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    togglePrayerExpansion(for: prayer)
                }
            }
        }
        .padding(.horizontal, -20)
        .lineLimit(1)
        .minimumScaleFactor(0.5)

        expandedPrayerDetail(for: prayers)
    }

    @ViewBuilder
    private func splitContent(prayers: [Prayer], isComparisonBaseline: Bool = false) -> some View {
        let midpoint = Int(floor(Double(prayers.count) / 2.0))
        let firstHalf = Array(prayers.prefix(midpoint))
        let secondHalf = Array(prayers.suffix(prayers.count - midpoint))

        HStack(spacing: 0) {
            VStack(spacing: 4) {
                ForEach(firstHalf, id: \.stableDisplayID) { prayer in
                    let color: Color = isComparisonBaseline ? .secondary : prayerColor(for: prayer, in: prayers)

                    SplitPrayerRow(
                        prayer: prayer,
                        color: color,
                        trailingContent: {
                            EmptyView()
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        togglePrayerExpansion(for: prayer)
                    }
                }
            }

            Divider()
                .background(settings.accentColor.color)
                .padding(.horizontal, 8)

            VStack(spacing: 4) {
                ForEach(secondHalf, id: \.stableDisplayID) { prayer in
                    let color: Color = isComparisonBaseline ? .secondary : prayerColor(for: prayer, in: prayers)

                    SplitPrayerRow(
                        prayer: prayer,
                        color: color,
                        trailingContent: {
                            EmptyView()
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        togglePrayerExpansion(for: prayer)
                    }
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)

        expandedPrayerDetail(for: prayers)
    }

    @ViewBuilder
    private func tilesContent(prayers: [Prayer], isComparisonBaseline: Bool = false) -> some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 10),
            count: settings.travelingMode ? 2 : 3
        )

        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(prayers, id: \.stableDisplayID) { prayer in
                let color: Color = isComparisonBaseline ? .secondary : prayerColor(for: prayer, in: prayers)
                let isCurrent = !isComparisonBaseline && isCurrentPrayer(prayer)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Image(systemName: prayer.image)
                            .font(.subheadline)
                            .foregroundColor(color)

                        Spacer()

                        #if os(iOS)
                        if !isComparisonBaseline {
                            prayerBell(for: prayer, rowColor: color)
                        }
                        #endif
                    }

                    Text(prayer.compactDisplayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(color)

                    Text(prayer.time, style: .time)
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .conditionalGlassEffect(
                    rectangle: true,
                    useColor: isCurrent ? 0.22 : 0.12,
                    customTint: isCurrent ? settings.accentColor.color : nil
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    togglePrayerExpansion(for: prayer)
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .onChange(of: settings.travelingMode) { _ in
            withAnimation { fullPrayers = false }
        }

        expandedPrayerDetail(for: prayers)
    }

    @ViewBuilder
    private func expandedPrayerDetail(for prayers: [Prayer]) -> some View {
        if let prayer = prayers.first(where: { expansionKey(for: $0) == expandedPrayerKey }) {
            expandedPrayerDetailContent(for: prayer)
            .id(prayer.stableDisplayID)
            .contentShape(Rectangle())
        }
    }

    private func expandedPrayerDetailContent(for prayer: Prayer) -> some View {
        HStack(alignment: .top, spacing: 10) {
            PrayerDetailBlock(prayer: prayer, referenceText: prayerReferenceText(for: prayer))
                .frame(maxWidth: .infinity, alignment: .leading)

            #if os(iOS)
            if prayerDisplayMode != .list && prayerDisplayMode != .tiles {
                prayerBell(for: prayer, rowColor: .primary)
            }
            #endif
        }
    }

    @ViewBuilder
    private var travelModeFooter: some View {
        if settings.travelingMode {
            VStack {
                #if os(iOS)
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
        #if os(iOS)
        VStack {
            DatePicker("Showing prayers for", selection: $selectedDate.animation(.easeInOut), displayedComponents: .date)
                .datePickerStyle(DefaultDatePickerStyle())
                .padding(4)

            if !Calendar.current.isDate(selectedDate, inSameDayAs: Date()) {
                footerActionButton(compareToday ? "Hide Today Comparison" : "Compare With Today") {
                    compareToday.toggle()
                }

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
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func footerActionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Text(title)
            .foregroundColor(settings.accentColor.color)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(8)
            .conditionalGlassEffect()
            .onTapGesture {
                settings.hapticFeedback()
                withAnimation {
                    action()
                }
            }
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
        if settings.changedDate {
            compareToday = true
        }
    }

    private func isCurrentPrayer(_ prayer: Prayer) -> Bool {
        settings.currentPrayer?.nameTransliteration.contains(prayer.nameTransliteration) ?? false
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
        if prayer.nameTransliteration == "Duhaa" {
            return """
            Duhaa is a voluntary prayer prayed after the sun has risen to the height of a spear, roughly 15 minutes after sunrise, until shortly before Dhuhr. Its best time is later in the morning, when the heat of the sun becomes stronger.

            "The forenoon prayer of the penitent is when young camels can feel the heat of the sun" (Muslim 784).

            "My friend (the Prophet (ﷺ) ) advised me to observe three things: (1) to fast three days a month; (2) to pray two rak`at of Duha prayer (forenoon prayer); and (3) to pray witr before sleeping." (Bukhari 1981).
            """
        }
        if prayer.nameTransliteration == "Islamic Midnight" {
            return """
            Islamic Midnight is halfway between Maghrib and the next Fajr. It marks the end of Isha and is used for calculating parts of the night.

            Formula: Islamic Midnight = Maghrib + ((Fajr - Maghrib) / 2)

            "When you pray Isha, its time is until half of the night has passed" (Muslim 612a).
            """
        }
        if prayer.nameTransliteration == "Last Third" {
            return """
            Tahajjud is commonly prayed during the last third of the night. A voluntary night prayer offered after Isha and before Fajr, its most virtuous time is during the final third of the night.

            The final third of the night before Fajr is a blessed time for prayer, dua, and seeking forgiveness.

            Formula: Last third starts = Fajr - ((Fajr - Maghrib) / 3)

            "Allah descends every night to the lowest heaven when one-third of the first part of the night is over and says: I am the Lord; I am the Lord: who is there to supplicate Me so that I answer him? Who is there to beg of Me so that I grant him? Who is there to beg forgiveness from Me so that I forgive him? He continues like this till the day breaks" (Muslim 758b).
            """
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

        Image(systemName: mode.symbolName)
            .font(.subheadline)
            .frame(width: 18, height: 18)
            .foregroundColor(mode == .off ? rowColor : settings.accentColor.color)
            .scaleEffect(bellScale(for: prayer))
            .rotationEffect(bellRotation(for: prayer))
            .contentShape(Rectangle())
            .padding(4)
            .conditionalGlassEffect()
            .onTapGesture {
                settings.hapticFeedback()
                triggerBellAnimation(for: prayer)
                settings.cycleNotificationMode(for: prayer)
            }
            .padding(.leading, 6)
            #if os(iOS)
            .contextMenu {
                Text("Notifications")
                    .foregroundStyle(.secondary)

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
    let displayName: String
    let isCurrent: Bool
    let iconColor: Color
    @ViewBuilder let trailingContent: () -> TrailingContent

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(isCurrent ? settings.accentColor.color.opacity(0.25) : .clear)
                #if os(iOS)
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
                        Text(displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Text(prayer.time, style: .time)
                        #if os(iOS)
                        .font(.subheadline)
                        #else
                        .font(.caption)
                        #endif
                        .foregroundColor(.primary)
                }
                .contentShape(Rectangle())
                .lineLimit(1)
                .minimumScaleFactor(0.5)

                trailingContent()
            }
        }
    }

    #if os(iOS)
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

    private var isOptionalPrayer: Bool {
        Settings.optionalPrayerNames.contains(prayer.nameTransliteration)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(isOptionalPrayer ? prayer.nameEnglish : "\(prayer.nameEnglish) - \(prayer.nameArabic)")
                .font(.title3)
                .foregroundColor(settings.accentColor.color)
                .lineLimit(1)

            if prayer.nameTransliteration == "Shurooq" {
                Text("Shurooq is not a prayer, but marks the end of Fajr.")
                    .foregroundColor(.primary)
                    .font(.footnote)
            } else if prayer.nameTransliteration == "Islamic Midnight" {
                Text("Midnight is not a prayer, but marks the end of Isha.")
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

private extension Prayer {
    var stableDisplayID: String {
        "\(nameTransliteration)-\(Int(time.timeIntervalSince1970))"
    }

    var compactDisplayName: String {
        nameTransliteration == "Islamic Midnight" ? "Midnight" : nameTransliteration
    }
}

private struct PrayerGridTile<TrailingContent: View>: View {
    let prayer: Prayer
    let color: Color
    @ViewBuilder let trailingContent: () -> TrailingContent

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: prayer.image)
                    .font(.subheadline)
                    .foregroundColor(color)
                    .padding(.trailing, -2)

                Text(prayer.compactDisplayName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                trailingContent()
            }

            Text(prayer.time, style: .time)
                .font(.subheadline)
                .foregroundColor(color)
        }
    }
}

private struct SplitPrayerRow<TrailingContent: View>: View {
    let prayer: Prayer
    let color: Color
    @ViewBuilder let trailingContent: () -> TrailingContent

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: prayer.image)
                .font(.subheadline)
                .frame(width: 20, alignment: .center)

            Text(prayer.compactDisplayName)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer()

            Text(prayer.time, style: .time)
                .fontWeight(.bold)

            trailingContent()
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
