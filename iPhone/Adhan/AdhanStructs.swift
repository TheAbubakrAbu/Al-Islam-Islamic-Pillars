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
    
    static func ==(lhs: Prayer, rhs: Prayer) -> Bool {
        return lhs.id == rhs.id
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
        let calendar = Calendar.current
        return calendar.isDate(self, inSameDayAs: date)
    }
    
    func addingMinutes(_ minutes: Int) -> Date {
        self.addingTimeInterval(TimeInterval(minutes * 60))
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
