import SwiftUI

// MARK: - App identifiers
/// Central place for reverse-DNS strings and the App Group name.
/// When you change these, update `Resources/Entitlements-Main.entitlements`,
/// `Resources/Entitlements-Widget.entitlements`, and `Resources/Info-Main.plist` to match.
enum AppIdentifiers {
    /// Shared App Group for `UserDefaults` / data (matches entitlements).
    static let appGroupSuiteName = "group.com.IslamicPillars.AppGroup"

    /// Main iOS bundle ID and OSLog subsystem prefix (matches `PRODUCT_BUNDLE_IDENTIFIER` for the app target).
    static let bundleIdentifier = "com.Quran.Elmallah.Islamic-Pillars"

    static let backgroundFetchPrayerTimesTaskIdentifier = "\(bundleIdentifier).fetchPrayerTimes"
    static let reciterDownloadsBackgroundSessionIdentifier = "\(bundleIdentifier).reciter-downloads"
    static let networkMonitorQueueLabel = "\(bundleIdentifier).NetworkMonitor"
    static let reciterDownloadDedupeQueueLabel = "\(bundleIdentifier).reciter-dedupe"
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
    return String(number).map { arabicNumbers[Int(String($0))!] }.joined()
}

private let quranStripScalars: Set<UnicodeScalar> = {
    var s = Set<UnicodeScalar>()

    // Tashkeel  U+064B…U+065F
    for v in 0x064B...0x065F { if let u = UnicodeScalar(v) { s.insert(u) } }

    // Quranic annotation signs  U+06D6…U+06ED
    for v in 0x06D6...0x06ED { if let u = UnicodeScalar(v) { s.insert(u) } }

    // Extras: short alif, madda, open ta-marbuta, dagger alif
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
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return self[start..<end]
    }
}
