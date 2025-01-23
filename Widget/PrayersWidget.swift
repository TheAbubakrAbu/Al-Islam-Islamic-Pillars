import SwiftUI
import WidgetKit

struct PrayersEntryView: View {
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
                if widgetFamily == .systemLarge {
                    Text(hijriDate)
                        .foregroundColor(entry.accentColor.color)
                        .font(.caption)
                        .padding(.vertical, 4)
                    
                    Spacer()
                    
                    Divider()
                        .background(entry.accentColor.color)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                }
                
                Spacer()
                
                if entry.prayers.count == 6 {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ], spacing: 12) {
                        ForEach(entry.prayers) { prayer in
                            VStack(alignment: .center) {
                                HStack {
                                    Image(systemName: prayer.image)
                                        .font(.subheadline)
                                        .foregroundColor(getPrayerColor(for: prayer, in: entry.prayers))
                                        .padding(.trailing, -5)
                                    
                                    Text(prayer.nameTransliteration)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(getPrayerColor(for: prayer, in: entry.prayers))
                                }
                                
                                Text(prayer.time, style: .time)
                                    .font(.subheadline)
                                    .foregroundColor(getPrayerColor(for: prayer, in: entry.prayers))
                            }
                        }
                    }
                    .padding(4)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ], spacing: 12) {
                        ForEach(entry.prayers) { prayer in
                            VStack(alignment: .center) {
                                HStack {
                                    Image(systemName: prayer.image)
                                        .font(.subheadline)
                                        .foregroundColor(getPrayerColor(for: prayer, in: entry.prayers))
                                        .padding(.trailing, -5)
                                    
                                    Text(prayer.nameTransliteration)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(getPrayerColor(for: prayer, in: entry.prayers))
                                }
                                
                                Text(prayer.time, style: .time)
                                    .font(.subheadline)
                                    .foregroundColor(getPrayerColor(for: prayer, in: entry.prayers))
                            }
                        }
                    }
                    .padding(4)
                }
                
                Spacer()
                
                if widgetFamily == .systemLarge {
                    Divider()
                        .background(entry.accentColor.color)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                    
                    Spacer()
                    
                    VStack {
                        if let currentPrayer = entry.currentPrayer, let nextPrayer = entry.nextPrayer {
                            VStack(alignment: .leading) {
                                HStack {
                                    Image(systemName: currentPrayer.image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 22, height: 22)
                                        .foregroundColor(currentPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                                    
                                    Text(currentPrayer.nameTransliteration)
                                        .font(.title3)
                                        .foregroundColor(currentPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                                    
                                    Spacer()
                                    
                                    Text("Time left: \(nextPrayer.time, style: .timer)")
                                        .font(.caption)
                                        .padding(.trailing, 2)
                                }
                                .padding(.leading, 4)
                            }
                            
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing) {
                                    HStack {
                                        Text("Starts at \(nextPrayer.time, style: .time)")
                                            .font(.caption)
                                        
                                        Text(nextPrayer.nameTransliteration)
                                            .font(.title3)
                                            .foregroundColor(nextPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                                        
                                        Image(systemName: nextPrayer.image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 22, height: 22)
                                            .foregroundColor(nextPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                                    }
                                    .padding(.top, -8)
                                }
                            }
                        }
                    }
                    .padding(4)
                    
                    Spacer()
                    
                    Divider()
                        .background(entry.accentColor.color)
                        .padding(.bottom, 2)
                        .padding(.horizontal, 4)
                    
                    HStack {
                        if !entry.currentCity.isEmpty && !entry.currentCity.isEmpty {
                            Image(systemName: "location.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 15, height: 15)
                                .foregroundColor(entry.accentColor.color)
                                .padding(.horizontal, 3)
                            
                            Text(entry.currentCity)
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        Image("Al-Islam")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .cornerRadius(4)
                    }
                    .padding(4)
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
}

struct PrayersWidget: Widget {
    let kind: String = "PrayersWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            if #available(iOS 17.0, *) {
                PrayersEntryView(entry: entry)
            } else {
                PrayersEntryView(entry: entry)
                    .padding()
            }
        }
        .supportedFamilies([.systemMedium, .systemLarge])
        .configurationDisplayName("Prayer Times")
        .description("This widget displays the prayer times")
    }
}
