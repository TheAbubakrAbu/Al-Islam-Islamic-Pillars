import SwiftUI
import WidgetKit

struct LockScreen3EntryView: View {
    var entry: PrayersProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if entry.prayers.isEmpty {
                Text("Open app to get prayer times")
            } else {
                let prayers = Array(entry.fullPrayers.prefix(3))
                
                ForEach(prayers) { prayer in
                    HStack {
                        Image(systemName: prayer.image)
                            .font(.caption)
                            .frame(width: 10, alignment: .center)
                        
                        Text(prayer.nameTransliteration)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text(prayer.time, style: .time)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(prayer.nameTransliteration == entry.currentPrayer?.nameTransliteration ? .primary : .secondary)
                }
            }
        }
        .font(.caption)
        .multilineTextAlignment(.leading)
        .lineLimit(1)
    }
}

struct LockScreen3Widget: Widget {
    let kind: String = "LockScreen3Widget"

    var body: some WidgetConfiguration {
        #if os(iOS)
        if #available(iOS 16, *) {
            return StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
                LockScreen3EntryView(entry: entry)
            }
            .supportedFamilies([.accessoryRectangular])
            .configurationDisplayName("First 3 Prayer Times")
            .description("Shows the first three prayer times of the day")
        } else {
            return StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
                LockScreen3EntryView(entry: entry)
            }
            .supportedFamilies([.systemSmall])
            .configurationDisplayName("First 3 Prayer Times")
            .description("Shows the first three prayer times of the day")
        }
        #endif
    }
}
