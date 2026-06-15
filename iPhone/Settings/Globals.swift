import SwiftUI

// MARK: - App identifiers
/// Central place for reverse-DNS strings and the App Group name.
/// When you change these, update `Resources/Entitlements-Main.entitlements`,
/// `Resources/Entitlements-Widget.entitlements`, and `Resources/Info-Main.plist` to match.
enum AppIdentifiers {
    static let appFullName = "Al-Islam | Islamic Pillars"
    static let appName = "Al-Islam"
    static let toolsView = "Al-Islam"
    
    static let mainColor = AccentColor.green
    static let mainColorString = "green"
    
    /// Shared App Group for `UserDefaults` / data (matches entitlements).
    static let appGroupSuiteName = "group.com.IslamicPillars.AppGroup"

    /// Main iOS bundle ID and OSLog subsystem prefix (matches `PRODUCT_BUNDLE_IDENTIFIER` for the app target).
    static let bundleIdentifier = "com.Quran.Elmallah.Islamic-Pillars"

    static let backgroundFetchPrayerTimesTaskIdentifier = "\(bundleIdentifier).fetchPrayerTimes"
    static let reciterDownloadsBackgroundSessionIdentifier = "\(bundleIdentifier).reciter-downloads"
    static let networkMonitorQueueLabel = "\(bundleIdentifier).NetworkMonitor"
    static let reciterDownloadDedupeQueueLabel = "\(bundleIdentifier).reciter-dedupe"
}

// MARK: - Quran widget shared data
/// Lightweight, fully-rendered payloads the main app writes to the App Group so the Quran widgets
/// can display instantly without loading Quran.json or the (async-loading) `QuranData` in the
/// extension. The app rebuilds this whenever last-read / last-listened state changes.
struct QuranWidgetSnapshot: Codable {
    /// A tajweed color span over the Arabic text, in UTF-16 offsets, with the color as 0–1 RGB. Plain
    /// `Codable` so it survives the App Group without serializing SwiftUI/UIKit color objects.
    struct ColorRun: Codable {
        let start: Int
        let length: Int
        let r: Double
        let g: Double
        let b: Double
    }

    struct AyahCard: Codable {
        let arabic: String
        let reference: String
        let english: String
        /// PostScript name of the Arabic font to render `arabic` with (e.g. the Uthmani font). Optional so
        /// older snapshots still decode.
        var fontName: String?
        /// Tajweed color spans over `arabic` (empty/nil when tajweed is off). Base text stays adaptive.
        var colorRuns: [ColorRun]?
    }
    struct ListenCard: Codable {
        let name: String
        let reciter: String
        let current: Double
        let full: Double
    }
    var lastRead: AyahCard?
    var lastListened: ListenCard?
    var randomPool: [AyahCard]

    init(lastRead: AyahCard? = nil, lastListened: ListenCard? = nil, randomPool: [AyahCard] = []) {
        self.lastRead = lastRead
        self.lastListened = lastListened
        self.randomPool = randomPool
    }
}

enum QuranWidgetStore {
    private static let key = "quranWidgetSnapshot"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName) }

    static func load() -> QuranWidgetSnapshot? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(QuranWidgetSnapshot.self, from: data)
    }

    static func save(_ snapshot: QuranWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: key)
    }
}

enum AppPerformance {
    static var isLowMemoryDevice: Bool {
        ProcessInfo.processInfo.physicalMemory < 3_000_000_000
    }

    static var shouldAvoidBroadPrewarm: Bool {
        #if os(watchOS)
        true
        #else
        isLowMemoryDevice
        #endif
    }

    static var ayahRowCacheLimit: Int {
        #if os(watchOS)
        900
        #else
        isLowMemoryDevice ? 1800 : 5000
        #endif
    }

    static var preparedSurahCacheLimit: Int {
        #if os(watchOS)
        24
        #else
        isLowMemoryDevice ? 60 : 160
        #endif
    }

    static var tajweedAttributedCacheLimit: Int {
        #if os(watchOS)
        180
        #else
        isLowMemoryDevice ? 700 : 1800
        #endif
    }

    static var cleanArabicCacheLimit: Int {
        #if os(watchOS)
        400
        #else
        isLowMemoryDevice ? 1500 : 4000
        #endif
    }

    static var prewarmArabicAyahLimit: Int? {
        #if os(watchOS)
        20
        #else
        isLowMemoryDevice ? 32 : nil
        #endif
    }
}

enum AccentColor: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }

    case red, orange, yellow, green, blue, indigo, cyan, teal, mint, purple, pink, brown

    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .indigo: return .indigo
        case .cyan: return .cyan
        case .teal: return .teal
        case .mint: return .mint
        case .purple: return .purple
        case .pink: return .pink
        case .brown: return .brown
        }
    }
}

let accentColors: [AccentColor] = AccentColor.allCases

struct CustomColorSchemeKey: EnvironmentKey {
    static let defaultValue: ColorScheme? = nil
}

extension EnvironmentValues {
    var customColorScheme: ColorScheme? {
        get { self[CustomColorSchemeKey.self] }
        set { self[CustomColorSchemeKey.self] = newValue }
    }
}

func arabicNumberString(from number: Int) -> String {
    let arabicNumbers = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
    return String(number).map { ch -> String in
        guard let digit = ch.wholeNumberValue, digit >= 0, digit <= 9 else { return String(ch) }
        return arabicNumbers[digit]
    }.joined()
}

