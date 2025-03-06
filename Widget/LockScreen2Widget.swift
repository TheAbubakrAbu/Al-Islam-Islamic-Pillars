import SwiftUI
import WidgetKit

struct LockScreen2EntryView: View {
    var entry: PrayersProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if entry.prayers.isEmpty {
                Text("Open app to get prayer times")
                    .font(.caption)
            } else if let currentPrayer = entry.currentPrayer, let nextPrayer = entry.nextPrayer {
                HStack {
                    Image(systemName: currentPrayer.image)
                        .font(.caption)
                        .padding(.trailing, -4)
                    
                    Text(currentPrayer.nameTransliteration)
                        .font(.headline)
                }
                
                Text("Time left: \(nextPrayer.time, style: .timer)")
                    .font(.caption)
                
                Text("\(nextPrayer.nameTransliteration) at \(nextPrayer.time, style: .time)")
                    .font(.caption)
            }
        }
        .multilineTextAlignment(.leading)
        .lineLimit(1)
    }
}

struct LockScreen2Widget: Widget {
    let kind: String = "LockScreen2Widget"

    var body: some WidgetConfiguration {
        #if os(iOS)
        if #available(iOS 16, *) {
            return StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
                LockScreen2EntryView(entry: entry)
            }
            .supportedFamilies([.accessoryRectangular])
            .configurationDisplayName("Prayer Times")
            .description("Shows the current prayer and the time remaining until the next prayer")
        } else {
            return StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
                LockScreen2EntryView(entry: entry)
            }
            .supportedFamilies([.systemSmall])
            .configurationDisplayName("Prayer Times")
            .description("Shows the current prayer and the time remaining until the next prayer")
        }
        #endif
    }
}
