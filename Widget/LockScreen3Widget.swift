import SwiftUI
import WidgetKit

struct LockScreen3EntryView: View {
    var entry: PrayersProvider.Entry

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            if entry.prayers.isEmpty {
                Text("Open app to get prayer times")
                    .font(.caption)
            } else {
                let first3Prayers = Array(entry.fullPrayers.prefix(3))

                ForEach(first3Prayers) { prayer in
                    HStack {
                        Image(systemName: prayer.image)
                            .font(.caption)
                            .padding(.trailing, -4)

                        if let currentPrayer = entry.currentPrayer, prayer.nameTransliteration == currentPrayer.nameTransliteration {
                            Text(prayer.nameTransliteration)
                                .fontWeight(.bold)
                        } else {
                            Text(prayer.nameTransliteration)
                        }
                        
                        Spacer()
                        
                        Text(prayer.time, style: .time)
                    }
                    .font(.subheadline)
                }
            }
        }
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
