import SwiftUI
import WidgetKit

struct RandomBookmarkedAyahWidget: Widget {
    let kind: String = "RandomBookmarkedAyahWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuranWidgetProvider(kind: .randomBookmarkedAyah)) { entry in
            QuranWidgetEntryView(entry: entry)
        }
        .supportedFamilies(quranWidgetFamilies())
        .configurationDisplayName("Random Bookmarked Ayah")
        .description("Shows a random ayah from your bookmarks")
    }
}
