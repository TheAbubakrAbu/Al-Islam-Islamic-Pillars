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
        
        var currentLocation: Location? = nil
        if let locationData = appGroupUserDefaults?.data(forKey: "currentLocation") {
            let decoder = JSONDecoder()
            currentLocation = try? decoder.decode(Location.self, from: locationData)
        }
        
        let accentColor: AccentColor = AccentColor(rawValue: appGroupUserDefaults?.string(forKey: "accentColor") ?? "green") ?? .green
        let travelingMode: Bool = appGroupUserDefaults?.bool(forKey: "travelingMode") ?? false
        let hanafiMadhab: Bool = appGroupUserDefaults?.bool(forKey: "hanafiMadhab") ?? false
        let prayerCalculation = appGroupUserDefaults?.string(forKey: "prayerCalculation") ?? "Muslim World League"
        let hijriOffset: Int = appGroupUserDefaults?.integer(forKey: "hijriOffset") ?? 0
        
        if let currentLoc = currentLocation {
            settings.currentLocation = currentLoc
        }
        
        settings.travelingMode = travelingMode
        settings.hanafiMadhab = hanafiMadhab
        settings.prayerCalculation = prayerCalculation
        
        settings.fetchPrayerTimes()
        
        if let prayersObject = settings.prayers {
            let prayers = prayersObject.prayers
            let fullPrayers = prayersObject.fullPrayers
            let current = settings.currentPrayer
            let next = settings.nextPrayer
            
            let currentCity = currentLocation?.city ?? ""
            
            return PrayersEntry(
                date: Date(),
                accentColor: accentColor,
                currentCity: currentCity,
                prayers: prayers,
                fullPrayers: fullPrayers,
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
            fullPrayers: [],
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
    let fullPrayers: [Prayer]
    let currentPrayer: Prayer?
    let nextPrayer: Prayer?
    
    let hijriOffset: Int
}
