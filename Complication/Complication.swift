import SwiftUI
import WidgetKit

struct PrayersEntryView: View {
    var entry: PrayersProvider.Entry
    @Environment(\.widgetFamily) private var family
    
    func accent(for prayer: Prayer) -> Color {
        prayer.nameTransliteration == "Shurooq" ? .primary : entry.accentColor.color
    }

    var body: some View {
        switch family {
        case .accessoryRectangular:
            rectangular
        default:
            circular
        }
    }
    
    var circular: some View {
        VStack(spacing: 4) {
            if let nextPrayer = entry.nextPrayer {
                Image(systemName: nextPrayer.image)
                    .foregroundColor(accent(for: nextPrayer))

                Text(nextPrayer.time, style: .time)
                    .font(.caption2)
                    .foregroundColor(accent(for: nextPrayer))
            } else {
                Text("Open app")
                    .font(.caption2)
                    .foregroundColor(entry.accentColor.color)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }

    var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            if entry.prayers.isEmpty {
                Text("Open app to get prayer times")
                    .font(.caption)
            } else if let currentPrayer = entry.currentPrayer, let nextPrayer = entry.nextPrayer {
                HStack {
                    if entry.prayers.count == 6 {
                        Image(systemName: currentPrayer.image)
                            .font(.body)
                            .padding(.trailing, -4)
                    }
                    
                    Text(currentPrayer.nameTransliteration)
                        .font(.headline)
                    
                    Text("\(nextPrayer.time, style: .timer)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .foregroundColor(accent(for: currentPrayer))
                    
                Text("\(nextPrayer.nameTransliteration) at \(nextPrayer.time, style: .time)")
                    .font(.subheadline)
                
                HStack {
                    Image(systemName: "location.fill")
                        .padding(.trailing, -4)
                    
                    Text(entry.currentCity)
                }
                .font(.caption)
            }
        }
        .multilineTextAlignment(.leading)
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
        .supportedFamilies([
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}
