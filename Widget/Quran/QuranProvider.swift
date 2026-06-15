import SwiftUI
import WidgetKit

enum QuranWidgetKind {
    case lastReadAyah
    case lastListenedSurah
    case randomAyah

    var title: String {
        switch self {
        case .lastReadAyah: return "Last Read Ayah"
        case .lastListenedSurah: return "Last Listened Surah"
        case .randomAyah: return "Random Ayah"
        }
    }

    var icon: String {
        switch self {
        case .lastReadAyah: return "book.closed"
        case .lastListenedSurah: return "play.fill"
        case .randomAyah: return "sparkles"
        }
    }
}

struct QuranWidgetEntry: TimelineEntry {
    let date: Date
    let kind: QuranWidgetKind
    let title: String
    let icon: String
    let primaryText: String
    let secondaryText: String?
    let tertiaryText: String?
    let accentColor: AccentColor
    let fallbackText: String?
    /// When set, `primaryText` is Arabic and should render with this font (e.g. the Uthmani font).
    var arabicFontName: String? = nil
}

struct QuranWidgetProvider: TimelineProvider {
    let kind: QuranWidgetKind

    func placeholder(in context: Context) -> QuranWidgetEntry { makeEntry() }

    func getSnapshot(in context: Context, completion: @escaping (QuranWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuranWidgetEntry>) -> Void) {
        let entry = makeEntry()
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60))))
    }

    private func makeEntry() -> QuranWidgetEntry {
        let settings = Settings.shared
        let snapshot = QuranWidgetStore.load()

        switch kind {
        case .lastReadAyah:
            return makeAyahEntry(settings: settings, card: snapshot?.lastRead,
                                 emptyMessage: "Open the app to set your last read verse.")
        case .lastListenedSurah:
            return makeLastListenedEntry(settings: settings, card: snapshot?.lastListened)
        case .randomAyah:
            return makeAyahEntry(settings: settings, card: randomCard(from: snapshot),
                                 emptyMessage: "Open the app to load random ayahs.")
        }
    }

    private func makeAyahEntry(settings: Settings, card: QuranWidgetSnapshot.AyahCard?, emptyMessage: String) -> QuranWidgetEntry {
        guard let card else {
            return fallbackEntry(settings: settings, message: emptyMessage)
        }
        return QuranWidgetEntry(
            date: Date(),
            kind: kind,
            title: kind.title,
            icon: kind.icon,
            primaryText: card.arabic,
            secondaryText: card.reference,
            tertiaryText: snippet(card.english),
            accentColor: settings.accentColor,
            fallbackText: nil,
            arabicFontName: card.fontName
        )
    }

    private func makeLastListenedEntry(settings: Settings, card: QuranWidgetSnapshot.ListenCard?) -> QuranWidgetEntry {
        guard let card else {
            return fallbackEntry(settings: settings, message: "Open the app to resume your last listened surah.")
        }
        return QuranWidgetEntry(
            date: Date(),
            kind: .lastListenedSurah,
            title: kind.title,
            icon: kind.icon,
            primaryText: card.name,
            secondaryText: card.reciter,
            tertiaryText: "\(formatDurationMMSS(card.current)) / \(formatDurationMMSS(card.full))",
            accentColor: settings.accentColor,
            fallbackText: nil
        )
    }

    /// Rotates through the app-provided pool so the widget shows a different ayah over time
    /// (deterministic per half-hour bucket, matching the timeline refresh cadence).
    private func randomCard(from snapshot: QuranWidgetSnapshot?) -> QuranWidgetSnapshot.AyahCard? {
        guard let pool = snapshot?.randomPool, !pool.isEmpty else { return nil }
        let bucket = Int(Date().timeIntervalSince1970 / (30 * 60))
        return pool[((bucket % pool.count) + pool.count) % pool.count]
    }

    private func fallbackEntry(settings: Settings, message: String) -> QuranWidgetEntry {
        QuranWidgetEntry(
            date: Date(),
            kind: kind,
            title: kind.title,
            icon: kind.icon,
            primaryText: message,
            secondaryText: nil,
            tertiaryText: nil,
            accentColor: settings.accentColor,
            fallbackText: message
        )
    }

    private func snippet(_ text: String, maxLength: Int = 90) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxLength else { return trimmed }
        let idx = trimmed.index(trimmed.startIndex, offsetBy: maxLength)
        return String(trimmed[..<idx]).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    private func formatDurationMMSS(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct QuranWidgetEntryView: View {
    @Environment(\.widgetFamily) private var widgetFamily

    let entry: QuranWidgetEntry

    private var isAccessoryRectangularFamily: Bool {
        #if os(iOS)
        if #available(iOSApplicationExtension 16.0, *) {
            return widgetFamily == .accessoryRectangular
        }
        #endif
        return false
    }

    /// On iOS 17+ the system applies default content margins (like the Adhan widgets), so we add no extra
    /// padding; on older iOS we pad manually.
    private var contentPadding: CGFloat {
        if isAccessoryRectangularFamily { return 0 }
        if #available(iOSApplicationExtension 17.0, *) { return 0 }
        return 14
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header

            if let fallbackText = entry.fallbackText {
                Text(fallbackText)
                    .font(isAccessoryRectangularFamily ? .caption2 : .caption)
                    .foregroundColor(.secondary)
                    .lineLimit(isAccessoryRectangularFamily ? 2 : 4)
            } else if isAccessoryRectangularFamily {
                accessoryBody
            } else {
                regularBody
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(contentPadding)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: entry.icon)
                .font(.caption.weight(.semibold))
            Text(entry.title)
                .font(isAccessoryRectangularFamily ? .caption2.weight(.semibold) : .caption.weight(.semibold))
            Spacer(minLength: 0)
        }
        .foregroundColor(entry.accentColor.color)
    }

    /// Renders `primaryText`: as Arabic in the supplied font when present, otherwise as a plain title.
    @ViewBuilder
    private func primaryText(arabicSize: CGFloat, lineLimit: Int) -> some View {
        if let fontName = entry.arabicFontName, !fontName.isEmpty {
            Text(entry.primaryText)
                .font(.custom(fontName, size: arabicSize))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(lineLimit)
                .minimumScaleFactor(0.5)
        } else {
            Text(entry.primaryText)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
    }

    private var accessoryBody: some View {
        VStack(alignment: .leading, spacing: 2) {
            primaryText(arabicSize: 16, lineLimit: 2)
            if let secondary = entry.secondaryText {
                Text(secondary)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var regularBody: some View {
        VStack(alignment: .leading, spacing: 5) {
            primaryText(arabicSize: 22, lineLimit: 3)

            if let secondary = entry.secondaryText {
                Text(secondary)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            if let tertiary = entry.tertiaryText {
                Text(tertiary)
                    .font(.caption2)
                    .foregroundColor(Color(.tertiaryLabel))
                    .lineLimit(2)
            }
        }
    }
}

func quranWidgetFamilies() -> [WidgetFamily] {
    #if os(iOS)
    if #available(iOS 16.0, *) {
        return [.systemSmall, .systemMedium, .accessoryRectangular]
    }
    #endif
    return [.systemSmall, .systemMedium]
}
