import SwiftUI
import os
import Adhan
import CoreLocation

let logger = Logger(subsystem: AppIdentifiers.bundleIdentifier, category: "Settings")

final class Settings: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = Settings()
    private let appGroupUserDefaults = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)

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
        Self.locationManager.delegate = self
        requestLocationAuthorization()

        runQuranStartupMigrations()
    }

    // MARK: - App group — shared with widgets / extensions

    @Published var accentColor: AccentColor {
        didSet {
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
            appGroupUserDefaults?.setValue(accentColor.rawValue, forKey: "accentColor")
        }
    }

    @Published var prayersData: Data {
        didSet {
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
            if !prayersData.isEmpty {
                appGroupUserDefaults?.setValue(prayersData, forKey: "prayersData")
            }
        }
    }

    var prayers: Prayers? {
        get {
            try? Self.decoder.decode(Prayers.self, from: prayersData)
        }
        set {
            prayersData = (try? Self.encoder.encode(newValue)) ?? Data()
        }
    }

    @Published var travelingMode: Bool {
        didSet {
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
            appGroupUserDefaults?.setValue(travelingMode, forKey: "travelingMode")
        }
    }

    @Published var currentLocation: Location? {
        didSet {
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
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
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
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
        didSet {
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
            appGroupUserDefaults?.setValue(hanafiMadhab, forKey: "hanafiMadhab")
        }
    }

    @Published var prayerCalculation: String {
        didSet {
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
            appGroupUserDefaults?.setValue(prayerCalculation, forKey: "prayerCalculation")
        }
    }

    @Published var hijriOffset: Int {
        didSet {
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
            appGroupUserDefaults?.setValue(hijriOffset, forKey: "hijriOffset")
        }
    }

    // MARK: - Prayer — live state & hijri (app-storage persistence)

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

    @Published var datePrayers: [Prayer]?
    @Published var dateFullPrayers: [Prayer]?
    @Published var changedDate = false

    var hijriCalendar: Calendar = {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "ar")
        return calendar
    }()

    var specialEvents: [(String, DateComponents, String, String)] {
        let currentHijriYear = hijriCalendar.component(.year, from: effectiveHijriReferenceDate())
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

    @AppStorage("lastScheduledHijriYear") private var lastScheduledHijriYear: Int = 0

    // MARK: - Prayer — @AppStorage (notifications, travel, calculation, alerts)

    @AppStorage("dateNotifications") var dateNotifications = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }

    @AppStorage("switchHijriDateAtMaghrib") var switchHijriDateAtMaghrib: Bool = false {
        didSet { self.updateDates() }
    }

    @AppStorage("naggingMode") var naggingMode: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingStartOffset") var naggingStartOffset: Int = 30 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("adhanNotificationSound") var adhanNotificationSound: String = "egypt-30" {
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

    @AppStorage("travelAutomatic") var travelAutomatic: Bool = true
    @AppStorage("travelTurnOffAutomatic") var travelTurnOffAutomatic: Bool = false
    @AppStorage("travelTurnOnAutomatic") var travelTurnOnAutomatic: Bool = false
    /// Set by the UI when the user toggles Traveling Mode; fetchPrayerTimes skips checkIfTraveling once so we don’t override or notify.
    var travelingModeManuallyToggled: Bool = false

    @AppStorage("calculationAutomatic") var calculationAutomatic: Bool = true
    @AppStorage("calculationAutoChanged") var calculationAutoChanged: Bool = false
    @AppStorage("calculationAutoPreviousMethod") var calculationAutoPreviousMethod: String = ""
    @AppStorage("calculationAutoDetectedMethod") var calculationAutoDetectedMethod: String = ""
    @AppStorage("calculationAutoDetectedCountryCode") var calculationAutoDetectedCountryCode: String = ""
    @AppStorage("currentCountryCode") var currentCountryCode: String = ""
    /// Set by the UI when the user manually picks a method while automatic mode is enabled.
    var calculationManuallyToggled: Bool = false

    @AppStorage("showLocationAlert") var showLocationAlert: Bool = false {
        willSet { objectWillChange.send() }
    }
    @AppStorage("showNotificationAlert") var showNotificationAlert: Bool = false

    @AppStorage("locationNeverAskAgain") var locationNeverAskAgain = false
    @AppStorage("notificationNeverAskAgain") var notificationNeverAskAgain = false

    @AppStorage("showPrayerInfo") var showPrayerInfo: Bool = false

    // MARK: - Quran — @AppStorage
    
    static let randomReciterName = "Random Reciter"
    
    @AppStorage("reciter") var reciter: String = "Muhammad Al-Minshawi (Murattal)"

    /// Disambiguates reciters that share the same display name (qiraah / surah base URL).
    @AppStorage("reciterId") var reciterId: String = ""

    @AppStorage("favoriteReciterIDsData") private var favoriteReciterIDsData = Data()
    var favoriteReciterIDs: [String] {
        get {
            (try? Self.decoder.decode([String].self, from: favoriteReciterIDsData)) ?? []
        }
        set {
            let normalized = Array(NSOrderedSet(array: newValue.compactMap {
                let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            })) as? [String] ?? []
            favoriteReciterIDsData = (try? Self.encoder.encode(normalized)) ?? Data()
        }
    }

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

    @AppStorage("favoriteNameNumbersData") private var favoriteNameNumbersData = Data()
    var favoriteNameNumbers: [Int] {
        get {
            (try? Self.decoder.decode([Int].self, from: favoriteNameNumbersData)) ?? []
        }
        set {
            favoriteNameNumbersData = (try? Self.encoder.encode(newValue)) ?? Data()
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

    @AppStorage("showBookmarks") var showBookmarks = true
    @AppStorage("showFavorites") var showFavorites = true

    @AppStorage("shareShowAyahInformation") var showAyahInformation: Bool = true
    @AppStorage("shareShowSurahInformation") var showSurahInformation: Bool = false

    @AppStorage("beginnerMode") var beginnerMode: Bool = false

    enum QuranSortMode: String, CaseIterable, Identifiable {
        case surah
        case juz
        case page
        case revelation

        var id: String { rawValue }
    }

    @AppStorage("quranSortMode") var quranSortModeRaw: String = QuranSortMode.surah.rawValue

    var quranSortMode: QuranSortMode {
        get { QuranSortMode(rawValue: quranSortModeRaw) ?? .surah }
        set { quranSortModeRaw = newValue.rawValue }
    }

    var groupBySurah: Bool { quranSortMode == .surah }
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

    enum Riwayah {
        static let hafsTag = ""
        static let hafsLabel = "Hafs an Asim (default)"

        static let shubah = "Shubah an Asim"
        static let khalaf = "Khalaf an Hamzah"
        static let buzzi = "al-Bazzi an Ibn Kathir"
        static let qunbul = "Qunbul an Ibn Kathir"
        static let warsh = "Warsh an Nafi"
        static let qaloon = "Qalun an Nafi"
        static let duri = "ad-Duri an Abi Amr"
        static let susi = "as-Susi an Abi Amr"

        static let warshArabic = "ورش عن نافع"
        static let qaloonArabic = "قالون عن نافع"
        static let duriArabic = "الدوري عن أبي عمرو"
        static let susiArabic = "السوسي عن أبي عمرو"
        static let buzziArabic = "البزي عن ابن كثير"
        static let qunbulArabic = "قنبل عن ابن كثير"
        static let shubahArabic = "شعبة عن عاصم"
        static let khalafArabic = "خلف عن حمزة"

        static let menuOptions: [(label: String, tag: String)] = [
            (hafsLabel, hafsTag),
            (shubah, shubah),
            (buzzi, buzzi),
            (qunbul, qunbul),
            (warsh, warsh),
            (qaloon, qaloon),
            (duri, duri),
            (susi, susi),
        ]

        static let arabicCaptionByTag: [String: String] = [
            hafsTag: "حفص عن عاصم",
            warsh: warshArabic,
            qaloon: qaloonArabic,
            duri: duriArabic,
            susi: susiArabic,
            buzzi: buzziArabic,
            qunbul: qunbulArabic,
            shubah: shubahArabic,
            khalaf: khalafArabic,
        ]

        static func canonicalTag(_ stored: String) -> String {
            let raw = stored.trimmingCharacters(in: .whitespacesAndNewlines)
            switch raw {
            case "", "Hafs", "Hafs an Asim", hafsLabel: return hafsTag
            case warsh, "Warsh An Nafi": return warsh
            case qaloon, "Qaloon an Nafi", "Qaloon An Nafi": return qaloon
            case duri, "Ad-Duri an Abi Amr": return duri
            case susi, "As-Susi an Abi Amr": return susi
            case buzzi, "Al-Buzzi an Ibn Kathir": return buzzi
            case qunbul, "Qumbul an Ibn Kathir": return qunbul
            case shubah, "Shu'bah an Asim", "Shu'bah an Aasim", "Shouba an Asim": return shubah
            case khalaf: return khalaf
            default: return raw
            }
        }
    }

    /// Which qiraah/riwayah to show for Arabic text. Empty or "Hafs" = Hafs an Asim (default). Transliteration and translations only apply to Hafs.
    @AppStorage("displayQiraah") var displayQiraah: String = ""

    /// When on, AyahsView shows a qiraat picker above the search bar to compare riwayat in that view.
    @AppStorage("qiraatComparisonMode") var qiraatComparisonMode: Bool = false

    /// When on, ReciterListView reveals non-Hafs qiraat reciters.
    @AppStorage("showOtherQiraatReciters") var showOtherQiraatReciters: Bool = false

    /// Shared expand/collapse state for qiraah details in Quran settings and reciter lists.
    var showQiraahDetails: Bool {
        get { showOtherQiraatReciters }
        set { showOtherQiraatReciters = newValue }
    }

    /// Pass to Ayah.displayArabic(qiraah:clean:). Nil means Hafs.
    var displayQiraahForArabic: String? {
        (displayQiraah.isEmpty || displayQiraah == "Hafs") ? nil : displayQiraah
    }

    /// When false, only Arabic is shown (no transliteration or English), since those are for Hafs an Asim only.
    var isHafsDisplay: Bool {
        displayQiraah.isEmpty || displayQiraah == "Hafs"
    }

    /// Arabic riwayah line for settings section headers (matches on-screen Arabic text riwayah).
    var displayQiraahArabicCaption: String {
        let key = Self.normalizeLegacyRiwayahTag(displayQiraah)
        return Self.Riwayah.arabicCaptionByTag[key] ?? Self.Riwayah.arabicCaptionByTag[Self.Riwayah.hafsTag]!
    }

    @AppStorage("showArabicText") var showArabicText: Bool = true
    @AppStorage("showTajweedColors") var showTajweedColors: Bool = false
    @AppStorage("showTajweedTafkhim") var showTajweedTafkhim: Bool = true
    @AppStorage("showTajweedQalqalah") var showTajweedQalqalah: Bool = true
    @AppStorage("showTajweedLamShamsiyah") var showTajweedLamShamsiyah: Bool = true
    @AppStorage("showTajweedSukoonJazm") var showTajweedDroppedLetter: Bool = true
    @AppStorage("showTajweedBareNuunMeem") var showTajweedIdghamBiGhunnahLight: Bool = true
    @AppStorage("showTajweedIdghamBiGhunnahHeavy") var showTajweedIdghamBiGhunnahHeavy: Bool = true
    @AppStorage("showTajweedIkhfaa") var showTajweedIkhfaa: Bool = true
    @AppStorage("showTajweedIqlab") var showTajweedIqlab: Bool = true
    @AppStorage("showTajweedIdghamBilaGhunnah") var showTajweedIdghamBilaGhunnah: Bool = true
    @AppStorage("showTajweedHamzatWaslSilent") var showTajweedHamzatWaslSilent: Bool = true
    @AppStorage("showTajweedMaddNatural2") var showTajweedMaddNatural2: Bool = true
    @AppStorage("showTajweedMadd246") var showTajweedMaddAaridLisSukoon: Bool = true
    @AppStorage("showTajweedMaddNecessary6") var showTajweedMaddNecessary6: Bool = true
    @AppStorage("showTajweedMaddSeparated") var showTajweedMaddSeparated: Bool = true
    @AppStorage("showTajweedMaddConnected") var showTajweedMaddConnected: Bool = true
    @AppStorage("cleanArabicText") var cleanArabicText: Bool = false
    @AppStorage("THEfontArabic") var fontArabic: String = "KFGQPCQUMBULUthmanicScript-Regu"
    @AppStorage("fontArabicSize") var fontArabicSize: Double = Double(UIFont.preferredFont(forTextStyle: .title1).pointSize)

    @AppStorage("useFontArabic") var useFontArabic = true

    @AppStorage("showTransliteration") var showTransliteration: Bool = false
    @AppStorage("showEnglishSaheeh") var showEnglishSaheeh: Bool = true
    @AppStorage("showEnglishMustafa") var showEnglishMustafa: Bool = false
    @AppStorage("showPageJuzDividers") var showPageJuzDividers: Bool = true
    @AppStorage("showPageJuzOverlay") var showPageJuzOverlay: Bool = false

    @AppStorage("quranSearchHistoryData") private var quranSearchHistoryData = Data()
    var quranSearchHistory: [String] {
        get {
            (try? Self.decoder.decode([String].self, from: quranSearchHistoryData)) ?? []
        }
        set {
            quranSearchHistoryData = (try? Self.encoder.encode(Array(newValue.prefix(10)))) ?? Data()
        }
    }

    @AppStorage("englishFontSize") var englishFontSize: Double = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)

    // MARK: - Arabic letters & 99 Names

    @AppStorage("favoriteLetterData") private var favoriteLetterData = Data()
    var favoriteLetters: [LetterData] {
        get {
            (try? Self.decoder.decode([LetterData].self, from: favoriteLetterData)) ?? []
        }
        set {
            favoriteLetterData = (try? Self.encoder.encode(newValue)) ?? Data()
        }
    }

    @AppStorage("showDescription") var showDescription = false
    
    // MARK: - App-wide appearance & misc @AppStorage

    @AppStorage("THEfirstLaunch") var firstLaunch = true

    @AppStorage("hapticOn") var hapticOn: Bool = true

    @AppStorage("defaultView") var defaultView: Bool = true

    @AppStorage("colorSchemeString") var colorSchemeString: String = "system"
    var colorScheme: ColorScheme? {
        get {
            colorSchemeFromString(colorSchemeString)
        }
        set {
            colorSchemeString = colorSchemeToString(newValue)
        }
    }

    // MARK: - Global helpers (not Quran- or Adhan-specific)

    func hapticFeedback() {
        #if os(iOS)
        if hapticOn { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        #endif

        #if os(watchOS)
        if hapticOn { WKInterfaceDevice.current().play(.click) }
        #endif
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

    func toggleLetterFavorite(letterData: LetterData) {
        withAnimation {
            if isLetterFavorite(letterData: letterData) {
                favoriteLetters.removeAll(where: { $0.id == letterData.id })
            } else {
                favoriteLetters.append(letterData)
            }
        }
    }

    func toggleReciterFavorite(reciterID: String) {
        let trimmed = reciterID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        withAnimation {
            if isReciterFavorite(reciterID: trimmed) {
                favoriteReciterIDs.removeAll(where: { $0 == trimmed })
            } else {
                favoriteReciterIDs.append(trimmed)
            }
        }
    }

    func isReciterFavorite(reciterID: String) -> Bool {
        let trimmed = reciterID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return favoriteReciterIDs.contains(trimmed)
    }

    func isLetterFavorite(letterData: LetterData) -> Bool {
        favoriteLetters.contains { $0.id == letterData.id }
    }
}
