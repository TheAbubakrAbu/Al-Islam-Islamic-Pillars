import SwiftUI
import WidgetKit

struct PrayersEntryView: View {
    var entry: PrayersProvider.Entry
    
    var body: some View {
        VStack {
            if let nextPrayer = entry.nextPrayer {
                VStack {
                    Image(systemName: nextPrayer.image)
                        .foregroundColor(nextPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                    
                    Text(nextPrayer.time, style: .time)
                        .font(.caption)
                        .foregroundColor(nextPrayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color)
                }
            } else {
                Text("Open app")
                    .font(.caption)
                    .foregroundColor(entry.accentColor.color)
                    .multilineTextAlignment(.center)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
}

@main
struct Complication: Widget {
    let kind: String = "Complication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayersProvider()) { entry in
            PrayersEntryView(entry: entry)
        }
        .configurationDisplayName("Next Prayer")
    }
}
