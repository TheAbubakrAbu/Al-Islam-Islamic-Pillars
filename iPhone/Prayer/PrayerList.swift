import SwiftUI

struct PrayerList: View {
    @EnvironmentObject var settings: Settings
    
    @State private var expandedPrayer: Prayer?
    @State private var fullPrayers: Bool = false
    
    @AppStorage("prayerDisplayMode") private var prayerDisplayModeRawValue: String = PrayerDisplayMode.list.rawValue

    enum PrayerDisplayMode: String, CaseIterable, Identifiable {
        case list = "Prayer List"
        case grid = "Prayer Grid"
        
        var id: String { self.rawValue }

        var displayName: String {
            switch self {
            case .list: return "LIST"
            case .grid: return "GRID"
            }
        }
    }
    
    func getPrayerColor(for prayer: Prayer) -> Color {
        guard let prayers = settings.prayers?.prayers else {
            return .secondary
        }
        
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
        
        if prayerIndex < currentPrayerIndex {
            return .secondary
        }
        
        return .primary
    }
    
    var body: some View {
        if let prayerObject = settings.prayers {
            let prayerTimes = prayerObject.prayers
            let fullPrayerTimes = prayerObject.fullPrayers
            
            let datePrayerTimes = settings.datePrayers ?? []
            let dateFullPrayerTimes = settings.dateFullPrayers ?? []
            
            let calendar = Calendar.current
            
            Section(header:
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
            ) {
                if PrayerDisplayMode(rawValue: prayerDisplayModeRawValue) == .list {
                    Group {
                        ForEach(
                            settings.changedDate
                            ? (fullPrayers ? dateFullPrayerTimes : datePrayerTimes)
                            : (fullPrayers ? fullPrayerTimes : prayerTimes)
                        ) { prayerTime in
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(settings.currentPrayer?.nameTransliteration.contains(prayerTime.nameTransliteration) ?? false ? settings.accentColor.color.opacity(0.25) : .clear)
                                    .padding(.horizontal, -12)
                                
                                HStack {
                                    Button(action: {
                                        settings.hapticFeedback()
                                        
                                        withAnimation {
                                            if let expandedPrayer = expandedPrayer, prayerTime == expandedPrayer {
                                                self.expandedPrayer = nil
                                            } else {
                                                self.expandedPrayer = prayerTime
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: prayerTime.image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 30, height: 30)
                                                .foregroundColor(prayerTime.nameTransliteration == "Shurooq" ? .primary : settings.accentColor.color)
                                                .padding(.all, 4)
                                                .padding(.trailing, 8)
                                            
                                            VStack(alignment: .leading) {
                                                Text(prayerTime.nameTransliteration)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                
                                                Text(prayerTime.time, style: .time)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            #if !os(watchOS)
                                            VStack(alignment: .trailing) {
                                                
                                                Text(prayerTime.nameEnglish)
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                                
                                                Text(prayerTime.nameArabic)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            #endif
                                        }
                                    }
                                    
                                    #if !os(watchOS)
                                    Image(systemName: settings.shouldShowFilledBell(prayerTime: prayerTime) ? "bell.fill" : settings.shouldShowOutlinedBell(prayerTime: prayerTime) ? "bell" : "bell.slash")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .onTapGesture {
                                            settings.hapticFeedback()
                                            
                                            if settings.shouldShowOutlinedBell(prayerTime: prayerTime) {
                                                switch prayerTime.nameTransliteration {
                                                case "Fajr":
                                                    settings.preNotificationFajr = 15
                                                    settings.notificationFajr = true
                                                case "Shurooq":
                                                    settings.preNotificationSunrise = 15
                                                    settings.notificationSunrise = true
                                                case "Dhuhr", "Dhuhr/Asr", "Jummuah":
                                                    settings.preNotificationDhuhr = 15
                                                    settings.notificationDhuhr = true
                                                case "Asr":
                                                    settings.preNotificationAsr = 15
                                                    settings.notificationAsr = true
                                                case "Maghrib", "Maghrib/Isha":
                                                    settings.preNotificationMaghrib = 15
                                                    settings.notificationMaghrib = true
                                                case "Isha":
                                                    settings.preNotificationIsha = 15
                                                    settings.notificationIsha = true
                                                default:
                                                    break
                                                }
                                            } else if settings.shouldShowFilledBell(prayerTime: prayerTime) {
                                                switch prayerTime.nameTransliteration {
                                                case "Fajr":
                                                    settings.preNotificationFajr = 0
                                                    settings.notificationFajr = false
                                                case "Shurooq":
                                                    settings.preNotificationSunrise = 0
                                                    settings.notificationSunrise = false
                                                case "Dhuhr", "Dhuhr/Asr", "Jummuah":
                                                    settings.preNotificationDhuhr = 0
                                                    settings.notificationDhuhr = false
                                                case "Asr":
                                                    settings.preNotificationAsr = 0
                                                    settings.notificationAsr = false
                                                case "Maghrib", "Maghrib/Isha":
                                                    settings.preNotificationMaghrib = 0
                                                    settings.notificationMaghrib = false
                                                case "Isha":
                                                    settings.preNotificationIsha = 0
                                                    settings.notificationIsha = false
                                                default:
                                                    break
                                                }
                                            } else {
                                                switch prayerTime.nameTransliteration {
                                                case "Fajr":
                                                    settings.preNotificationFajr = 0
                                                    settings.notificationFajr = true
                                                case "Shurooq":
                                                    settings.preNotificationSunrise = 0
                                                    settings.notificationSunrise = true
                                                case "Dhuhr", "Dhuhr/Asr", "Jummuah":
                                                    settings.preNotificationDhuhr = 0
                                                    settings.notificationDhuhr = true
                                                case "Asr":
                                                    settings.preNotificationAsr = 0
                                                    settings.notificationAsr = true
                                                case "Maghrib", "Maghrib/Isha":
                                                    settings.preNotificationMaghrib = 0
                                                    settings.notificationMaghrib = true
                                                case "Isha":
                                                    settings.preNotificationIsha = 0
                                                    settings.notificationIsha = true
                                                default:
                                                    break
                                                }
                                            }
                                        }
                                        .frame(width: 18, height: 18)
                                        .foregroundColor(
                                            prayerTime.nameTransliteration == "Shurooq" ? .primary :
                                                (settings.shouldShowFilledBell(prayerTime: prayerTime) || settings.shouldShowOutlinedBell(prayerTime: prayerTime)) ? settings.accentColor.color : .primary
                                        )
                                        .padding(.leading, 6)
                                        .contextMenu {
                                            Button(action: {
                                                settings.hapticFeedback()
                                                
                                                switch prayerTime.nameTransliteration {
                                                case "Fajr":
                                                    settings.preNotificationFajr = 15
                                                    settings.notificationFajr = true
                                                case "Shurooq":
                                                    settings.preNotificationSunrise = 15
                                                    settings.notificationSunrise = true
                                                case "Dhuhr", "Dhuhr/Asr", "Jummuah":
                                                    settings.preNotificationDhuhr = 15
                                                    settings.notificationDhuhr = true
                                                case "Asr":
                                                    settings.preNotificationAsr = 15
                                                    settings.notificationAsr = true
                                                case "Maghrib", "Maghrib/Isha":
                                                    settings.preNotificationMaghrib = 15
                                                    settings.notificationMaghrib = true
                                                case "Isha":
                                                    settings.preNotificationIsha = 15
                                                    settings.notificationIsha = true
                                                default:
                                                    break
                                                }
                                            }) {
                                                Label("Prenotification", systemImage: "bell.fill")
                                            }
                                            
                                            Button(action: {
                                                settings.hapticFeedback()
                                                
                                                switch prayerTime.nameTransliteration {
                                                case "Fajr":
                                                    settings.preNotificationFajr = 0
                                                    settings.notificationFajr = true
                                                case "Shurooq":
                                                    settings.preNotificationSunrise = 0
                                                    settings.notificationSunrise = true
                                                case "Dhuhr", "Dhuhr/Asr", "Jummuah":
                                                    settings.preNotificationDhuhr = 0
                                                    settings.notificationDhuhr = true
                                                case "Asr":
                                                    settings.preNotificationAsr = 0
                                                    settings.notificationAsr = true
                                                case "Maghrib", "Maghrib/Isha":
                                                    settings.preNotificationMaghrib = 0
                                                    settings.notificationMaghrib = true
                                                case "Isha":
                                                    settings.preNotificationIsha = 0
                                                    settings.notificationIsha = true
                                                default:
                                                    break
                                                }
                                            }) {
                                                Label("Notification", systemImage: "bell")
                                            }
                                            
                                            Button(action: {
                                                settings.hapticFeedback()
                                                
                                                switch prayerTime.nameTransliteration {
                                                case "Fajr":
                                                    settings.preNotificationFajr = 0
                                                    settings.notificationFajr = false
                                                case "Shurooq":
                                                    settings.preNotificationSunrise = 0
                                                    settings.notificationSunrise = false
                                                case "Dhuhr", "Dhuhr/Asr", "Jummuah":
                                                    settings.preNotificationDhuhr = 0
                                                    settings.notificationDhuhr = false
                                                case "Asr":
                                                    settings.preNotificationAsr = 0
                                                    settings.notificationAsr = false
                                                case "Maghrib", "Maghrib/Isha":
                                                    settings.preNotificationMaghrib = 0
                                                    settings.notificationMaghrib = false
                                                case "Isha":
                                                    settings.preNotificationIsha = 0
                                                    settings.notificationIsha = false
                                                default:
                                                    break
                                                }
                                            }) {
                                                Label("No Notification", systemImage: "bell.slash")
                                            }
                                        }
                                        #endif
                                }
                                .padding(.vertical, 4)
                            }
                            
                            if let expandedPrayer = expandedPrayer, prayerTime == expandedPrayer {
                                if prayerTime.nameTransliteration != "Shurooq" {
                                    VStack(alignment: .leading) {
                                        if(prayerTime.rakah != "0") {
                                            Text("Prayer Rakahs: \(prayerTime.rakah)")
                                                .foregroundColor(.primary)
                                                .font(.body)
                                        }
                                        
                                        if(prayerTime.sunnahBefore != "0") {
                                            Text("Sunnah Rakahs Before: \(prayerTime.sunnahBefore)")
                                                .foregroundColor(.secondary)
                                                .font(.footnote)
                                        }
                                        
                                        if(prayerTime.sunnahAfter != "0") {
                                            Text("Sunnah Rakahs After: \(prayerTime.sunnahAfter)")
                                                .foregroundColor(.secondary)
                                                .font(.footnote)
                                        }
                                        
                                        if prayerTime.nameTransliteration == "Fajr" {
                                            Text("Prophet Muhammad (peace and blessings of Allah be upon him) said: “The time for Fajr prayer is from the appearance of dawn, as long as the sun has not yet risen” (Muslim 612).")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                                .padding(.top, 2)
                                        } else if prayerTime.nameTransliteration.contains("Dhuhr") {
                                            Text("Prophet Muhammad (peace and blessings of Allah be upon him) said: “The time for Dhuhr is when the sun has passed its zenith and a person’s shadow is equal in length to his height, until the time for Asr begins” (Muslim 612).")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                                .padding(.top, 2)
                                        } else if prayerTime.nameTransliteration == "Jummuah" {
                                            Text("Prophet Muhammad (peace and blessings of Allah be upon him) said: “The Friday prayer is obligatory upon every Muslim in the time of Dhuhr, except for a child, a woman, or an ill person” (Abu Dawood 1067).")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                                .padding(.top, 2)
                                        } else if prayerTime.nameTransliteration == "Asr" {
                                            Text("Prophet Muhammad (peace and blessings of Allah be upon him) said: “The time for Asr prayer lasts until the sun turns yellow” (Muslim 612).")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                                .padding(.top, 2)
                                        } else if prayerTime.nameTransliteration.contains("Maghrib") {
                                            Text("Prophet Muhammad (peace and blessings of Allah be upon him) said: “The time for Maghrib lasts until the twilight has faded” (Muslim 612).")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                                .padding(.top, 2)
                                        } else if prayerTime.nameTransliteration == "Isha" {
                                            Text("Prophet Muhammad (peace and blessings of Allah be upon him) said: “The time for Isha lasts until the middle of the night” (Muslim 612).")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                                .padding(.top, 2)
                                        }
                                    }
                                } else {
                                    VStack(alignment: .leading) {
                                        Text("Shurooq is not a prayer, but marks the end of Fajr.")
                                            .foregroundColor(.primary)
                                            .font(.footnote)
                                        
                                        Text("Prophet Muhammad (peace and blessings of Allah be upon him) said: “The time for Fajr prayer is from the appearance of dawn as long as the sun has not yet risen. When the sun begins to rise, stop praying, for it rises between the horns of Shaytan” (Muslim 612).")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                            .padding(.top, 2)
                                    }
                                }
                            }
                        }
                    }
                    .onChange(of: settings.travelingMode) { _ in
                        withAnimation {
                            fullPrayers = false
                        }
                    }
                } else {
                    let columns: [GridItem] = Array(
                        repeating: GridItem(.flexible(), spacing: 12),
                        count: (settings.changedDate
                                ? (fullPrayers ? dateFullPrayerTimes : datePrayerTimes)
                                : (fullPrayers ? fullPrayerTimes : prayerTimes)
                        ).count == 4 ? 2 : 3
                    )

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(
                            settings.changedDate
                            ? (fullPrayers ? dateFullPrayerTimes : datePrayerTimes)
                            : (fullPrayers ? fullPrayerTimes : prayerTimes)
                        ) { prayer in
                            VStack(alignment: .center) {
                                HStack {
                                    Image(systemName: prayer.image)
                                        .font(.subheadline)
                                        .foregroundColor(getPrayerColor(for: prayer))
                                        .padding(.trailing, -5)
                                    
                                    Text(prayer.nameTransliteration)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(getPrayerColor(for: prayer))
                                }
                                
                                Text(prayer.time, style: .time)
                                    .font(.subheadline)
                                    .foregroundColor(getPrayerColor(for: prayer))
                            }
                        }
                    }
                    .padding(.horizontal, -20)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                }
                
                if settings.travelingMode {
                    VStack {
                        #if !os(watchOS)
                        Text("Traveling mode is on. If you are traveling more than 48 mi, then you can pray Qasr, where you combine prayers. You can customize and learn more in settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        #endif
                        
                        Text(fullPrayers ? "View Qasr Prayers" : "View Full Prayers")
                            .font(.subheadline)
                            .foregroundColor(settings.accentColor.color)
                            .padding(.vertical, 8)
                            .onTapGesture {
                                settings.hapticFeedback()
                                withAnimation {
                                    fullPrayers.toggle()
                                }
                            }
                        
                        #if os(watchOS)
                        Text("Traveling mode is on. If you are traveling more than 48 mi, then you can pray Qasr, where you combine prayers. You can customize and learn more in settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        #endif
                    }
                }
                
                #if !os(watchOS)
                VStack {
                    DatePicker("Showing prayers for", selection: $settings.selectedDate.animation(.easeInOut), displayedComponents: .date)
                        .datePickerStyle(DefaultDatePickerStyle())
                        .padding(4)
                    
                    if !calendar.isDate(settings.selectedDate, inSameDayAs: Date()) {
                        Text("Show prayers for today")
                            .font(.subheadline)
                            .foregroundColor(settings.accentColor.color)
                            .padding(.vertical, 8)
                            .onTapGesture {
                                settings.hapticFeedback()
                                withAnimation {
                                    settings.selectedDate = Date()
                                }
                            }
                    }
                }
                #endif
            }
        }
    }
}
