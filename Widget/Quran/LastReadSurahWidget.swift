import SwiftUI
import WidgetKit

struct LastReadSurahWidget: Widget {
    let kind: String = "LastReadSurahWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuranWidgetProvider(kind: .lastReadSurah)) { entry in
            QuranWidgetEntryView(entry: entry)
        }
        .supportedFamilies(quranWidgetFamilies())
        .configurationDisplayName("Last Read Surah")
        .description("Shows the surah and ayah you last read")
    }
}
