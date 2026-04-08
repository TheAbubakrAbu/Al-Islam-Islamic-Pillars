import SwiftUI
import Adhan
import CoreLocation
import Network
import UserNotifications
import WidgetKit

struct AdhanSoundOption: Identifiable, Equatable {
    let id: String
    let title: String
}

extension Settings {
    static let supportedAdhanSounds: [AdhanSoundOption] = [
        .init(id: "default", title: "Default"),
        .init(id: "egypt-30", title: "Egypt"),
        .init(id: "makkah-30", title: "Makkah"),
        .init(id: "madina-30", title: "Madina"),
        .init(id: "alaqsa-30", title: "Al-Aqsa"),
        .init(id: "alaqsa-2-30", title: "Al-Aqsa 2"),
        
        .init(id: "abdulbaset-30", title: "Abdul Baset"),
        .init(id: "abdulghaffar-30", title: "Abdul Ghaffar"),
        .init(id: "al-qatami-30", title: "Al-Qatami"),
        .init(id: "zakariya-30", title: "Zakariya")
    ]

    func adhanSoundFilename(for selection: String) -> String? {
        guard selection != "default",
              Self.supportedAdhanSounds.contains(where: { $0.id == selection }),
              Bundle.main.path(forResource: selection, ofType: "caf") != nil else { return nil }
        return "\(selection).caf"
    }

    static let locationManager: CLLocationManager = {
        let lm = CLLocationManager()
        lm.desiredAccuracy = kCLLocationAccuracyHundredMeters
        lm.distanceFilter = 500
        return lm
    }()
    
    private static let geocoder = CLGeocoder()
    private static var cachedPlacemark: (coord: CLLocationCoordinate2D, city: String, countryCode: String)?
    private static let geocodeActor = GeocodeActor()
    private static let networkMonitor = NWPathMonitor()
    private static let networkMonitorQueue = DispatchQueue(label: AppIdentifiers.networkMonitorQueueLabel)
    private static var didStartNetworkMonitor = false
    private static var isNetworkReachable = true
    private static var pendingGeocodeCoord: CLLocationCoordinate2D?
    
    private static let oneMile: CLLocationDistance = 1609.34   // m
    private static let halfMile: CLLocationDistance = 500      // m
    private static let maxAge: TimeInterval = 180              // s
    
    private static let travelThresholdM: CLLocationDistance = 48 * oneMile   // ≈ 77 112 m

    private static func ensureNetworkMonitorStarted() {
        guard !didStartNetworkMonitor else { return }
        didStartNetworkMonitor = true

        networkMonitor.pathUpdateHandler = { path in
            let isNowReachable = (path.status == .satisfied)
            let becameReachable = isNowReachable && !isNetworkReachable
            isNetworkReachable = isNowReachable

            guard becameReachable else { return }

            let pending = pendingGeocodeCoord
            pendingGeocodeCoord = nil
            guard let pending else { return }

            Task { @MainActor in
                await Settings.shared.updateCity(latitude: pending.latitude, longitude: pending.longitude)
                Settings.shared.fetchPrayerTimes(force: true)
            }
        }

        networkMonitor.start(queue: networkMonitorQueue)
    }

    private func queueGeocodeForReconnect(_ coord: CLLocationCoordinate2D) {
        Self.pendingGeocodeCoord = coord
    }

    private func isNetworkGeocodeError(_ error: Error) -> Bool {
        if let clError = error as? CLError {
            return clError.code == .network
        }

        let nsError = error as NSError
        return nsError.domain == kCLErrorDomain && nsError.code == CLError.Code.network.rawValue
    }
    
