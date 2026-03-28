import SwiftUI
import CoreLocation

struct Location: Codable, Equatable {
    var city: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
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

    static func == (lhs: Prayer, rhs: Prayer) -> Bool {
        lhs.id == rhs.id
    }
}

struct HijriDate: Identifiable, Codable {
    var id: Date { date }

    let english: String
    let arabic: String
    let date: Date
}

extension Date {
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }

    func addingMinutes(_ minutes: Int) -> Date {
        addingTimeInterval(TimeInterval(minutes * 60))
    }
}

extension Character {
    var asciiDigitValue: UInt32? {
        guard let value = unicodeScalars.first?.value, (48...57).contains(value) else { return nil }
        return value - 48
    }
}

extension DateFormatter {
    private static func configuredTimeFormatter(localeIdentifier: String? = nil) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = .current

        if let localeIdentifier {
            formatter.locale = Locale(identifier: localeIdentifier)
        }

        return formatter
    }

    static let timeAR = configuredTimeFormatter(localeIdentifier: "ar")
    static let timeEN = configuredTimeFormatter()
}

extension Double {
    var stringRepresentation: String {
        String(format: "%.3f", self)
    }
}

extension CLLocationCoordinate2D {
    var stringRepresentation: String {
        let latitudeText = String(format: "%.3f", latitude)
        let longitudeText = String(format: "%.3f", longitude)
        return "(\(latitudeText), \(longitudeText))"
    }
}
