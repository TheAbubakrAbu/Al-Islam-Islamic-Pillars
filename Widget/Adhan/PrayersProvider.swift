import SwiftUI
import WidgetKit

enum AdhanWidgetDateFormatting {
    static let hijriCalendar: Calendar = {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "ar")
        return calendar
    }()

    static let mediumHijriFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = hijriCalendar
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "en")
        return formatter
    }()

    static let fullHijriFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = hijriCalendar
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "en")
        return formatter
    }()

    static func hijriDate(for entry: PrayersEntry, style: DateFormatter.Style) -> String {
        let formatter = style == .full ? fullHijriFormatter : mediumHijriFormatter
        let now = Date()
        var referenceDate = now

        if entry.switchHijriDateAtMaghrib,
           let maghrib = entry.fullPrayers.first(where: { $0.nameTransliteration == "Maghrib" })?.time,
           now >= maghrib {
            referenceDate = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        }

        guard let offsetDate = hijriCalendar.date(byAdding: .day, value: entry.hijriOffset, to: referenceDate) else {
            return formatter.string(from: referenceDate)
        }

        return formatter.string(from: offsetDate)
    }
}

struct PrayersProvider: TimelineProvider {
    private let store   = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)
    private let settings = Settings.shared

    func placeholder(in context: Context) -> PrayersEntry { makeEntry() }

    func getSnapshot(in ctx: Context, completion: @escaping (PrayersEntry)->Void) {
        completion(makeEntry())
    }

    func getTimeline(in ctx: Context, completion: @escaping (Timeline<PrayersEntry>)->Void) {
        let entry = makeEntry()
        let refresh = entry.nextPrayer?.time ?? Date().addingTimeInterval(30 * 60)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func makeEntry() -> PrayersEntry {
        if let data = store?.data(forKey: "prayersData"),
           let prayers = try? Settings.decoder.decode(Prayers.self, from: data) {
            settings.prayers = prayers
        }

        if let locData = store?.data(forKey: "currentLocation"),
           let loc = try? Settings.decoder.decode(Location.self, from: locData) {
            settings.currentLocation = loc
        }

        settings.accentColor = AccentColor(rawValue: store?.string(forKey: "accentColor") ?? AppIdentifiers.mainColorString) ?? AppIdentifiers.mainColor
        settings.travelingMode = store?.bool(forKey: "travelingMode") ?? false
        settings.hanafiMadhab = store?.bool(forKey: "hanafiMadhab") ?? false
        settings.prayerCalculation = store?.string(forKey: "prayerCalculation") ?? "Muslim World League"
        settings.hijriOffset = store?.integer(forKey: "hijriOffset") ?? 0
        settings.switchHijriDateAtMaghrib = store?.bool(forKey: "switchHijriDateAtMaghrib") ?? false

        settings.fetchPrayerTimes()

        guard let obj = settings.prayers else {
            return emptyEntry(accent: settings.accentColor)
        }

        return PrayersEntry(
            date:                       Date(),
            accentColor:                settings.accentColor,
            currentCity:                settings.currentLocation?.city ?? "",
            prayers:                    obj.prayers,
            fullPrayers:                obj.fullPrayers,
            currentPrayer:              settings.currentPrayer,
            nextPrayer:                 settings.nextPrayer,
            hijriOffset:                settings.hijriOffset,
            switchHijriDateAtMaghrib:   settings.switchHijriDateAtMaghrib
        )
    }

    private func emptyEntry(accent: AccentColor) -> PrayersEntry {
        .init(date: Date(),
              accentColor: accent,
              currentCity: "",
              prayers: [], fullPrayers: [],
              currentPrayer: nil, nextPrayer: nil,
              hijriOffset: 0,
              switchHijriDateAtMaghrib: false)
    }
}

struct PrayersEntry: TimelineEntry {
    let date: Date
    let accentColor: AccentColor
    let currentCity: String
    let prayers: [Prayer]
    let fullPrayers: [Prayer]
    let currentPrayer: Prayer?
    let nextPrayer: Prayer?
    let hijriOffset: Int
    let switchHijriDateAtMaghrib: Bool
}
