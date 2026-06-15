import SwiftUI
import WidgetKit

struct RandomAyahWidget: Widget {
    let kind: String = "RandomAyahWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuranWidgetProvider(kind: .randomAyah)) { entry in
            QuranWidgetEntryView(entry: entry)
        }
        .supportedFamilies(quranWidgetFamilies())
        .configurationDisplayName("Random Ayah")
        .description("Shows a safe random ayah from the Quran")
    }
}