    // AUTHORIZATION CHANGES
    func locationManager(_ mgr: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            showLocationAlert = false
            mgr.requestLocation()
            #if os(iOS)
            mgr.startMonitoringSignificantLocationChanges()
            #else
            mgr.startUpdatingLocation()
            #endif
            
        case .denied where !locationNeverAskAgain:
            showLocationAlert = true

        case .restricted, .notDetermined:
            logger.debug("Location authorization is restricted or not determined.")
            break

        default: break
        }
    }
    
    // MAIN LOCATION CALLBACK
    func locationManager(_ mgr: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last else { return }

        let isValid = loc.horizontalAccuracy > 0
        let isFresh = abs(loc.timestamp.timeIntervalSinceNow) <= 300
        guard isValid && isFresh else { return }

        if let cur = currentLocation {
            let prev = CLLocation(latitude: cur.latitude, longitude: cur.longitude)
            let distance = prev.distance(from: loc)
            if distance < Self.halfMile { return }
        }

        Task { @MainActor in
            await updateCity(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
            fetchPrayerTimes(force: false)
        }
    }

    // ERROR HANDLER
    func locationManager(_ mgr: CLLocationManager, didFailWithError err: Error) {
        logger.error("CLLocationManager failed: \(err.localizedDescription)")
    }

    // PERMISSION REQUEST
    func requestLocationAuthorization() {
        Self.ensureNetworkMonitorStarted()

        switch Self.locationManager.authorizationStatus {
        case .notDetermined:
            Self.locationManager.requestAlwaysAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            #if os(iOS)
            Self.locationManager.startMonitoringSignificantLocationChanges()
            #else
            Self.locationManager.startUpdatingLocation()
            #endif

            Self.locationManager.requestLocation()
        default:
            break
        }
    }
    
    actor GeocodeActor {
        private let gc = CLGeocoder()
        func placemark(for location: CLLocation) async throws -> CLPlacemark? {
            if gc.isGeocoding { gc.cancelGeocode() }
            return try await gc.reverseGeocodeLocation(location).first
        }
    }
    
    /// Reverse‑geocode utilities
    @MainActor
    func updateCity(latitude: Double, longitude: Double, attempt: Int = 0, maxAttempts: Int = 3) async {
        Self.ensureNetworkMonitorStarted()

        let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        if !Self.isNetworkReachable {
            queueGeocodeForReconnect(coord)

            // Keep coordinates usable for prayer calculations while waiting for connectivity.
            if currentLocation == nil || currentLocation?.city.contains("(") == true {
                withAnimation {
                    currentLocation = Location(city: "(\(latitude.stringRepresentation), \(longitude.stringRepresentation))",
                                               latitude: latitude, longitude: longitude)
                }
            }
            return
        }

        if let cached = Self.cachedPlacemark,
           CLLocation(latitude: cached.coord.latitude, longitude: cached.coord.longitude)
             .distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude)) < 100,
                     cached.city == currentLocation?.city,
                     cached.countryCode == currentCountryCode {
            return
        }

        let location = CLLocation(latitude: latitude, longitude: longitude)

        do {
            guard let placemark = try await Self.geocodeActor.placemark(for: location) else {
                throw CLError(.geocodeFoundNoResult)
            }

            let newCity: String = {
                let cityLike = placemark.locality
                           ?? placemark.subLocality
                           ?? placemark.subAdministrativeArea
                           ?? placemark.name
                let region = placemark.administrativeArea ?? placemark.country
                if let c = cityLike, let r = region { return "\(c), \(r)" }
                if let c = cityLike { return c }
                if let r = region { return r }
                return "(\(latitude.stringRepresentation), \(longitude.stringRepresentation))"
            }()

            let detectedCountryCode = placemark.isoCountryCode?.uppercased() ?? ""

            if newCity != currentLocation?.city || detectedCountryCode != currentCountryCode {
                withAnimation {
                    currentLocation = Location(city: newCity, latitude: latitude, longitude: longitude)
                    currentCountryCode = detectedCountryCode
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }

            Self.cachedPlacemark = (coord, newCity, detectedCountryCode)

        } catch {
            if isNetworkGeocodeError(error) || !Self.isNetworkReachable {
                queueGeocodeForReconnect(coord)
                logger.warning("Geocode deferred until network returns")
                return
            }

            logger.warning("Geocode attempt \(attempt+1) failed: \(error.localizedDescription)")
            guard attempt + 1 < maxAttempts else {
                withAnimation {
                    currentLocation = Location(city: "(\(latitude.stringRepresentation), \(longitude.stringRepresentation))",
                                               latitude: latitude, longitude: longitude)
                    currentCountryCode = ""
                    WidgetCenter.shared.reloadAllTimelines()
                }
                return
            }
            let delay = UInt64(pow(2.0, Double(attempt)) * 2_000_000_000)
            try? await Task.sleep(nanoseconds: delay)
            await updateCity(latitude: latitude, longitude: longitude, attempt: attempt + 1, maxAttempts: maxAttempts)
        }
    }
    
    private static let travelingNotificationId = "Al-Islam.TravelingMode"
    private static let calculationNotificationId = "Al-Islam.CalculationMode"

    private static let countryCalculationMap: [String: String] = [
        // North America method (mainland + US territories commonly on ISNA-style defaults)
        "US": "North America",
        "CA": "North America",
        "MX": "North America",
        "PR": "North America",
        "VI": "North America",
        "GU": "North America",
        "AS": "North America",
        "MP": "North America",
        "UM": "North America",

        // United Kingdom
        "GB": "Britain (Moonsighting Committee)",
        "IE": "Britain (Moonsighting Committee)",

        // Saudi Arabia and nearby countries that commonly follow it
        "SA": "Saudi Arabia (Umm Al-Qura)",
        "BH": "Saudi Arabia (Umm Al-Qura)",
        "OM": "Saudi Arabia (Umm Al-Qura)",
        "YE": "Saudi Arabia (Umm Al-Qura)",

        // Egyptian method and nearby region defaults
        "EG": "Egypt",
        "LY": "Egypt",
        "TN": "Egypt",
        "DZ": "Egypt",
        "MA": "Egypt",
        "SD": "Egypt",
        "SS": "Egypt",
        "DJ": "Egypt",
        "ER": "Egypt",
        "SO": "Egypt",
        "JO": "Egypt",
        "LB": "Egypt",
        "SY": "Egypt",
        "IQ": "Egypt",
        "PS": "Egypt",

        // Gulf country-specific methods
        "AE": "Dubai",
        "KW": "Kuwait",
        "QA": "Qatar",

        // Turkey
        "TR": "Turkey",
        "CY": "Turkey",
        "AL": "Turkey",
        "XK": "Turkey",
        "BA": "Turkey",
        "MK": "Turkey",

        // Tehran
        "IR": "Tehran",

        // Karachi method (South Asia)
        "PK": "Karachi",
        "IN": "Karachi",
        "BD": "Karachi",
        "AF": "Karachi",
        "NP": "Karachi",
        "LK": "Karachi",

        // Singapore method (Southeast Asia)
        "SG": "Singapore",
        "MY": "Singapore",
        "BN": "Singapore",
        "ID": "Singapore",
        "TH": "Singapore",
        "PH": "Singapore"
    ]

    private func automaticCalculationMethod(for countryCode: String) -> String {
        Self.countryCalculationMap[countryCode] ?? "Muslim World League"
    }

    /// Maps stored or auto-detected labels to a key that exists in `calcParams` (avoids repeat auto-changes / picker fights).
    private func canonicalPrayerCalculationMethod(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if Self.calcParams[trimmed] != nil { return trimmed }
        switch trimmed {
        case "Saudi Arabia":
            return "Saudi Arabia (Umm Al-Qura)"
        case "United Kingdom":
            return "Britain (Moonsighting Committee)"
        default:
            return "Muslim World League"
        }
    }

    /// Resolves the Adhan parameters for whatever string is stored (picker label, legacy name, or unknown → MWL fallback).
    private func calculationParameters(forStoredLabel name: String) -> CalculationParameters {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let params = Self.calcParams[trimmed] { return params }
        let canonical = canonicalPrayerCalculationMethod(trimmed)
        return Self.calcParams[canonical] ?? Self.calcParams["Muslim World League"]!
    }

    func checkAutomaticPrayerCalculation() {
        guard Bundle.main.bundleIdentifier?.contains("Widget") != true,
              calculationAutomatic,
              let currentLocation = currentLocation,
              currentLocation.latitude != 1000,
              currentLocation.longitude != 1000
        else { return }

        let countryCode = currentCountryCode.uppercased()
        guard !countryCode.isEmpty else { return }

        let detectedRaw = automaticCalculationMethod(for: countryCode)
        let detectedMethod = canonicalPrayerCalculationMethod(detectedRaw)
        guard let detectedParams = Self.calcParams[detectedMethod] else { return }

        let currentParams = calculationParameters(forStoredLabel: prayerCalculation)
        if detectedParams == currentParams {
            return
        }

        let previousMethod = prayerCalculation
        withAnimation {
            prayerCalculation = detectedMethod
        }

        calculationAutoPreviousMethod = previousMethod
        calculationAutoDetectedMethod = detectedMethod
        calculationAutoDetectedCountryCode = countryCode
        calculationAutoChanged = true

        #if os(iOS)
        let content = UNMutableNotificationContent()
        content.title = "Al-Islam"
        content.body = "Prayer calculation switched to \(detectedMethod) for \(currentLocation.city)."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: Self.calculationNotificationId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
        #endif
    }

    func checkIfTraveling() {
        guard Bundle.main.bundleIdentifier?.contains("Widget") != true,
              travelAutomatic,
              let currentLocation = currentLocation,
              let homeLocation = homeLocation,
              currentLocation.latitude != 1000,
              currentLocation.longitude != 1000
        else { return }

        let here  = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let home  = CLLocation(latitude: homeLocation.latitude, longitude: homeLocation.longitude)
        let miles = here.distance(from: home) / 1609.34
        let isAway = miles >= 48

        if isAway {
            if !travelingMode {
                withAnimation { travelingMode = true }
                travelTurnOffAutomatic = false
                travelTurnOnAutomatic  = true
                #if os(iOS)
                let content = UNMutableNotificationContent()
                content.title = "Al-Islam"
                content.body  = "Traveling mode automatically turned on at \(currentLocation.city)"
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let req = UNNotificationRequest(identifier: Self.travelingNotificationId, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(req)
                #endif
            }
        } else {
            if travelingMode {
                withAnimation { travelingMode = false }
                travelTurnOnAutomatic  = false
                travelTurnOffAutomatic = true
                #if os(iOS)
                let content = UNMutableNotificationContent()
                content.title = "Al-Islam"
                content.body  = "Traveling mode automatically turned off at \(currentLocation.city)"
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let req = UNNotificationRequest(identifier: Self.travelingNotificationId, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(req)
                #endif
            }
        }
    }
    
    private static let hijriCalendarAR: Calendar = {
        var c = Calendar(identifier: .islamicUmmAlQura)
        c.locale = Locale(identifier: "ar")
        return c
    }()

    private static let hijriFormatterAR: DateFormatter = {
        let f = DateFormatter()
        f.calendar = hijriCalendarAR
        f.locale   = Locale(identifier: "ar")
        f.dateFormat = "d MMMM، yyyy"
        return f
    }()

    private static let hijriFormatterEN: DateFormatter = {
        let f = DateFormatter()
        f.calendar = hijriCalendarAR
        f.locale   = Locale(identifier: "en")
        f.dateStyle = .long
        return f
    }()
    
    private static let gregorian: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = .current
        return c
    }()
    
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

    func effectiveHijriReferenceDate(now: Date = Date()) -> Date {
        guard switchHijriDateAtMaghrib else { return now }
        guard let prayers = getPrayerTimes(for: now, fullPrayers: true) else { return now }
        guard let maghrib = prayers.first(where: { $0.nameTransliteration == "Maghrib" })?.time else { return now }
        guard now >= maghrib else { return now }
        return Self.gregorian.date(byAdding: .day, value: 1, to: now) ?? now
    }
    
    func updateDates() {
        let now = Date()
        let effectiveDate = effectiveHijriReferenceDate(now: now)
        if let h = hijriDate, Self.gregorian.isDate(h.date, inSameDayAs: effectiveDate) {
            return
        }

        let base = Self.hijriCalendarAR.date(byAdding: .day, value: hijriOffset, to: effectiveDate) ?? effectiveDate
        let arabic = arabicNumberString(from: Self.hijriFormatterAR.string(from: base)) + " هـ"
        let english = Self.hijriFormatterEN.string(from: base)

        withAnimation {
            hijriDate = HijriDate(english: english, arabic: arabic, date: effectiveDate)
        }
    }
    
    private static let calcParams: [String: CalculationParameters] = {
        let map: [(String, CalculationMethod)] = [
            ("Muslim World League", .muslimWorldLeague),
            ("Britain (Moonsighting Committee)",      .moonsightingCommittee),
            ("Saudi Arabia (Umm Al-Qura)",        .ummAlQura),
            ("Egypt",               .egyptian),
            ("Dubai",               .dubai),
            ("Kuwait",              .kuwait),
            ("Qatar",               .qatar),
            ("Turkey",              .turkey),
            ("Tehran",              .tehran),
            ("Karachi",             .karachi),
            ("Singapore",           .singapore),
            ("North America",       .northAmerica),
            
            // Legacy labels kept for backward compatibility with saved settings.
            ("Moonsight Committee", .moonsightingCommittee),
            ("Umm Al-Qura",         .ummAlQura)
        ]
        return Dictionary(uniqueKeysWithValues: map.map { ($0.0, $0.1.params) })
    }()
    
    private struct NotifPrefs {
        let enabled: ReferenceWritableKeyPath<Settings, Bool>
        let preMinutes: ReferenceWritableKeyPath<Settings, Int>
        let nagging: ReferenceWritableKeyPath<Settings, Bool>
    }
    
    private struct Proto {
        let ar, tr, en, img, rakah, sunnahB, sunnahA: String
    }

    private static let prayerProtos: [String: Proto] = [
        "Fajr":      .init(ar:"الفَجر",  tr:"Fajr",   en:"Dawn",     img:"sunrise",       rakah:"2", sunnahB:"2", sunnahA:"0"),
        "Sunrise":   .init(ar:"الشُرُوق", tr:"Shurooq",en:"Sunrise",  img:"sunrise.fill",  rakah:"0", sunnahB:"0", sunnahA:"0"),
        "Dhuhr":     .init(ar:"الظُهر",  tr:"Dhuhr",  en:"Noon",     img:"sun.max",       rakah:"4", sunnahB:"2 and 2", sunnahA:"2"),
        "Asr":       .init(ar:"العَصر",  tr:"Asr",    en:"Afternoon",img:"sun.min",       rakah:"4", sunnahB:"0", sunnahA:"0"),
        "Maghrib":   .init(ar:"المَغرِب",tr:"Maghrib",en:"Sunset",   img:"sunset",        rakah:"3", sunnahB:"0", sunnahA:"2"),
        "Isha":      .init(ar:"العِشَاء", tr:"Isha",   en:"Night",    img:"moon",          rakah:"4", sunnahB:"0", sunnahA:"2"),
        // grouped (travel) variants
        "Dhuhr/Asr":     .init(ar:"الظُهر وَالعَصر", tr:"Dhuhr/Asr",   en:"Daytime",   img:"sun.max", rakah:"2 and 2", sunnahB:"0", sunnahA:"0"),
        "Maghrib/Isha":     .init(ar:"المَغرِب وَالعِشَاء", tr:"Maghrib/Isha", en:"Nighttime", img:"sunset", rakah:"3 and 2",sunnahB:"0", sunnahA:"0")
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
        let rawPrayers = _computeRawPrayers(for: date)
        guard !rawPrayers.isEmpty else { return nil }
        
        if fullPrayers || !travelingMode {
            return rawPrayers
        }
        
        return _filterTravelingMode(rawPrayers)
    }    

    /// Optimized getter that computes both normal and full prayer lists in a single calculation pass
    func getPrayerTimesNormalAndFull(for date: Date) -> (normal: [Prayer], full: [Prayer])? {
        let rawPrayers = _computeRawPrayers(for: date)
        guard !rawPrayers.isEmpty else { return nil }
        
        let fullList = rawPrayers
        let normalList = travelingMode ? _filterTravelingMode(rawPrayers) : rawPrayers
        
        return (normal: normalList, full: fullList)
    }    
    /// Computes the raw unfiltered prayer times for a given date. This internal function
    /// handles all PrayerTimes calculation logic once, avoiding duplicate computations.
    private func _computeRawPrayers(for date: Date) -> [Prayer] {
        guard let here = currentLocation, here.latitude != 1000, here.longitude != 1000 else { return [] }

        var params = Self.calcParams[prayerCalculation] ?? Self.calcParams["Muslim World League"]!
        params.madhab = hanafiMadhab ? Madhab.hanafi : Madhab.shafi

        let comps = Self.gregorian.dateComponents([.year, .month, .day], from: date)

        guard let raw = PrayerTimes(
                coordinates: Coordinates(latitude: here.latitude, longitude: here.longitude),
                date: comps,
                calculationParameters: params
        )
        else { return [] }

        @inline(__always) func off(_ d: Date, by m: Int) -> Date {
            d.addingTimeInterval(Double(m) * 60)
        }

        let fajr     = off(raw.fajr,     by: offsetFajr)
        let sunrise  = off(raw.sunrise,  by: offsetSunrise)
        let dhuhr    = off(raw.dhuhr,    by: offsetDhuhr)
        let asr      = off(raw.asr,      by: offsetAsr)
        let maghrib  = off(raw.maghrib,  by: offsetMaghrib)
        let isha     = off(raw.isha,     by: offsetIsha)

        let isFriday = Self.gregorian.component(.weekday, from: date) == 6

        var list: [Prayer] = [
            prayer(from: "Fajr",    time: fajr),
            prayer(from: "Sunrise", time: sunrise)
        ]

        // Dhuhr / Jumuah switch
        if isFriday {
            list.append(
                Prayer(nameArabic: "الجُمُعَة",
                       nameTransliteration: "Jumuah",
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
    }

    func fetchPrayerTimes(force: Bool = false, notification: Bool = false, calledFrom: StaticString = #function, completion: (() -> Void)? = nil) {
        Self.ensureNetworkMonitorStarted()
        updateDates()
        
        guard let loc = currentLocation, loc.latitude  != 1000, loc.longitude != 1000 else {
            logger.debug("No valid location – skip refresh")
            completion?()
            return
        }
        
        if force || loc.city.contains("(") {
            let coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
            if Self.isNetworkReachable {
                Task { @MainActor in
                    await updateCity(latitude: loc.latitude, longitude: loc.longitude)
                    if Bundle.main.bundleIdentifier?.contains("Widget") != true,
                       calculationAutomatic,
                       !calculationManuallyToggled {
                        checkAutomaticPrayerCalculation()
                    }
                }
            } else {
                queueGeocodeForReconnect(coord)
                logger.debug("Skipping geocode while offline; will retry on reconnect")
            }
        }
        
        let isWidget = Bundle.main.bundleIdentifier?.contains("Widget") == true
        if !isWidget, travelAutomatic, homeLocation != nil, !travelingModeManuallyToggled {
            travelingModeManuallyToggled = false
            checkIfTraveling()
        } else if travelingModeManuallyToggled {
            travelingModeManuallyToggled = false
        }

        if !isWidget, calculationAutomatic, !calculationManuallyToggled {
            calculationManuallyToggled = false
            // Coordinate placeholder city means ISO country may still be wrong or empty; geocode runs
            // asynchronously above — we run the check again from that Task once the placemark is known.
            if !loc.city.contains("(") {
                checkAutomaticPrayerCalculation()
            }
        } else if calculationManuallyToggled {
            calculationManuallyToggled = false
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
            
            // Single calculation – both filtered and full lists derived from same source
            let rawPrayers    = _computeRawPrayers(for: today)
            let todayPrayers  = travelingMode ? _filterTravelingMode(rawPrayers) : rawPrayers
            let fullPrayers   = rawPrayers  // Full list already computed
            
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
        } else if notification {
            schedulePrayerTimeNotifications()
            printAllScheduledNotifications()
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        updateCurrentAndNextPrayer()
        completion?()
    }
    
    /// Efficiently filters raw prayers to traveling mode format (condensed list)
    private func _filterTravelingMode(_ rawPrayers: [Prayer]) -> [Prayer] {
        guard rawPrayers.count >= 6 else { return rawPrayers }

        let combinedDhuhrAsr = prayer(from: "Dhuhr/Asr", time: rawPrayers[2].time)
        let combinedMaghribIsha = prayer(from: "Maghrib/Isha", time: rawPrayers[4].time)

        return [rawPrayers[0], rawPrayers[1], combinedDhuhrAsr, combinedMaghribIsha]
    }
    
    func updateCurrentAndNextPrayer() {
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
               let firstTomorrow = _getFirstPrayerOfDay(for: tmr) {
                nextPrayer = firstTomorrow
            } else {
                nextPrayer = nil
            }
        }
    }
    
    /// Efficiently gets just the first prayer of a given day (optimized for getting tomorrow's Fajr)
    private func _getFirstPrayerOfDay(for date: Date) -> Prayer? {
        let raw = _computeRawPrayers(for: date)
        return raw.first  // Fajr is always first regardless of mode
    }
    
    @MainActor
    func requestNotificationAuthorization() async -> Bool {
        #if os(iOS)
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
        #else
        return true
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

    /// Static lookup table
    private static let notifTable: [String: NotifPrefs] = [
        "Fajr":          .init(enabled: \.notificationFajr,  preMinutes: \.preNotificationFajr,  nagging: \.naggingFajr),
        "Shurooq":       .init(enabled: \.notificationSunrise, preMinutes: \.preNotificationSunrise, nagging: \.naggingSunrise),
        "Dhuhr":         .init(enabled: \.notificationDhuhr, preMinutes: \.preNotificationDhuhr, nagging: \.naggingDhuhr),
        "Dhuhr/Asr":         .init(enabled: \.notificationDhuhr, preMinutes: \.preNotificationDhuhr, nagging: \.naggingDhuhr),
        "Jumuah":       .init(enabled: \.notificationDhuhr, preMinutes: \.preNotificationDhuhr, nagging: \.naggingDhuhr),
        "Asr":           .init(enabled: \.notificationAsr,   preMinutes: \.preNotificationAsr,   nagging: \.naggingAsr),
        "Maghrib":       .init(enabled: \.notificationMaghrib, preMinutes: \.preNotificationMaghrib, nagging: \.naggingMaghrib),
        "Maghrib/Isha":         .init(enabled: \.notificationMaghrib, preMinutes: \.preNotificationMaghrib, nagging: \.naggingMaghrib),
        "Isha":          .init(enabled: \.notificationIsha,  preMinutes: \.preNotificationIsha,  nagging: \.naggingIsha)
    ]

    /// Pre‑computes the full list of minutes‑before offsets for a prayer.
    private func offsets(for prefs: NotifPrefs) -> [Int] {
        var result: [Int] = []

        // “at time” alert
        if self[keyPath: prefs.enabled] { result.append(0) }

        // user‑defined single offset
        let minutes = self[keyPath: prefs.preMinutes]
        if self[keyPath: prefs.enabled], minutes > 0 {
            result.append(minutes)
        }

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
        #if os(iOS)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        #endif

        // Unique per-day id so we don’t collide across days
        let id = String(format: "RefreshReminder-%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)

        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(req) { error in
            if let error { logger.debug("Refresh reminder add failed: \(error.localizedDescription)") }
        }
    }

    func schedulePrayerTimeNotifications() {
        #if os(iOS)
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
        
        let futureDays = naggingMode ? 1 : 3
        if futureDays > 0 {
            for dayOffset in 1...futureDays {
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
        }

        if naggingMode {
            scheduleRefreshNag(inDays: 1, using: center)
        }
        scheduleRefreshNag(inDays: 2, using: center)
        scheduleRefreshNag(inDays: 3, using: center)
        
        prayers?.setNotification = true
        #else
        return
        #endif
    }
    
    private func buildBody(prayer: Prayer, minutesBefore: Int?, city: String) -> String {
        let englishPart: String = {
            switch prayer.nameTransliteration {
            case "Shurooq":
                return " (end of Fajr)"
            case "Jumuah":
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

    private func prayerNotificationSound(for prayer: Prayer, minutesBefore: Int?) -> UNNotificationSound {
        // Shurooq marks end of Fajr, not a salah — never use full adhan.
        if prayer.nameTransliteration == "Shurooq" {
            return .default
        }
        guard minutesBefore == nil else { return .default }

        #if os(iOS)
        guard let filename = adhanSoundFilename(for: adhanNotificationSound) else {
            return .default
        }
        return UNNotificationSound(named: UNNotificationSoundName(filename))
        #else
        return .default
        #endif
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
        content.title = "Al-Islam"
        content.body = buildBody(prayer: prayer, minutesBefore: minutes, city: city)
        content.sound = prayerNotificationSound(for: prayer, minutesBefore: minutes)
        #if os(iOS)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        #endif

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
            #if os(iOS)
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }
            #endif
            
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

    enum PrayerNotificationMode {
        case off
        case atTime
        case preNotification

        var symbolName: String {
            switch self {
            case .off:
                return "bell.slash"
            case .atTime:
                return "bell"
            case .preNotification:
                return "bell.fill"
            }
        }
    }

    func notificationMode(for prayerTime: Prayer) -> PrayerNotificationMode {
        guard let prefs = Self.notifTable[prayerTime.nameTransliteration] else { return .off }

        let enabled = self[keyPath: prefs.enabled]
        let preMinutes = self[keyPath: prefs.preMinutes]

        if enabled && preMinutes > 0 {
            return .preNotification
        }

        if enabled {
            return .atTime
        }

        return .off
    }

    func setNotificationMode(_ mode: PrayerNotificationMode, for prayerTime: Prayer) {
        guard let prefs = Self.notifTable[prayerTime.nameTransliteration] else { return }

        switch mode {
        case .off:
            self[keyPath: prefs.preMinutes] = 0
            self[keyPath: prefs.enabled] = false
        case .atTime:
            self[keyPath: prefs.preMinutes] = 0
            self[keyPath: prefs.enabled] = true
        case .preNotification:
            self[keyPath: prefs.preMinutes] = 15
            self[keyPath: prefs.enabled] = true
        }
    }

    @discardableResult
    func cycleNotificationMode(for prayerTime: Prayer) -> PrayerNotificationMode {
        let nextMode: PrayerNotificationMode

        switch notificationMode(for: prayerTime) {
        case .off:
            nextMode = .atTime
        case .atTime:
            nextMode = .preNotification
        case .preNotification:
            nextMode = .off
        }

        setNotificationMode(nextMode, for: prayerTime)
        return nextMode
    }

    func shouldShowFilledBell(prayerTime: Prayer) -> Bool {
        notificationMode(for: prayerTime) == .preNotification
    }

    func shouldShowOutlinedBell(prayerTime: Prayer) -> Bool {
        notificationMode(for: prayerTime) == .atTime
    }

    // MARK: - Travel & automatic calculation (UI prompts)

    func automaticTravelMessage(turnOn: Bool) -> String {
        if turnOn {
            return "Al-Islam has automatically detected that you are traveling, so your prayers will be shortened."
        }
        return "Al-Islam has automatically detected that you are no longer traveling, so your prayers will not be shortened."
    }

    var automaticCalculationMessage: String {
        let country = calculationAutoDetectedCountryCode.isEmpty ? "unknown" : calculationAutoDetectedCountryCode
        return "Al-Islam detected your region as \(country) and switched prayer calculation from \(calculationAutoPreviousMethod) to \(calculationAutoDetectedMethod)."
    }

    func resetTravelAutomaticFlags() {
        travelTurnOnAutomatic = false
        travelTurnOffAutomatic = false
    }

    func overrideTravelingMode(keepOn: Bool) {
        travelingModeManuallyToggled = true
        withAnimation {
            travelingMode = keepOn
        }
        travelAutomatic = false
        resetTravelAutomaticFlags()
        fetchPrayerTimes(force: true)
    }

    func confirmTravelAutomaticChange() {
        resetTravelAutomaticFlags()
    }

    func overrideAutomaticCalculationKeepingPrevious() {
        calculationManuallyToggled = true
        withAnimation {
            prayerCalculation = calculationAutoPreviousMethod
        }
        calculationAutomatic = false
        calculationAutoChanged = false
        fetchPrayerTimes(force: true)
    }

    func confirmAutomaticCalculationChange() {
        calculationAutoChanged = false
    }
}
