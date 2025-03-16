import SwiftUI
import WidgetKit

struct CountdownEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily

    var entry: PrayersProvider.Entry
    
    var hijriCalendar: Calendar = {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "ar")
        return calendar
    }()
    
    var hijriDate1: String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = hijriCalendar
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = Locale(identifier: "en")
        
        guard let offsetDate = hijriCalendar.date(byAdding: .day, value: entry.hijriOffset, to: Date()) else {
            return dateFormatter.string(from: Date())
        }
        
        return dateFormatter.string(from: offsetDate)
    }
    
    var hijriDate2: String {
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
                    if widgetFamily == .systemMedium {
                        Spacer()
                        
                        Text(hijriDate2)
                            .foregroundColor(entry.accentColor.color)
                            .font(.caption)
                        
                        Spacer()
                        
                        Divider()
                            .background(entry.accentColor.color)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                        
                        Spacer()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Image(systemName: currentPrayer.image)
                                        .font(.subheadline)
                                        .foregroundColor(currentPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                                    
                                    Text(currentPrayer.nameTransliteration)
                                        .font(.headline)
                                        .foregroundColor(currentPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                                    
                                    Spacer()
                                    
                                    Text("Time left: \(nextPrayer.time, style: .timer)")
                                        .font(.caption)
                                }
                                .padding(.leading, 6)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        
                        Spacer()
                    }
                    
                    if widgetFamily == .systemSmall {
                        VStack(alignment: .leading, spacing: 1) {
                            HStack {
                                Spacer()
                                
                                Text(hijriDate1)
                                    .foregroundColor(entry.accentColor.color)
                                    .font(.caption2)
                                
                                Spacer()
                            }
                            
                            Spacer()
                            
                            Divider()
                                .background(entry.accentColor.color)
                            
                            Spacer()
                            
                            HStack {
                                Image(systemName: currentPrayer.image)
                                    .font(.subheadline)
                                
                                Text(currentPrayer.nameTransliteration)
                                    .font(.headline)
                                    .padding(.leading, -2)
                            }
                            .foregroundColor(currentPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                            .padding(.bottom, -4)
                            
                            Spacer()
                            
                            HStack {
                                Text("Next:")
                                
                                Image(systemName: nextPrayer.image)
                                    .padding(.horizontal, -6)
                                
                                Text(nextPrayer.nameTransliteration)
                            }
                            .font(.caption2)
                            .foregroundColor(nextPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                            
                            Text("Starts at \(nextPrayer.time, style: .time)")
                                .font(.caption2)
                            
                            Text("Time left: \(nextPrayer.time, style: .timer)")
                                .font(.caption2)
                            
                            Spacer()
                            
                            if !entry.currentCity.isEmpty && !entry.currentCity.isEmpty {
                                Divider()
                                    .background(entry.accentColor.color)
                                
                                Spacer()
                            
                                HStack {
                                    Image(systemName: "location.fill")
                                        .font(.caption)
                                        .foregroundColor(entry.accentColor.color)
                                    
                                    Text(entry.currentCity)
                                        .font(.caption)
                                }
                            }
                        }
                    } else {
                        HStack {
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                HStack {
                                    Text("Starts at \(nextPrayer.time, style: .time)")
                                        .font(.caption)
                                    
                                    Text(nextPrayer.nameTransliteration)
                                        .font(.headline)
                                        .foregroundColor(nextPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                                    
                                    Image(systemName: nextPrayer.image)
                                        .font(.subheadline)
                                        .foregroundColor(nextPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        Spacer()
                        
                        Divider()
                            .background(entry.accentColor.color)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                        
                        Spacer()
                        
                        HStack {
                            if !entry.currentCity.isEmpty && !entry.currentCity.isEmpty {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundColor(entry.accentColor.color)
                                    .padding(.horizontal, 3)
                                
                                Text(entry.currentCity)
                                    .font(.caption)
                            }
                            
                            Spacer()
                            
                            Image("Al-Islam")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .cornerRadius(4)
                        }
                        .padding(.horizontal, 4)
                        
                        Spacer()
                    }
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }
}

struct CountdownWidget: Widget {
    let kind: String = "CountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            if #available(iOS 17.0, *) {
                CountdownEntryView(entry: entry)
            } else {
                CountdownEntryView(entry: entry)
                    .padding()
            }
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("Prayer Countdown")
        .description("This widget displays the upcoming prayer time")
    }
}
