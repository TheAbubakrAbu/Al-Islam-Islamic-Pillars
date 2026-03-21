import SwiftUI

struct DateView: View {
    @EnvironmentObject private var settings: Settings

    @State private var sourceDate = Date()
    @State private var selectedTab: ConversionTab = .hijriToGregorian

    private let hijriCalendar: Calendar = {
        var cal = Calendar(identifier: .islamicUmmAlQura)
        cal.locale = Locale(identifier: "ar")
        return cal
    }()
    private let gregorianCalendar = Calendar(identifier: .gregorian)

    enum ConversionTab { case hijriToGregorian, gregorianToHijri }

    private static let hijriFormatterEn: DateFormatter = {
        let fmt = DateFormatter()
        var hijriCal = Calendar(identifier: .islamicUmmAlQura)
        hijriCal.locale = Locale(identifier: "ar")
        fmt.calendar = hijriCal
        fmt.locale = Locale(identifier: "en")
        fmt.dateFormat = "EEEE, d MMMM yyyy"
        return fmt
    }()
    private static let gregFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.dateFormat = "EEEE, d MMMM yyyy"
        return fmt
    }()

    private var convertedDate: Date { sourceDate }

    var body: some View {
        VStack {
            #if !os(watchOS)
            List {
                Section("SELECT DATE") {
                    datePickerSection
                    conversionPicker
                }

                Section("CONVERTED DATE") {
                    Text(formatted(convertedDate, using: selectedTab == .hijriToGregorian ? gregorianCalendar : hijriCalendar))
                        .bold()
                        .foregroundColor(settings.accentColor.color)
                }
            }
            #endif
        }
        .navigationTitle("Hijri Converter")
        .applyConditionalListStyle(defaultView: settings.defaultView)
    }

    @ViewBuilder
    private var datePickerSection: some View {
        let calendar = selectedTab == .hijriToGregorian ? hijriCalendar : gregorianCalendar
        let title = selectedTab == .hijriToGregorian ? "Select Hijri Date" : "Select Gregorian Date"
        VStack(alignment: .leading) {
            #if !os(watchOS)
            DatePicker(title, selection: $sourceDate.animation(.easeInOut), displayedComponents: .date)
                .environment(\.calendar, calendar)
                .datePickerStyle(.graphical)
                .frame(maxHeight: 400)
            #endif
        }
    }

    @ViewBuilder
    private var conversionPicker: some View {
        Picker("Conversion Type", selection: $selectedTab.animation(.easeInOut)) {
            Text("Hijri to Gregorian").tag(ConversionTab.hijriToGregorian)
            Text("Gregorian to Hijri").tag(ConversionTab.gregorianToHijri)
        }
        #if !os(watchOS)
        .pickerStyle(.segmented)
        #endif
    }

    private func formatted(_ date: Date, using calendar: Calendar) -> String {
        if calendar.identifier == .islamicUmmAlQura {
            return Self.hijriFormatterEn.string(from: date)
        } else {
            return Self.gregFormatter.string(from: date)
        }
    }
}
