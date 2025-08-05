import SwiftUI
import WidgetKit

struct Prayers2EntryView: View {
    @Environment(\.widgetFamily) var widgetFamily

    var entry: PrayersProvider.Entry

    func getPrayerColor(for prayer: Prayer, in prayers: [Prayer]) -> Color {
        guard let currentIndex = prayers.firstIndex(where: { $0.id == prayer.id }) else {
            return .secondary
        }

        guard let currentPrayerIndex = prayers.firstIndex(where: { $0.nameTransliteration == entry.currentPrayer?.nameTransliteration }) else {
            return .secondary
        }

        if currentIndex < currentPrayerIndex {
            return .secondary
        } else if currentIndex == currentPrayerIndex {
            return entry.accentColor.color
        } else {
            return .primary
        }
    }
    
    var hijriCalendar: Calendar = {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "ar")
        return calendar
    }()
    
    var hijriDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = hijriCalendar
        dateFormatter.dateStyle = .full
        dateFormatter.locale = Locale(identifier: "en")
        
        guard let offsetDate = hijriCalendar.date(byAdding: .day, value: entry.hijriOffset, to: Date()) else {
            return dateFormatter.string(from: Date())
        }
        
        return dateFormatter.string(from: offsetDate)
    }
    
    var body: some View {
        VStack {
            if entry.prayers.isEmpty {
                Text("Open app to get prayer times")
                    .foregroundColor(entry.accentColor.color)
            } else {
                if let currentPrayer = entry.currentPrayer, let nextPrayer = entry.nextPrayer {
                    HStack {
                        Image(systemName: currentPrayer.image)
                            .foregroundColor(entry.accentColor.color)
                        
                        Text(currentPrayer.nameTransliteration)
                            .foregroundColor(entry.accentColor.color)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            Text("Time left: \(nextPrayer.time, style: .timer)")
                                .font(.subheadline)
                                .frame(alignment: .trailing)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .font(.headline)
                    .padding(.vertical, 4)
                }
                
                Spacer()
                
                HStack {
                    let first3Prayers = Array(entry.prayers
                        .prefix(Int(floor(Double(
                            entry.prayers.count / 2
                        )))))
                    
                    VStack(spacing: 4) {
                        ForEach(first3Prayers) { prayer in
                            HStack {
                                Image(systemName: prayer.image)
                                    .frame(width: 10, alignment: .center)
                                
                                Text(prayer.nameTransliteration)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                
                                Spacer()
                                
                                Text(prayer.time, style: .time)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(getPrayerColor(for: prayer, in: entry.prayers))
                            .font(.caption)
                        }
                    }
                    
                    Divider()
                        .background(entry.accentColor.color)
                        .frame(height: 65)
                        .padding(.horizontal, 4)
                    
                    let last3Prayers = Array(entry.prayers
                        .suffix(Int(floor(Double(
                            entry.prayers.count / 2
                        )))))
                    
                    VStack(spacing: 4) {
                        ForEach(last3Prayers) { prayer in
                            HStack {
                                Image(systemName: prayer.image)
                                    .frame(width: 10, alignment: .center)
                                
                                Text(prayer.nameTransliteration)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                
                                Spacer()
                                
                                Text(prayer.time, style: .time)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(getPrayerColor(for: prayer, in: entry.prayers))
                            .font(.caption)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                
                Spacer()
                
                HStack {
                    if !entry.currentCity.isEmpty && !entry.currentCity.isEmpty {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(entry.accentColor.color)
                            .padding(.horizontal, 3)
                        
                        Text(entry.currentCity)
                            .font(.caption2)
                    }
                    
                    Spacer()
                    
                    Image("Al-Islam")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                        .cornerRadius(2)
                }
                .padding(.vertical, 4)
            }
        }
        .lineLimit(1)
    }
}

struct Prayers2Widget: Widget {
    let kind: String = "Prayers2Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            if #available(iOS 17.0, *) {
                Prayers2EntryView(entry: entry)
            } else {
                Prayers2EntryView(entry: entry)
                    .padding()
            }
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Prayer Times")
        .description("This widget displays the prayer times")
    }
}
