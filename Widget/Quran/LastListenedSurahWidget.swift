import SwiftUI
import WidgetKit

struct LastListenedSurahWidget: Widget {
    let kind: String = "LastListenedSurahWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuranWidgetProvider(kind: .lastListenedSurah)) { entry in
            QuranWidgetEntryView(entry: entry)
        }
        .supportedFamilies(quranWidgetFamilies())
        .configurationDisplayName("Last Listened Surah")
        .description("Shows the last surah you listened to")
    }
}
