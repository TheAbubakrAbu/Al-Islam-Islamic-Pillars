import SwiftUI
import WidgetKit

struct PrayersProvider: TimelineProvider {
    var settings = Settings.shared

    func placeholder(in context: Context) -> PrayersEntry {
        return createPrayersEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayersEntry) -> Void) {
        let entry = createPrayersEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayersEntry>) -> ()) {
        var entries: [PrayersEntry] = []
        let entry = createPrayersEntry()
        entries.append(entry)
        
        let timeline = Timeline(entries: entries, policy: .after(entries.last?.date ?? Date()))
        completion(timeline)
    }

    private func createPrayersEntry() -> PrayersEntry {
        let appGroupUserDefaults = UserDefaults(suiteName: "group.com.IslamicPillars.AppGroup")

        if let data = appGroupUserDefaults?.data(forKey: "prayersData") {
            let decoder = JSONDecoder()
            if let prayers = try? decoder.decode(Prayers.self, from: data) {
                settings.prayers = prayers
            }
        }
        
        let accentColor: AccentColor = AccentColor(rawValue: appGroupUserDefaults?.string(forKey: "accentColor") ?? "green") ?? .green
        if appGroupUserDefaults?.object(forKey: "accentColor") == nil {
            appGroupUserDefaults?.set("green", forKey: "accentColor")
        }
        
        var currentLocation: Location? = nil
        if let locationData = appGroupUserDefaults?.data(forKey: "currentLocation") {
            let decoder = JSONDecoder()
            currentLocation = try? decoder.decode(Location.self, from: locationData)
        }
        
        let travelingMode: Bool = appGroupUserDefaults?.bool(forKey: "travelingMode") ?? false
        if appGroupUserDefaults?.object(forKey: "travelingMode") == nil {
            appGroupUserDefaults?.set(false, forKey: "travelingMode")
        }

        let hanafiMadhab: Bool = appGroupUserDefaults?.bool(forKey: "hanafiMadhab") ?? false
        if appGroupUserDefaults?.object(forKey: "hanafiMadhab") == nil {
            appGroupUserDefaults?.set(false, forKey: "hanafiMadhab")
        }

        let prayerCalculation = appGroupUserDefaults?.string(forKey: "prayerCalculation") ?? "Muslim World League"
        if appGroupUserDefaults?.object(forKey: "prayerCalculation") == nil {
            appGroupUserDefaults?.set("Muslim World League", forKey: "prayerCalculation")
        }

        let hijriOffset: Int = appGroupUserDefaults?.integer(forKey: "hijriOffset") ?? 0
        if appGroupUserDefaults?.object(forKey: "hijriOffset") == nil {
            appGroupUserDefaults?.set(0, forKey: "hijriOffset")
        }
        
        if let currentLoc = currentLocation {
            settings.currentLocation = currentLoc
        }
        settings.travelingMode = travelingMode
        settings.hanafiMadhab = hanafiMadhab
        settings.prayerCalculation = prayerCalculation
        
        settings.fetchPrayerTimes()
        
        if let prayersObject = settings.prayers {
            let prayers = prayersObject.prayers
            let current = settings.currentPrayer
            let next = settings.nextPrayer
            
            let currentCity = currentLocation?.city ?? ""
            
            return PrayersEntry(
                date: Date(),
                accentColor: accentColor,
                currentCity: currentCity,
                prayers: prayers,
                currentPrayer: current,
                nextPrayer: next,
                hijriOffset: hijriOffset
            )
        }
        
        return PrayersEntry(
            date: Date(),
            accentColor: .green,
            currentCity: "",
            prayers: [],
            currentPrayer: nil,
            nextPrayer: nil,
            hijriOffset: 0
        )
    }
}

struct PrayersEntry: TimelineEntry {
    let date: Date
    let accentColor: AccentColor
    let currentCity: String
    
    let prayers: [Prayer]
    let currentPrayer: Prayer?
    let nextPrayer: Prayer?
    
    let hijriOffset: Int
}