private let quranStripScalars: Set<UnicodeScalar> = {
    var s = Set<UnicodeScalar>()

    // Tashkeel  U+064B…U+065F
    for v in 0x064B...0x065F { if let u = UnicodeScalar(v) { s.insert(u) } }

    // Quranic annotation signs  U+06D6…U+06ED
    for v in 0x06D6...0x06ED { if let u = UnicodeScalar(v) { s.insert(u) } }

    // Extras: short alif, madda, open taa marbuutah, dagger alif
    [0x0670, 0x0657, 0x0674, 0x0656].forEach { v in
        if let u = UnicodeScalar(v) { s.insert(u) }
    }

    return s
}()

extension String {
    var normalizingArabicIndicDigitsToWestern: String {
        let arabicIndicZero: UInt32 = 0x0660
        let easternArabicIndicZero: UInt32 = 0x06F0
        let asciiZero: UInt32 = 0x0030

        var out = String.UnicodeScalarView()
        out.reserveCapacity(unicodeScalars.count)

        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x0660...0x0669:
                let value = scalar.value - arabicIndicZero
                if let mapped = UnicodeScalar(asciiZero + value) {
                    out.append(mapped)
                } else {
                    out.append(scalar)
                }
            case 0x06F0...0x06F9:
                let value = scalar.value - easternArabicIndicZero
                if let mapped = UnicodeScalar(asciiZero + value) {
                    out.append(mapped)
                } else {
                    out.append(scalar)
                }
            default:
                out.append(scalar)
            }
        }

        return String(out)
    }

    var removingArabicDiacriticsAndSigns: String {
        var out = String.UnicodeScalarView()
        out.reserveCapacity(unicodeScalars.count)

        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x0671: // ٱ  hamzatul-wasl
                out.append(UnicodeScalar(0x0627)!)
            default:
                if !quranStripScalars.contains(scalar) { out.append(scalar) }
            }
        }
        return String(out)
    }

    var removingArabicSukoon: String {
        String(unicodeScalars.filter { $0.value != 0x0652 })
    }

    var removingSilentArabicLettersForSearch: String {
        var out = ""
        out.reserveCapacity(count)

        for cluster in self {
            let scalars = Array(String(cluster).unicodeScalars)
            guard let base = scalars.first(where: { (0x0621...0x064A).contains($0.value) || $0.value == 0x0671 }) else {
                out.append(cluster)
                continue
            }

            if base.value == 0x0671 {
                continue
            }

            let hasStandardSukoon = scalars.contains { $0.value == 0x0652 }
            let hasDaggerAlif = scalars.contains { $0.value == 0x0670 }
            let hasShadda = scalars.contains { $0.value == 0x0651 }
            let hasUthmaniSukoon = scalars.contains { $0.value == 0x06E1 }
            let hasArabicVowel = scalars.contains {
                $0.value == 0x064E || $0.value == 0x064F || $0.value == 0x0650 ||
                $0.value == 0x064B || $0.value == 0x064C || $0.value == 0x064D ||
                $0.value == 0x0656 || $0.value == 0x0657 || $0.value == 0x065A
            }

            switch base.value {
            case 0x0627, 0x0648, 0x064A, 0x0649:
                if hasStandardSukoon && !hasUthmaniSukoon {
                    continue
                }
            case 0x0644:
                if hasStandardSukoon {
                    continue
                }
            default:
                break
            }

            if base.value == 0x0648, hasDaggerAlif, !hasArabicVowel, !hasShadda, !hasStandardSukoon, !hasUthmaniSukoon {
                continue
            }

            out.append(cluster)
        }

        return out
    }

    var removingArabicDots: String {
        let dotlessMap: [Character: Character] = [
            "أ": "ا", "إ": "ا", "ؤ": "ء", "ئ": "ء",
            "آ": "ا", "ٱ": "ا", "ى": "ى",
            "ب": "ٮ", "ت": "ٮ", "ث": "ٮ", "ن": "ٮ", "ي": "ى",
            "ج": "ح", "خ": "ح", "ذ": "د", "ز": "ر", "ش": "س", "ض": "ص",
            "ظ": "ط", "غ": "ع", "ف": "ڡ", "ق": "ٯ", "ة": "ه"
        ]
        return String(map { dotlessMap[$0] ?? $0 })
    }
    
    func removeDiacriticsFromLastLetter() -> String {
        guard !isEmpty else { return self }

        let shaddah = UnicodeScalar(0x0651)!
        let scalars = Array(unicodeScalars)
        var idx = scalars.count
        var trailingShaddahCount = 0
        var removedNonShaddah = false

        // Remove trailing Arabic marks from final letter cluster, but keep shaddah.
        while idx > 0, quranStripScalars.contains(scalars[idx - 1]) {
            if scalars[idx - 1] == shaddah {
                trailingShaddahCount += 1
            } else {
                removedNonShaddah = true
            }
            idx -= 1
        }

        guard removedNonShaddah else { return self }

        var out = String.UnicodeScalarView()
        out.reserveCapacity(idx + trailingShaddahCount)
        for scalar in scalars[0..<idx] { out.append(scalar) }
        for _ in 0..<trailingShaddahCount { out.append(shaddah) }
        return String(out)
    }

    subscript(_ r: Range<Int>) -> Substring {
        let lower = Swift.max(0, Swift.min(r.lowerBound, count))
        let upper = Swift.max(lower, Swift.min(r.upperBound, count))
        let start = index(startIndex, offsetBy: lower, limitedBy: endIndex) ?? endIndex
        let end = index(startIndex, offsetBy: upper, limitedBy: endIndex) ?? endIndex
        return self[start..<end]
    }
}
