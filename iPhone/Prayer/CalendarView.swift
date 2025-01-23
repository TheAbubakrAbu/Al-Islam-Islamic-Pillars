import SwiftUI

struct HijriCalendarView: View {
    @EnvironmentObject var settings: Settings
    
    @State var nearestEventId: String = ""
    @State var hijriYear = 1445
    @State var hijriMonth = 1
    
    var hijriCalendar: Calendar = {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "ar")
        return calendar
    }()

    let gregorianCalendar = Calendar(identifier: .gregorian)

    var monthSymbols = ["Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani", "Jumada al-Ula", "Jumada al-Thani", "Rajab", "Sha'ban", "Ramadan", "Shawwal", "Dhul Qi'dah", "Dhul Hijjah"]
    
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()
    
    func updateInformation() {
        let currentDate = Date()
        let components = hijriCalendar.dateComponents([.year, .month], from: currentDate)
        hijriYear = components.year ?? 1445
        hijriMonth = components.month ?? 1
        
        settings.updateDates()
    }

    var body: some View {
        NavigationView {
            VStack {
                if let hijriDate = settings.hijriDate {
                    Text(hijriDate.english)
                        .foregroundColor(settings.accentColor.color)
                        .font(.title2)
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.vertical, 2)
                    
                    Text(hijriDate.arabic)
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 2)
                }
                
                ScrollViewReader { proxy in
                    List {
                        Section(header: Text("IMPORTANT ISLAMIC DATES")) {
                            ForEach(settings.specialEvents, id: \.0) { event in
                                let date = hijriCalendar.date(from: event.1)!
                                let dateInEnglish = formatter.string(from: date)
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(event.0)
                                            .font(.headline)
                                            .lineLimit(nil)
                                            .multilineTextAlignment(.leading)
                                            .foregroundColor(settings.accentColor.color)
                                        
                                        Text(event.2)
                                            .font(.subheadline)
                                            .lineLimit(nil)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("\(event.1.day!) \(monthSymbols[event.1.month! - 1]), \(String(event.1.year!)) AH")
                                            .font(.caption)
                                            .lineLimit(nil)
                                            .multilineTextAlignment(.trailing)
                                            .padding(.vertical, 2)
                                        Text(dateInEnglish)
                                            .font(.caption)
                                            .lineLimit(nil)
                                            .multilineTextAlignment(.trailing)
                                            .foregroundColor(.secondary)
                                            .padding(.bottom, 2)
                                    }
                                }
                                .padding(.vertical, 4)
                                .id(event.0)
                                .onAppear {
                                    if event.0 == nearestEventId {
                                        withAnimation {
                                            proxy.scrollTo(nearestEventId, anchor: .top)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .onAppear {
                        let now = Date()
                        if let nearestEvent = settings.specialEvents.min(by: { abs(hijriCalendar.date(from: $0.1)!.timeIntervalSince(now)) < abs(hijriCalendar.date(from: $1.1)!.timeIntervalSince(now)) }) {
                            nearestEventId = nearestEvent.0
                        }
                        updateInformation()
                    }
                    .applyConditionalListStyle(defaultView: settings.defaultView)
                }
                
                Spacer()
            }
        }
        .navigationViewStyle(.stack)
        .navigationTitle("Hijri Calendar")
    }
}
