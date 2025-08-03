import SwiftUI
import WidgetKit

struct PrayersProvider: TimelineProvider {
    private let store   = UserDefaults(suiteName: "group.com.IslamicPillars.AppGroup")
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

        settings.accentColor      = AccentColor(rawValue: store?.string(forKey: "accentColor") ?? "") ?? .green
        settings.travelingMode    = store?.bool(forKey: "travelingMode") ?? false
        settings.hanafiMadhab     = store?.bool(forKey: "hanafiMadhab") ?? false
        settings.prayerCalculation = store?.string(forKey: "prayerCalculation") ?? "Muslim World League"
        settings.hijriOffset       = store?.integer(forKey: "hijriOffset") ?? 0

        settings.fetchPrayerTimes()

        guard let obj = settings.prayers else {
            return emptyEntry(accent: settings.accentColor)
        }

        return PrayersEntry(
            date:           Date(),
            accentColor:    settings.accentColor,
            currentCity:    settings.currentLocation?.city ?? "",
            prayers:        obj.prayers,
            fullPrayers:    obj.fullPrayers,
            currentPrayer:  settings.currentPrayer,
            nextPrayer:     settings.nextPrayer,
            hijriOffset:    settings.hijriOffset
        )
    }

    private func emptyEntry(accent: AccentColor) -> PrayersEntry {
        .init(date: Date(),
              accentColor: accent,
              currentCity: "",
              prayers: [], fullPrayers: [],
              currentPrayer: nil, nextPrayer: nil,
              hijriOffset: 0)
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
}
