import SwiftUI
import CoreLocation

struct Location: Codable, Equatable {
    var city: String
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}

struct Prayer: Identifiable, Codable, Equatable {
    var id = UUID()
    let nameArabic: String
    let nameTransliteration: String
    let nameEnglish: String
    let time: Date
    let image: String
    let rakah: String
    let sunnahBefore: String
    let sunnahAfter: String
    
    static func ==(lhs: Prayer, rhs: Prayer) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Prayers: Identifiable, Codable, Equatable {
    var id = UUID()
    let day: Date
    let city: String
    let prayers: [Prayer]
    let fullPrayers: [Prayer]
    var setNotification: Bool
}

struct HijriDate: Identifiable, Codable {
    var id: Date { date }
    
    let english: String
    let arabic: String
    let date: Date
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

struct ShareSettings: Equatable {
    var arabic = false
    var transliteration = false
    var translation = false
    var showFooter = false
}

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
    let numberString = String(number)
    
    var arabicNumberString = ""
    for character in numberString {
        if let digit = Int(String(character)) {
            arabicNumberString += arabicNumbers[digit]
        }
    }
    return arabicNumberString
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

    subscript(_ r: Range<Int>) -> Substring {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return self[start..<end]
    }
}

extension Date {
    func isSameDay(as date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, inSameDayAs: date)
    }
    
    func addingMinutes(_ minutes: Int) -> Date {
        self.addingTimeInterval(TimeInterval(minutes * 60))
    }
}

extension Double {
    var stringRepresentation: String {
        return String(format: "%.3f", self)
    }
}

extension CLLocationCoordinate2D {
    var stringRepresentation: String {
        let lat = String(format: "%.3f", self.latitude)
        let lon = String(format: "%.3f", self.longitude)
        return "(\(lat), \(lon))"
    }
}

extension Character {
    var asciiDigitValue: UInt32? {
        guard let v = unicodeScalars.first?.value, (48...57).contains(v) else { return nil }
        return v - 48        // '0' is 48
    }
}

extension DateFormatter {
    static let timeAR: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.locale    = Locale(identifier: "ar")
        f.timeZone  = .current
        return f
    }()

    static let timeEN: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.timeZone  = .current
        return f
    }()
}
