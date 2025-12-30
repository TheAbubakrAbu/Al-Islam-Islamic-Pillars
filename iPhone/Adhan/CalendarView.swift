import SwiftUI

struct HijriCalendarView: View {
    @EnvironmentObject var settings: Settings
    
    @State private var nearestEventId: String = ""
    @State private var hijriYear = 1445
    @State private var hijriMonth = 1
    
    private let gregorianCalendar = Calendar(identifier: .gregorian)
    
    private static let monthSymbols = [
        "Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani",
        "Jumada al-Ula", "Jumada al-Thani", "Rajab", "Sha'ban",
        "Ramadan", "Shawwal", "Dhul Qi'dah", "Dhul Hijjah"
    ]
    
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d, yyyy"
        return f
    }()
    
    private func updateInformation() {
        let currentDate = Date()
        let components = settings.hijriCalendar.dateComponents([.year, .month], from: currentDate)
        hijriYear = components.year ?? 1445
        hijriMonth = components.month ?? 1
        settings.updateDates()
    }
    
    var body: some View {
        VStack {
            if let hijriDate = settings.hijriDate {
                Text(hijriDate.english)
                    .foregroundColor(settings.accentColor.color)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.vertical, 2)
                
                Text(hijriDate.arabic)
                    .foregroundColor(settings.accentColor.color)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 2)
            }
            
            ScrollViewReader { proxy in
                List {
                    Section(header: Text("IMPORTANT ISLAMIC DATES")) {
                        ForEach(settings.specialEvents, id: \.0) { event in
                            let date = settings.hijriCalendar.date(from: event.1)!
                            let dateInEnglish = Self.formatter.string(from: date)
                            let comps = event.1
                            let monthName = Self.monthSymbols[(comps.month ?? 1) - 1]
                            let hijriString = "\(comps.day ?? 1) \(monthName), \(String(comps.year ?? hijriYear)) AH"
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(event.0)
                                        .font(.headline)
                                        .foregroundColor(settings.accentColor.color)
                                    
                                    Text(event.2)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    Text(event.3)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(alignment: .trailing) {
                                    Text(hijriString)
                                        .font(.caption)
                                        .padding(.vertical, 2)
                                    Text(dateInEnglish)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 2)
                                }
                            }
                            .padding(.vertical, 4)
                            .id(event.0)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = event.0
                                } label: {
                                    Label("Copy Event Name", systemImage: "doc.on.doc")
                                }
                                
                                Button {
                                    UIPasteboard.general.string = event.2
                                } label: {
                                    Label("Copy Event Subtitle", systemImage: "doc.on.doc")
                                }
                                
                                Button {
                                    UIPasteboard.general.string = event.3
                                } label: {
                                    Label("Copy Event Description", systemImage: "doc.on.doc")
                                }
                                
                                Button {
                                    UIPasteboard.general.string = hijriString
                                } label: {
                                    Label("Copy Hijri Date", systemImage: "doc.on.doc")
                                }
                                
                                Button {
                                    UIPasteboard.general.string = dateInEnglish
                                } label: {
                                    Label("Copy Gregorian Date", systemImage: "doc.on.doc")
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    updateInformation()
                    
                    let now = Date()
                    if let nearest = settings.specialEvents.min(by: {
                        let d0 = settings.hijriCalendar.date(from: $0.1)!.timeIntervalSince(now)
                        let d1 = settings.hijriCalendar.date(from: $1.1)!.timeIntervalSince(now)
                        return abs(d0) < abs(d1)
                    }) {
                        nearestEventId = nearest.0
                    }
                    DispatchQueue.main.async {
                        withAnimation {
                            proxy.scrollTo(nearestEventId, anchor: .top)
                        }
                    }
                }
                .applyConditionalListStyle(defaultView: settings.defaultView)
                .navigationTitle("Hijri Calendar")
            }
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    HijriCalendarView()
        .environmentObject(Settings.shared)
}
