import SwiftUI
import os
import Adhan
import CoreLocation
import UserNotifications
import WidgetKit

let logger = Logger(subsystem: "com.Quran.Elmallah.Islamic-Pillars", category: "Al-Islam")

final class Settings: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = Settings()
    private let appGroupUserDefaults = UserDefaults(suiteName: "group.com.IslamicPillars.AppGroup")
    
    static let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .millisecondsSince1970
        return enc
    }()

    static let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .millisecondsSince1970
        return dec
    }()
    
    private lazy var locationManager: CLLocationManager = {
        let lm = CLLocationManager()
        lm.delegate = self
        lm.desiredAccuracy = kCLLocationAccuracyHundredMeters
        lm.distanceFilter = 500
        return lm
    }()
    let geocoder = CLGeocoder()
    
    private let kaabaCoordinates = Coordinates(latitude: 21.4225, longitude: 39.8262)
    @Published var qiblaDirection: Double = 0
    
    private override init() {
        self.accentColor = AccentColor(rawValue: appGroupUserDefaults?.string(forKey: "accentColor") ?? "green") ?? .green
        self.prayersData = appGroupUserDefaults?.data(forKey: "prayersData") ?? Data()
        self.travelingMode = appGroupUserDefaults?.bool(forKey: "travelingMode") ?? false
        self.hanafiMadhab = appGroupUserDefaults?.bool(forKey: "hanafiMadhab") ?? false
        self.prayerCalculation = appGroupUserDefaults?.string(forKey: "prayerCalculation") ?? "Muslim World League"
        self.hijriOffset = appGroupUserDefaults?.integer(forKey: "hijriOffset") ?? 0
        
        if let locationData = appGroupUserDefaults?.data(forKey: "currentLocation") {
            do {
                let location = try Self.decoder.decode(Location.self, from: locationData)
                currentLocation = location
            } catch {
                logger.debug("Failed to decode location: \(error)")
            }
        }
        
        if let homeLocationData = appGroupUserDefaults?.data(forKey: "homeLocationData") {
            do {
                let homeLocation = try Self.decoder.decode(Location.self, from: homeLocationData)
                self.homeLocation = homeLocation
            } catch {
                logger.debug("Failed to decode home location: \(error)")
            }
        }
        
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        requestLocationAuthorization()
        
        if self.reciter.starts(with: "ar") {
            if let match = reciters.first(where: { $0.ayahIdentifier == self.reciter }) {
                self.reciter = match.name
            } else {
                self.reciter = "Muhammad Al-Minshawi (Murattal)"
            }
        }
    }
    
    private static let oneMile: CLLocationDistance = 1609.34   // m
    private static let minAcc: CLLocationAccuracy = 100        // m
    private static let maxAge: TimeInterval = 60               // s
    private static let headingΔ: Double = 1.0                  // deg – ignore jitter
    
    var acceptStaleOnce = true
    
    /// MAIN LOCATION CALLBACK
    func locationManager(_ mgr: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last, loc.horizontalAccuracy > 0, loc.horizontalAccuracy <= Self.minAcc else { return }
        if abs(loc.timestamp.timeIntervalSinceNow) > Self.maxAge, !acceptStaleOnce { return }
        acceptStaleOnce = false
        if let cur = currentLocation {
            let prev = CLLocation(latitude: cur.latitude, longitude: cur.longitude)
            guard loc.distance(from: prev) >= Self.oneMile else { return }
        }
        Task { @MainActor in
            await updateCity(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
            fetchPrayerTimes(force: true)
        }
    }

    /// COMPASS / QIBLA
    func locationManager(_ mgr: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0, let cur = currentLocation
        else { return }

        let target = Qibla(coordinates: Coordinates(latitude: cur.latitude, longitude: cur.longitude)).direction
        var delta = target - newHeading.trueHeading
        delta = delta.truncatingRemainder(dividingBy: 360)
        if delta < 0 { delta += 360 }

        if abs(delta - qiblaDirection) >= Self.headingΔ {
            qiblaDirection = delta
        }
    }

    /// AUTHORIZATION CHANGES
    func locationManager(_ mgr: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            showLocationAlert = false
            mgr.requestLocation()
            
            if CLLocationManager.headingAvailable() {
                mgr.startUpdatingHeading()
            }
            #if !os(watchOS)
            mgr.startMonitoringSignificantLocationChanges()
            #else
            mgr.startUpdatingLocation()
            #endif

        case .denied where !locationNeverAskAgain:
            showLocationAlert = true

        case .restricted, .notDetermined:
            break

        default: break
        }
    }

    /// ERROR HANDLER
    func locationManager(_ mgr: CLLocationManager, didFailWithError err: Error) {
        logger.error("CLLocationManager failed: \(err.localizedDescription)")
    }

    /// PERMISSION REQUEST
    func requestLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager(_ : locationManager, didChangeAuthorization: locationManager.authorizationStatus)
        default:
            break
        }
    }
    
    actor GeocodeActor {
        private let gc = CLGeocoder()
        func placemark(for location: CLLocation) async throws -> CLPlacemark? {
            try await gc.reverseGeocodeLocation(location).first
        }
    }
    
    /// Remember the most recent geocode to short‑circuit duplicates
    private var cachedPlacemark: (coord: CLLocationCoordinate2D, city: String)?
    private let geocodeActor = GeocodeActor()
    
    /// Reverse‑geocode utilities
    @MainActor
    func updateCity(latitude: Double, longitude: Double, attempt: Int = 0, maxAttempts: Int = 3) async {
        let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        if let cached = cachedPlacemark,
           CLLocation(latitude: cached.coord.latitude, longitude: cached.coord.longitude)
               .distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude)) < 100,
           cached.city == currentLocation?.city {
            return
        }

        let location = CLLocation(latitude: latitude, longitude: longitude)

        do {
            guard let placemark = try await geocodeActor.placemark(for: location) else {
                throw CLError(.geocodeFoundNoResult)
            }

            let newCity: String = {
                if let city = placemark.locality {
                    let region = placemark.administrativeArea ?? placemark.country ?? ""
                    return "\(city), \(region)"
                } else {
                    return "(\(latitude.stringRepresentation), \(longitude.stringRepresentation))"
                }
            }()

            if newCity != currentLocation?.city {
                withAnimation {
                    currentLocation = Location(city: newCity, latitude: latitude, longitude: longitude)
                }
                WidgetCenter.shared.reloadAllTimelines()
            }

            cachedPlacemark = (coord, newCity)

        } catch {
            logger.warning("Geocode attempt \(attempt+1) failed: \(error.localizedDescription)")
            guard attempt + 1 < maxAttempts else {
                // Fall‑back to raw coordinates
                currentLocation = Location(city: "\(latitude.stringRepresentation), \(longitude.stringRepresentation)", latitude: latitude, longitude: longitude)
                return
            }

            // Exponential back‑off:  2s → 4s → 8s
            let delay = UInt64(pow(2.0, Double(attempt)) * 2_000_000_000) // ns
            try? await Task.sleep(nanoseconds: delay)
            await updateCity(latitude: latitude, longitude: longitude, attempt: attempt + 1, maxAttempts: maxAttempts)
        }
    }
    
    private static let travelThresholdM: CLLocationDistance = 48 * oneMile   // ≈ 77 112 m

    func checkIfTraveling() {
        guard travelAutomatic, let here = currentLocation, let home = homeLocation, here.latitude != 1000, here.longitude != 1000
        else { return }

        let distance = CLLocation(latitude: here.latitude, longitude: here.longitude)
                       .distance(from: CLLocation(latitude: home.latitude, longitude: home.longitude))

        let isAway = distance >= Self.travelThresholdM
        guard isAway != travelingMode else { return }

        withAnimation { travelingMode = isAway }
        travelTurnOnAutomatic = isAway
        travelTurnOffAutomatic = !isAway
        logger.debug("Traveling mode \(isAway ? "enabled" : "disabled") – distance \(Int(distance)) m")

        #if !os(watchOS)
        scheduleTravelNotification(turnedOn: !isAway, city: here.city)
        #endif
    }

    #if !os(watchOS)
    private func scheduleTravelNotification(turnedOn: Bool, city: String) {
        let center  = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Al‑Islam"
        content.body  = "Traveling mode automatically turned \(turnedOn ? "on" : "off") at \(city)"
        content.sound = .default

        let trigger  = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger))
    }
    #endif
    
    @inline(__always)
    func arabicNumberString<S: StringProtocol>(from ascii: S) -> String {
        var out = String();  out.reserveCapacity(ascii.count)
        for ch in ascii {
            if let d = ch.asciiDigitValue {
                out.unicodeScalars.append(UnicodeScalar(0x0660 + d)!)   // ٠…٩
            } else {
                out.append(ch)
            }
        }
        return out
    }

    func formatArabicDate(_ date: Date) -> String {
        arabicNumberString(from: DateFormatter.timeAR.string(from: date))
    }

    func formatDate(_ date: Date) -> String {
        DateFormatter.timeEN.string(from: date)
    }

    private static let hijriCalendarAR: Calendar = {
        var c = Calendar(identifier: .islamicUmmAlQura)
        c.locale = Locale(identifier: "ar")
        return c
    }()

    static let hijriFormatterAR: DateFormatter = {
        let f = DateFormatter()
        f.calendar = hijriCalendarAR
        f.locale   = Locale(identifier: "ar")
        f.dateFormat = "d MMMM، yyyy"
        return f
    }()

    static let hijriFormatterEN: DateFormatter = {
        let f = DateFormatter()
        f.calendar = hijriCalendarAR
        f.locale   = Locale(identifier: "en")
        f.dateStyle = .long
        return f
    }()
    
    func updateDates() {
        let now = Date()
        if let h = hijriDate, h.date.isSameDay(as: now) {
            return
        }

        let base = Self.hijriCalendarAR.date(byAdding: .day, value: hijriOffset, to: now) ?? now
        let arabic  = arabicNumberString(from: Self.hijriFormatterAR.string(from: base)) + " هـ"
        let english = Self.hijriFormatterEN.string(from: base)

        withAnimation {
            hijriDate = HijriDate(english: english, arabic: arabic, date: now)
        }
    }
    
    private static let gregorian: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = .current
        return c
    }()

    private static let calcParams: [String: CalculationParameters] = {
        let map: [(String, CalculationMethod)] = [
            ("Muslim World League", .muslimWorldLeague),
            ("Moonsight Committee", .moonsightingCommittee),
            ("Umm Al-Qura",         .ummAlQura),
            ("Egypt",               .egyptian),
            ("Dubai",               .dubai),
            ("Kuwait",              .kuwait),
            ("Qatar",               .qatar),
            ("Turkey",              .turkey),
            ("Tehran",              .tehran),
            ("Karachi",             .karachi),
            ("Singapore",           .singapore),
            ("North America",       .northAmerica)
        ]
        return Dictionary(uniqueKeysWithValues: map.map { ($0.0, $0.1.params) })
    }()
    
    private struct Proto {
        let ar, tr, en, img, rakah, sunnahB, sunnahA: String
    }

    private static let prayerProtos: [String: Proto] = [
        "Fajr":      .init(ar:"الفَجْر",  tr:"Fajr",   en:"Dawn",     img:"sunrise",       rakah:"2", sunnahB:"2", sunnahA:"0"),
        "Sunrise":   .init(ar:"الشُرُوق", tr:"Shurooq",en:"Sunrise",  img:"sunrise.fill",  rakah:"0", sunnahB:"0", sunnahA:"0"),
        "Dhuhr":     .init(ar:"الظُهْر",  tr:"Dhuhr",  en:"Noon",     img:"sun.max",       rakah:"4", sunnahB:"2 and 2", sunnahA:"2"),
        "Asr":       .init(ar:"العَصْر",  tr:"Asr",    en:"Afternoon",img:"sun.min",       rakah:"4", sunnahB:"0", sunnahA:"0"),
        "Maghrib":   .init(ar:"المَغْرِب",tr:"Maghrib",en:"Sunset",   img:"sunset",        rakah:"3", sunnahB:"0", sunnahA:"2"),
        "Isha":      .init(ar:"العِشَاء", tr:"Isha",   en:"Night",    img:"moon",          rakah:"4", sunnahB:"0", sunnahA:"2"),
        // grouped (travel) variants
        "Dh/As":     .init(ar:"الظُهْر وَالْعَصْر", tr:"Dhuhr/Asr",   en:"Daytime",   img:"sun.max", rakah:"2 and 2", sunnahB:"0", sunnahA:"0"),
        "Mg/Ij":     .init(ar:"المَغْرِب وَالْعِشَاء", tr:"Maghrib/Isha", en:"Nighttime", img:"sunset", rakah:"3 and 2",sunnahB:"0", sunnahA:"0")
    ]
    
    @inline(__always)
    private func prayer(from key: String, time: Date) -> Prayer {
        let p = Self.prayerProtos[key]!
        return Prayer(
            nameArabic: p.ar,
            nameTransliteration: p.tr,
            nameEnglish: p.en,
            time: time,
            image: p.img,
            rakah: p.rakah,
            sunnahBefore: p.sunnahB,
            sunnahAfter: p.sunnahA
        )
    }
    
    /// Ultra‑fast prayer generator. Returns `nil` if location is not valid.
    func getPrayerTimes(for date: Date, fullPrayers: Bool = false) -> [Prayer]? {
        guard let here = currentLocation, here.latitude != 1000, here.longitude != 1000 else { return nil }

        var params = Self.calcParams[prayerCalculation] ?? Self.calcParams["Muslim World League"]!
        params.madhab = hanafiMadhab ? Madhab.hanafi : Madhab.shafi

        let comps = Self.gregorian.dateComponents([.year, .month, .day], from: date)

        guard let raw = PrayerTimes(
                coordinates: Coordinates(latitude: here.latitude, longitude: here.longitude),
                date: comps,
                calculationParameters: params
        )
        else { return nil }

        @inline(__always) func off(_ d: Date, by m: Int) -> Date {
            d.addingTimeInterval(Double(m) * 60)
        }

        let fajr     = off(raw.fajr,     by: offsetFajr)
        let sunrise  = off(raw.sunrise,  by: offsetSunrise)
        let dhuhr    = off(raw.dhuhr,    by: offsetDhuhr)
        let asr      = off(raw.asr,      by: offsetAsr)
        let maghrib  = off(raw.maghrib,  by: offsetMaghrib)
        let isha     = off(raw.isha,     by: offsetIsha)
        let dhAsr    = off(raw.dhuhr,    by: offsetDhurhAsr)
        let mgIsha   = off(raw.maghrib,  by: offsetMaghribIsha)

        let isFriday = Self.gregorian.component(.weekday, from: date) == 6

        if fullPrayers || !travelingMode {
            var list: [Prayer] = [
                prayer(from: "Fajr",    time: fajr),
                prayer(from: "Sunrise", time: sunrise)
            ]

            // Dhuhr / Jumuah switch
            if isFriday {
                list.append(
                    Prayer(nameArabic: "الجُمُعَة",
                           nameTransliteration: "Jummuah",
                           nameEnglish: "Friday",
                           time: dhuhr,
                           image: "sun.max.fill",
                           rakah: "2",
                           sunnahBefore: "0",
                           sunnahAfter: "2 and 2")
                )
            } else {
                list.append(prayer(from: "Dhuhr", time: dhuhr))
            }

            list += [
                prayer(from: "Asr",     time: asr),
                prayer(from: "Maghrib", time: maghrib),
                prayer(from: "Isha",    time: isha)
            ]
            return list
        } else {
            return [
                prayer(from: "Fajr",    time: fajr),
                prayer(from: "Sunrise", time: sunrise),
                prayer(from: "Dh/As",   time: dhAsr),
                prayer(from: "Mg/Ij",   time: mgIsha)
            ]
        }
    }

    func fetchPrayerTimes(force: Bool = false, notification: Bool = false, calledFrom: StaticString = #function, completion: (() -> Void)? = nil) {
        updateDates()

        guard let loc = currentLocation, loc.latitude  != 1000, loc.longitude != 1000 else {
            logger.debug("No valid location – skip refresh")
            completion?()
            return
        }

        if force || loc.city.contains("(") {
            Task { @MainActor in
                await updateCity(latitude: loc.latitude, longitude: loc.longitude)
            }
        }

        if travelAutomatic, homeLocation != nil {
            checkIfTraveling()
        }

        // Decide if we need fresh prayers
        let today      = Date()
        let stored     = prayers
        let staleCity  = stored?.city != currentLocation?.city
        let staleDate  = !(stored?.day.isSameDay(as: today) ?? false)
        let emptyList  = stored?.prayers.isEmpty ?? true
        let needsFetch = force || stored == nil || staleCity || staleDate || emptyList

        if needsFetch {
            logger.debug("Fetching prayer times – caller: \(calledFrom)")

            let todayPrayers  = getPrayerTimes(for: today) ?? []
            let fullPrayers   = getPrayerTimes(for: today, fullPrayers: true) ?? []

            prayers = Prayers(
                day: today,
                city: currentLocation!.city,
                prayers: todayPrayers,
                fullPrayers: fullPrayers,
                setNotification: false
            )

            schedulePrayerTimeNotifications()
            printAllScheduledNotifications()
            WidgetCenter.shared.reloadAllTimelines()
        } else if notification && !(stored?.setNotification ?? false) {
            schedulePrayerTimeNotifications()
            printAllScheduledNotifications()
            WidgetCenter.shared.reloadAllTimelines()
        }

        updateCurrentAndNextPrayer()
        completion?()
    }
    
    private func updateCurrentAndNextPrayer() {
        guard let p = prayers?.prayers, !p.isEmpty else {
            logger.debug("No prayer list to compute current/next")
            return
        }

        let now = Date()

        let nextIdx = p.firstIndex { $0.time > now }

        if let i = nextIdx {
            nextPrayer = p[i]
            currentPrayer = i == 0 ? p.last : p[i-1]
        } else {
            // past last prayer – peek at tomorrow for “next”
            currentPrayer = p.last
            if let tmr = Calendar.current.date(byAdding: .day, value: 1, to: now),
               let firstTomorrow = getPrayerTimes(for: tmr)?.first {
                nextPrayer = firstTomorrow
            } else {
                nextPrayer = nil
            }
        }
    }
    
    @MainActor
    func requestNotificationAuthorization() async -> Bool {
        #if os(watchOS)
        return true
        #else
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus

        switch status {
        case .authorized:
            showNotificationAlert = false
            return true

        case .denied:
            showNotificationAlert = !notificationNeverAskAgain
            logger.debug("Notification permission denied")
            return false

        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                showNotificationAlert = !granted && !notificationNeverAskAgain
                if granted { fetchPrayerTimes(notification: true) }
                return granted
            } catch {
                logger.error("Notification request failed: \(error.localizedDescription)")
                showNotificationAlert = !notificationNeverAskAgain
                return false
            }

        default:
            return false
        }
        #endif
    }
    
    func requestNotificationAuthorization(completion: (() -> Void)? = nil) {
        Task { @MainActor in
            _ = await requestNotificationAuthorization()
            completion?()
        }
    }
    
    func printAllScheduledNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { (requests) in
            for request in requests {
                logger.debug("\(request.content.body)")
            }
        }
    }
    
    private struct NotifPrefs {
        let enabled: ReferenceWritableKeyPath<Settings, Bool>
        let preMinutes: ReferenceWritableKeyPath<Settings, Int>
        let nagging: ReferenceWritableKeyPath<Settings, Bool>
    }

    /// Static lookup table
    private static let notifTable: [String: NotifPrefs] = [
        "Fajr":          .init(enabled: \.notificationFajr,  preMinutes: \.preNotificationFajr,  nagging: \.naggingFajr),
        "Shurooq":       .init(enabled: \.notificationSunrise, preMinutes: \.preNotificationSunrise, nagging: \.naggingSunrise),
        "Dhuhr":         .init(enabled: \.notificationDhuhr, preMinutes: \.preNotificationDhuhr, nagging: \.naggingDhuhr),
        "Dhuhr/Asr":     .init(enabled: \.notificationDhuhr, preMinutes: \.preNotificationDhuhr, nagging: \.naggingDhuhr),
        "Jummuah":       .init(enabled: \.notificationDhuhr, preMinutes: \.preNotificationDhuhr, nagging: \.naggingDhuhr),
        "Asr":           .init(enabled: \.notificationAsr,   preMinutes: \.preNotificationAsr,   nagging: \.naggingAsr),
        "Maghrib":       .init(enabled: \.notificationMaghrib, preMinutes: \.preNotificationMaghrib, nagging: \.naggingMaghrib),
        "Maghrib/Isha":  .init(enabled: \.notificationMaghrib, preMinutes: \.preNotificationMaghrib, nagging: \.naggingMaghrib),
        "Isha":          .init(enabled: \.notificationIsha,  preMinutes: \.preNotificationIsha,  nagging: \.naggingIsha)
    ]

    /// Pre‑computes the full list of minutes‑before offsets for a prayer.
    private func offsets(for prefs: NotifPrefs) -> [Int] {
        var result: [Int] = []

        // “at time” alert
        if self[keyPath: prefs.enabled] { result.append(0) }

        // user‑defined single offset
        let minutes = self[keyPath: prefs.preMinutes]
        if minutes > 0 { result.append(minutes) }

        // nagging offsets (if globally on *and* per‑prayer nagging on)
        if naggingMode && self[keyPath: prefs.nagging] {
            result += naggingCascade(start: naggingStartOffset)
        }
        return result
    }

    /// Generates exponential‑type cascade: 30,15,10,5 (by default)
    private func naggingCascade(start: Int) -> [Int] {
        guard start > 0 else { return [] }
        var m = start
        var out: [Int] = []
        while m > 15 { out.append(m); m -= 15 }
        if m >= 5  { out.append(m) }
        out += [10,5].filter { $0 < start }
        return out
    }

    private func scheduleRefreshNag(
        inDays offset: Int = 2,
        hour: Int = 12,
        minute: Int = 0,
        using center: UNUserNotificationCenter = .current()
    ) {
        guard let day = Calendar.current.date(byAdding: .day, value: offset, to: Date()) else { return }

        var comps = Calendar.current.dateComponents([.year, .month, .day], from: day)
        comps.hour = hour
        comps.minute = minute

        guard (Calendar.current.date(from: comps) ?? Date.distantPast) > Date() else { return }

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = "Al-Islam"
        content.body  = "Please open the app to refresh today’s prayer times and notifications."
        content.sound = .default

        // Unique per-day id so we don’t collide across days
        let id = String(format: "RefreshReminder-%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)

        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(req) { error in
            if let error { logger.debug("Refresh reminder add failed: \(error.localizedDescription)") }
        }
    }

    func schedulePrayerTimeNotifications() {
        #if os(watchOS)
        return
        #else
        guard let city = currentLocation?.city, let prayerObj = prayers
        else { return }

        logger.debug("Scheduling prayer time notifications")
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        if dateNotifications {
            for event in specialEvents {
                scheduleNotification(for: event)
            }
        }

        for prayer in prayerObj.prayers {
            guard let prefs = Self.notifTable[prayer.nameTransliteration] else { continue }

            for minutes in offsets(for: prefs) {
                scheduleNotification(
                    for: prayer,
                    preNotificationTime: minutes == 0 ? nil : minutes,
                    city: city
                )
            }
        }
        
        // Schedule for the next 3 days
        for dayOffset in 1..<4 {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: prayerObj.day) ?? Date()
            guard let list = getPrayerTimes(for: date) else { continue }

            for prayer in list {
                guard let prefs = Self.notifTable[prayer.nameTransliteration] else { continue }

                for minutes in offsets(for: prefs) {
                    scheduleNotification(
                        for: prayer,
                        preNotificationTime: minutes == 0 ? nil : minutes,
                        city: city
                    )
                }
            }
        }

        scheduleRefreshNag(inDays: 2, using: center)
        scheduleRefreshNag(inDays: 3, using: center)
        
        prayers?.setNotification = true
        #endif
    }
    
    private func buildBody(prayer: Prayer, minutesBefore: Int?, city: String) -> String {
        let englishPart: String = {
            switch prayer.nameTransliteration {
            case "Shurooq":
                return " (end of Fajr)"
            case "Jummuah":
                return " (Friday)"
            default:
                return ""
            }
        }()

        if let m = minutesBefore {
            // “n m until …”
            return "\(m)m until \(prayer.nameTransliteration)\(englishPart) in \(city)"
                 + (travelingMode ? " (traveling)" : "")
                 + " [\(formatDate(prayer.time))]"
        } else if prayer.nameTransliteration == "Fajr",
                  let list = prayers?.prayers, list.count > 1 {
            // Special Fajr “ends at …” text
            return "Time for \(prayer.nameTransliteration)\(englishPart)"
                 + " at \(formatDate(prayer.time)) in \(city)"
                 + (travelingMode ? " (traveling)" : "")
                 + " [ends at \(formatDate(list[1].time))]"
        } else {
            return "Time for \(prayer.nameTransliteration)\(englishPart)"
                 + " at \(formatDate(prayer.time)) in \(city)"
                 + (travelingMode ? " (traveling)" : "")
        }
    }

    func scheduleNotification(for prayer: Prayer, preNotificationTime minutes: Int?, city: String, using center: UNUserNotificationCenter = .current()) {
        let triggerTime: Date = {
            if let m = minutes, m != 0 {
                return Calendar.current.date(byAdding: .minute, value: -m, to: prayer.time) ?? prayer.time
            }
            return prayer.time
        }()

        guard triggerTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Al‑Islam"
        content.body = buildBody(prayer: prayer, minutesBefore: minutes, city: city)
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let id = "\(prayer.nameTransliteration)-\(minutes ?? 0)-\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
        let req  = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(req) { error in
            if let error { logger.debug("Notification add failed: \(error.localizedDescription)") }
        }
    }
    
    func scheduleNotification(for event: (String, DateComponents, String, String)) {
        let (titleText, hijriComps, eventSubTitle, _) = event
        
        if let hijriDate = hijriCalendar.date(from: hijriComps) {
            let gregorianCalendar = Calendar(identifier: .gregorian)
            var gregorianComps = gregorianCalendar.dateComponents([.year, .month, .day], from: hijriDate)
            gregorianComps.hour = 9
            gregorianComps.minute = 0
            
            guard
                let finalDate = gregorianCalendar.date(from: gregorianComps),
                finalDate > Date()
            else {
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Al-Islam"
            content.body = "\(titleText) (\(eventSubTitle))"
            content.sound = .default
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: gregorianComps, repeats: false)
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    logger.debug("Failed to schedule special event notification: \(error)")
                }
            }
        }
    }
    
    func hapticFeedback() {
        #if os(iOS)
        if hapticOn { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        #endif
        
        #if os(watchOS)
        if hapticOn { WKInterfaceDevice.current().play(.click) }
        #endif
    }
    
    @AppStorage("hijriDate") private var hijriDateData: String?
    var hijriDate: HijriDate? {
        get {
            guard let hijriDateData = hijriDateData,
                  let data = hijriDateData.data(using: .utf8) else {
                return nil
            }
            return try? Self.decoder.decode(HijriDate.self, from: data)
        }
        set {
            if let newValue = newValue {
                let encoded = try? Self.encoder.encode(newValue)
                hijriDateData = encoded.flatMap { String(data: $0, encoding: .utf8) }
            } else {
                hijriDateData = nil
            }
        }
    }
    
    @Published var prayersData: Data {
        didSet {
            if !prayersData.isEmpty {
                appGroupUserDefaults?.setValue(prayersData, forKey: "prayersData")
            }
        }
    }
    var prayers: Prayers? {
        get {
            return try? Self.decoder.decode(Prayers.self, from: prayersData)
        }
        set {
            prayersData = (try? Self.encoder.encode(newValue)) ?? Data()
        }
    }
    
    @AppStorage("currentPrayerData") var currentPrayerData: Data?
    @Published var currentPrayer: Prayer? {
        didSet {
            currentPrayerData = try? Self.encoder.encode(currentPrayer)
        }
    }

    @AppStorage("nextPrayerData") var nextPrayerData: Data?
    @Published var nextPrayer: Prayer? {
        didSet {
            nextPrayerData = try? Self.encoder.encode(nextPrayer)
        }
    }
    
    @Published var accentColor: AccentColor {
        didSet { appGroupUserDefaults?.setValue(accentColor.rawValue, forKey: "accentColor") }
    }
    
    @Published var travelingMode: Bool {
        didSet { appGroupUserDefaults?.setValue(travelingMode, forKey: "travelingMode") }
    }
    
    @Published var currentLocation: Location? {
        didSet {
            guard let location = currentLocation else { return }
            do {
                let locationData = try Self.encoder.encode(location)
                appGroupUserDefaults?.setValue(locationData, forKey: "currentLocation")
            } catch {
                logger.debug("Failed to encode location: \(error)")
            }
        }
    }
    
    @Published var homeLocation: Location? {
        didSet {
            guard let homeLocation = homeLocation else {
                appGroupUserDefaults?.removeObject(forKey: "homeLocationData")
                return
            }
            do {
                let homeLocationData = try Self.encoder.encode(homeLocation)
                appGroupUserDefaults?.set(homeLocationData, forKey: "homeLocationData")
            } catch {
                logger.debug("Failed to encode home location: \(error)")
            }
        }
    }
    
    @Published var hanafiMadhab: Bool {
        didSet { appGroupUserDefaults?.setValue(hanafiMadhab, forKey: "hanafiMadhab") }
    }
    
    @Published var prayerCalculation: String {
        didSet { appGroupUserDefaults?.setValue(prayerCalculation, forKey: "prayerCalculation") }
    }
    
    @Published var hijriOffset: Int {
        didSet { appGroupUserDefaults?.setValue(hijriOffset, forKey: "hijriOffset") }
    }
    
    @AppStorage("reciter") var reciter: String = "Muhammad Al-Minshawi (Murattal)"
    
    @AppStorage("reciteType") var reciteType: String = "Continue to Next"
    
    @AppStorage("favoriteSurahsData") private var favoriteSurahsData = Data()
    var favoriteSurahs: [Int] {
        get {
            (try? Self.decoder.decode([Int].self, from: favoriteSurahsData)) ?? []
        }
        set {
            favoriteSurahsData = (try? Self.encoder.encode(newValue)) ?? Data()
        }
    }
    
    @AppStorage("bookmarkedAyahsData") private var bookmarkedAyahsData = Data()
    var bookmarkedAyahs: [BookmarkedAyah] {
        get {
            (try? Self.decoder.decode([BookmarkedAyah].self, from: bookmarkedAyahsData)) ?? []
        }
        set {
            bookmarkedAyahsData = (try? Self.encoder.encode(newValue)) ?? Data()
        }
    }
     
    @AppStorage("showCurrentInfo") var showCurrentInfo: Bool = false
    @AppStorage("showNextInfo") var showNextInfo: Bool = false
    
    @AppStorage("showBookmarks") var showBookmarks = true
    @AppStorage("showFavorites") var showFavorites = true

    @AppStorage("favoriteLetterData") private var favoriteLetterData = Data()
    var favoriteLetters: [LetterData] {
        get {
            (try? Self.decoder.decode([LetterData].self, from: favoriteLetterData)) ?? []
        }
        set {
            favoriteLetterData = (try? Self.encoder.encode(newValue)) ?? Data()
        }
    }
    
    func dictionaryRepresentation() -> [String: Any] {
        var dict: [String: Any] = [
            "accentColor": self.accentColor.rawValue,
            
            "travelingMode": self.travelingMode,
            "hanafiMadhab": self.hanafiMadhab,
            "prayerCalculation": self.prayerCalculation,
            "hijriOffset": self.hijriOffset,
            
            "reciter": self.reciter,
            "reciteType": self.reciteType,
            "beginnerMode": self.beginnerMode,
            "lastReadSurah": self.lastReadSurah,
            "lastReadAyah": self.lastReadAyah,
            
            "offsetFajr": self.offsetFajr,
            "offsetSunrise": self.offsetSunrise,
            "offsetDhuhr": self.offsetDhuhr,
            "offsetAsr": self.offsetAsr,
            "offsetMaghrib": self.offsetMaghrib,
            "offsetIsha": self.offsetIsha,
            "offsetDhurhAsr": self.offsetDhurhAsr,
            "offsetMaghribIsha": self.offsetMaghribIsha,
        ]
        
        if let currentLocationData = try? Self.encoder.encode(self.currentLocation) {
            dict["currentLocation"] = String(data: currentLocationData, encoding: .utf8)
        } else {
            dict["currentLocation"] = NSNull()
        }
        
        do {
            dict["homeLocationData"] = try Self.encoder.encode(self.homeLocation)
        } catch {
            logger.debug("Error encoding homeLocation: \(error)")
        }
        
        do {
            dict["favoriteSurahsData"] = try Self.encoder.encode(self.favoriteSurahs)
        } catch {
            logger.debug("Error encoding favoriteSurahs: \(error)")
        }

        do {
            dict["bookmarkedAyahsData"] = try Self.encoder.encode(self.bookmarkedAyahs)
        } catch {
            logger.debug("Error encoding bookmarkedAyahs: \(error)")
        }

        do {
            dict["favoriteLetterData"] = try Self.encoder.encode(self.favoriteLetters)
        } catch {
            logger.debug("Error encoding favoriteLetters: \(error)")
        }
        
        return dict
    }

    func update(from dict: [String: Any]) {
        if let accentColor = dict["accentColor"] as? String,
           let accentColorValue = AccentColor(rawValue: accentColor) {
            self.accentColor = accentColorValue
        }
        if let travelingMode = dict["travelingMode"] as? Bool {
            self.travelingMode = travelingMode
        }
        if let hanafiMadhab = dict["hanafiMadhab"] as? Bool {
            self.hanafiMadhab = hanafiMadhab
        }
        if let prayerCalculation = dict["prayerCalculation"] as? String {
            self.prayerCalculation = prayerCalculation
        }
        if let hijriOffset = dict["hijriOffset"] as? Int {
            self.hijriOffset = hijriOffset
        }
        if let reciter = dict["reciter"] as? String {
            self.reciter = reciter
        }
        if let reciteType = dict["reciteType"] as? String {
            self.reciteType = reciteType
        }
        if let beginnerMode = dict["beginnerMode"] as? Bool {
            self.beginnerMode = beginnerMode
        }
        if let lastReadSurah = dict["lastReadSurah"] as? Int {
            self.lastReadSurah = lastReadSurah
        }
        if let lastReadAyah = dict["lastReadAyah"] as? Int {
            self.lastReadAyah = lastReadAyah
        }
        if let currentLocationString = dict["currentLocation"] as? String,
           let currentLocationData = currentLocationString.data(using: .utf8) {
            self.currentLocation = try? Self.decoder.decode(Location.self, from: currentLocationData)
        }
        if let homeLocationData = dict["homeLocationData"] as? Data {
            self.homeLocation = (try? Self.decoder.decode(Location.self, from: homeLocationData)) ?? nil
        }
        if let favoriteSurahsData = dict["favoriteSurahsData"] as? Data {
            self.favoriteSurahs = (try? Self.decoder.decode([Int].self, from: favoriteSurahsData)) ?? []
        }
        if let bookmarkedAyahsData = dict["bookmarkedAyahsData"] as? Data {
            self.bookmarkedAyahs = (try? Self.decoder.decode([BookmarkedAyah].self, from: bookmarkedAyahsData)) ?? []
        }
        if let favoriteLetterData = dict["favoriteLetterData"] as? Data {
            self.favoriteLetters = (try? Self.decoder.decode([LetterData].self, from: favoriteLetterData)) ?? []
        }
        if let offsetFajr = dict["offsetFajr"] as? Int {
            self.offsetFajr = offsetFajr
        }
        if let offsetSunrise = dict["offsetSunrise"] as? Int {
            self.offsetSunrise = offsetSunrise
        }
        if let offsetDhuhr = dict["offsetDhuhr"] as? Int {
            self.offsetDhuhr = offsetDhuhr
        }
        if let offsetAsr = dict["offsetAsr"] as? Int {
            self.offsetAsr = offsetAsr
        }
        if let offsetMaghrib = dict["offsetMaghrib"] as? Int {
            self.offsetMaghrib = offsetMaghrib
        }
        if let offsetIsha = dict["offsetIsha"] as? Int {
            self.offsetIsha = offsetIsha
        }
        if let offsetDhurhAsr = dict["offsetDhurhAsr"] as? Int {
            self.offsetDhurhAsr = offsetDhurhAsr
        }
        if let offsetMaghribIsha = dict["offsetMaghribIsha"] as? Int {
            self.offsetMaghribIsha = offsetMaghribIsha
        }
    }
    
    @AppStorage("firstLaunch") var firstLaunch = true
    
    @AppStorage("dateNotifications") var dateNotifications = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    
    @AppStorage("lastScheduledHijriYear") private var lastScheduledHijriYear: Int = 0
    
    var hijriCalendar: Calendar = {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "ar")
        return calendar
    }()
    
    var specialEvents: [(String, DateComponents, String, String)] {
        let currentHijriYear = hijriCalendar.component(.year, from: Date())
        return [
            ("Islamic New Year", DateComponents(year: currentHijriYear, month: 1, day: 1), "Start of Hijri year", "The first day of the Islamic calendar; no special acts of worship or celebration are prescribed."),
            ("Day Before Ashura", DateComponents(year: currentHijriYear, month: 1, day: 9), "Recommended to fast", "The Prophet ﷺ intended to fast the 9th to differ from the Jews, making it Sunnah to do so before Ashura."),
            ("Day of Ashura", DateComponents(year: currentHijriYear, month: 1, day: 10), "Recommended to fast", "Ashura marks the day Allah saved Musa (Moses) and the Israelites from Pharaoh; fasting expiates sins of the previous year."),
            
            ("First Day of Ramadan", DateComponents(year: currentHijriYear, month: 9, day: 1), "Begin obligatory fast", "The month of fasting begins; all Muslims must fast from Fajr (dawn) to Maghrib (sunset)."),
            ("Last 10 Nights of Ramadan", DateComponents(year: currentHijriYear, month: 9, day: 21), "Seek Laylatul Qadr", "The most virtuous nights of the year; increase worship as these nights are beloved to Allah and contain Laylatul Qadr."),
            ("27th Night of Ramadan", DateComponents(year: currentHijriYear, month: 9, day: 27), "Likely Laylatul Qadr", "A strong possibility for Laylatul Qadr — the Night of Decree when the Qur’an was sent down — though not confirmed."),
            ("Eid Al-Fitr", DateComponents(year: currentHijriYear, month: 10, day: 1), "Celebration of ending the fast", "Celebration marking the end of Ramadan; fasting is prohibited on this day; encouraged to fast 6 days in Shawwal."),
            
            ("First 10 Days of Dhul-Hijjah", DateComponents(year: currentHijriYear, month: 12, day: 1), "Most beloved days", "The best days for righteous deeds; fasting and dhikr are highly encouraged."),
            ("Beginning of Hajj", DateComponents(year: currentHijriYear, month: 12, day: 8), "Pilgrimage begins", "Pilgrims begin the rites of Hajj, heading to Mina to start the sacred journey."),
            ("Day of Arafah", DateComponents(year: currentHijriYear, month: 12, day: 9), "Recommended to fast", "Fasting for non-pilgrims expiates sins of the past and coming year."),
            ("Eid Al-Adha", DateComponents(year: currentHijriYear, month: 12, day: 10), "Celebration of sacrifice during Hajj", "The day of sacrifice; fasting is not allowed and sacrifice of an animal is offered."),
            ("End of Eid Al-Adha", DateComponents(year: currentHijriYear, month: 12, day: 13), "Hajj and Eid end", "Final day of Eid Al-Adha; pilgrims and non-pilgrims return to daily life."),
        ]
    }
    
    @Published var datePrayers: [Prayer]?
    @Published var dateFullPrayers: [Prayer]?
    @Published var changedDate = false
    
    @AppStorage("hapticOn") var hapticOn: Bool = true
    
    @AppStorage("defaultView") var defaultView: Bool = true
    
    @AppStorage("colorSchemeString") var colorSchemeString: String = "system"
    var colorScheme: ColorScheme? {
        get {
            return colorSchemeFromString(colorSchemeString)
        }
        set {
            colorSchemeString = colorSchemeToString(newValue)
        }
    }
    
    @AppStorage("travelAutomatic") var travelAutomatic: Bool = true
    @AppStorage("travelTurnOffAutomatic") var travelTurnOffAutomatic: Bool = false
    @AppStorage("travelTurnOnAutomatic") var travelTurnOnAutomatic: Bool = false
    
    @AppStorage("showLocationAlert") var showLocationAlert: Bool = false {
        willSet { objectWillChange.send() }
    }
    @AppStorage("showNotificationAlert") var showNotificationAlert: Bool = false
    
    @AppStorage("locationNeverAskAgain") var locationNeverAskAgain = false
    @AppStorage("notificationNeverAskAgain") var notificationNeverAskAgain = false
    
    @AppStorage("naggingMode") var naggingMode: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingStartOffset") var naggingStartOffset: Int = 30 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    
    @AppStorage("preNotificationFajr") var preNotificationFajr: Int = 0 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("notificationFajr") var notificationFajr: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingFajr") var naggingFajr: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("offsetFajr") var offsetFajr: Int = 0 {
        didSet { self.fetchPrayerTimes(force: true) }
    }

    @AppStorage("preNotificationSunrise") var preNotificationSunrise: Int = 0 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("notificationSunrise") var notificationSunrise: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingSunrise") var naggingSunrise: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("offsetSunrise") var offsetSunrise: Int = 0 {
        didSet { self.fetchPrayerTimes(force: true) }
    }

    @AppStorage("preNotificationDhuhr") var preNotificationDhuhr: Int = 0 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("notificationDhuhr") var notificationDhuhr: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingDhuhr") var naggingDhuhr: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("offsetDhuhr") var offsetDhuhr: Int = 0 {
        didSet { self.fetchPrayerTimes(force: true) }
    }

    @AppStorage("preNotificationAsr") var preNotificationAsr: Int = 0 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("notificationAsr") var notificationAsr: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingAsr") var naggingAsr: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("offsetAsr") var offsetAsr: Int = 0 {
        didSet { self.fetchPrayerTimes(force: true) }
    }

    @AppStorage("preNotificationMaghrib") var preNotificationMaghrib: Int = 0 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("notificationMaghrib") var notificationMaghrib: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingMaghrib") var naggingMaghrib: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("offsetMaghrib") var offsetMaghrib: Int = 0 {
        didSet { self.fetchPrayerTimes(force: true) }
    }

    @AppStorage("preNotificationIsha") var preNotificationIsha: Int = 0 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("notificationIsha") var notificationIsha: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingIsha") var naggingIsha: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("offsetIsha") var offsetIsha: Int = 0 {
        didSet { self.fetchPrayerTimes(force: true) }
    }
    
    @AppStorage("offsetDhurhAsr") var offsetDhurhAsr: Int = 0 {
        didSet { self.fetchPrayerTimes(force: true) }
    }
    @AppStorage("offsetMaghribIsha") var offsetMaghribIsha: Int = 0 {
        didSet { self.fetchPrayerTimes(force: true) }
    }

    @AppStorage("beginnerMode") var beginnerMode: Bool = false
    
    @AppStorage("groupBySurah") var groupBySurah: Bool = true
    @AppStorage("searchForSurahs") var searchForSurahs: Bool = true
    
    @AppStorage("lastReadSurah") var lastReadSurah: Int = 0
    @AppStorage("lastReadAyah") var lastReadAyah: Int = 0
    
    @AppStorage("lastListenedSurahData") private var lastListenedSurahData: Data?
    var lastListenedSurah: LastListenedSurah? {
        get {
            guard let data = lastListenedSurahData else { return nil }
            do {
                return try Self.decoder.decode(LastListenedSurah.self, from: data)
            } catch {
                logger.debug("Failed to decode last listened surah: \(error)")
                return nil
            }
        }
        set {
            if let newValue = newValue {
                do {
                    lastListenedSurahData = try Self.encoder.encode(newValue)
                } catch {
                    logger.debug("Failed to encode last listened surah: \(error)")
                }
            } else {
                lastListenedSurahData = nil
            }
        }
    }
    
    @AppStorage("showArabicText") var showArabicText: Bool = true
    @AppStorage("cleanArabicText") var cleanArabicText: Bool = false
    @AppStorage("fontArabic") var fontArabic: String = "KFGQPCHafsEx1UthmanicScript-Reg"
    @AppStorage("fontArabicSize") var fontArabicSize: Double = Double(UIFont.preferredFont(forTextStyle: .body).pointSize) + 10
    
    @AppStorage("useFontArabic") var useFontArabic = true

    @AppStorage("showTransliteration") var showTransliteration: Bool = true
    @AppStorage("showEnglishTranslation") var showEnglishTranslation: Bool = true
    
    @AppStorage("englishFontSize") var englishFontSize: Double = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
    
    @inline(__always)
    private func binding<T>(_ key: ReferenceWritableKeyPath<Settings, T>, default value: T) -> Binding<T> {
        Binding(
            get: { self[keyPath: key] },
            set: { self[keyPath: key] = $0 }
        )
    }

    func currentNotification(prayerTime: Prayer) -> Binding<Bool> {
        guard let prefs = Self.notifTable[prayerTime.nameTransliteration] else {
            return .constant(false)
        }
        return binding(prefs.enabled, default: false)
    }

    func currentPreNotification(prayerTime: Prayer) -> Binding<Int> {
        guard let prefs = Self.notifTable[prayerTime.nameTransliteration] else {
            return .constant(0)
        }
        return binding(prefs.preMinutes, default: 0)
    }

    func shouldShowFilledBell(prayerTime: Prayer) -> Bool {
        guard let prefs = Self.notifTable[prayerTime.nameTransliteration] else { return false }
        return self[keyPath: prefs.enabled] && self[keyPath: prefs.preMinutes] > 0
    }

    func shouldShowOutlinedBell(prayerTime: Prayer) -> Bool {
        guard let prefs = Self.notifTable[prayerTime.nameTransliteration] else { return false }
        return self[keyPath: prefs.enabled] && self[keyPath: prefs.preMinutes] == 0
    }
    
    func toggleSurahFavorite(surah: Int) {
        withAnimation {
            if isSurahFavorite(surah: surah) {
                favoriteSurahs.removeAll(where: { $0 == surah })
            } else {
                favoriteSurahs.append(surah)
            }
        }
    }

    func isSurahFavorite(surah: Int) -> Bool {
        return favoriteSurahs.contains(surah)
    }

    func toggleBookmark(surah: Int, ayah: Int) {
        withAnimation {
            let bookmark = BookmarkedAyah(surah: surah, ayah: ayah)
            if let index = bookmarkedAyahs.firstIndex(where: {$0.id == bookmark.id}) {
                bookmarkedAyahs.remove(at: index)
            } else {
                bookmarkedAyahs.append(bookmark)
            }
        }
    }

    func isBookmarked(surah: Int, ayah: Int) -> Bool {
        let bookmark = BookmarkedAyah(surah: surah, ayah: ayah)
        return bookmarkedAyahs.contains(where: {$0.id == bookmark.id})
    }

    func toggleLetterFavorite(letterData: LetterData) {
        withAnimation {
            if isLetterFavorite(letterData: letterData) {
                favoriteLetters.removeAll(where: { $0.id == letterData.id })
            } else {
                favoriteLetters.append(letterData)
            }
        }
    }

    func isLetterFavorite(letterData: LetterData) -> Bool {
        return favoriteLetters.contains(where: {$0.id == letterData.id})
    }
    
    private static let unwantedCharSet: CharacterSet = {
        CharacterSet(charactersIn: "-[]()'\"").union(.nonBaseCharacters)
    }()

    func cleanSearch(_ text: String, whitespace: Bool = false) -> String {
        var cleaned = String(text.unicodeScalars
            .filter { !Self.unwantedCharSet.contains($0) }
        ).lowercased()

        if whitespace {
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned
    }
    
    func colorSchemeFromString(_ colorScheme: String) -> ColorScheme? {
        switch colorScheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }

    func colorSchemeToString(_ colorScheme: ColorScheme?) -> String {
        switch colorScheme {
        case .light:
            return "light"
        case .dark:
            return "dark"
        default:
            return "system"
        }
    }
}
