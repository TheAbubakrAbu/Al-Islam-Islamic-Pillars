import SwiftUI
import WidgetKit

enum QuranWidgetKind {
    case lastReadSurah
    case lastListenedSurah
    case randomAyah
    case randomBookmarkedAyah

    var title: String {
        switch self {
        case .lastReadSurah: return "Last Read Surah"
        case .lastListenedSurah: return "Last Listened Surah"
        case .randomAyah: return "Random Ayah"
        case .randomBookmarkedAyah: return "Random Bookmarked Ayah"
        }
    }

    var icon: String {
        switch self {
        case .lastReadSurah: return "book.closed"
        case .lastListenedSurah: return "play.fill"
        case .randomAyah: return "sparkles"
        case .randomBookmarkedAyah: return "bookmark.fill"
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
        let quranData = QuranData.shared

        switch kind {
        case .lastReadSurah:
            return makeLastReadEntry(settings: settings, quranData: quranData)
        case .lastListenedSurah:
            return makeLastListenedEntry(settings: settings, quranData: quranData)
        case .randomAyah:
            return makeRandomAyahEntry(settings: settings, quranData: quranData)
        case .randomBookmarkedAyah:
            return makeRandomBookmarkedAyahEntry(settings: settings, quranData: quranData)
        }
    }

    private func makeLastReadEntry(settings: Settings, quranData: QuranData) -> QuranWidgetEntry {
        guard let surah = quranData.surah(settings.lastReadSurah), settings.lastReadSurah > 0 else {
            return fallbackEntry(settings: settings, message: "Open the app to set your last read verse.")
        }

        let ayahText = settings.lastReadAyah > 0 ? "Ayah \(settings.lastReadAyah)" : "Last read surah"
        return QuranWidgetEntry(
            date: Date(),
            kind: .lastReadSurah,
            title: kind.title,
            icon: kind.icon,
            primaryText: surah.nameTransliteration,
            secondaryText: "Surah \(surah.id) • \(surah.nameEnglish)",
            tertiaryText: ayahText,
            accentColor: settings.accentColor,
            fallbackText: nil
        )
    }

    private func makeLastListenedEntry(settings: Settings, quranData: QuranData) -> QuranWidgetEntry {
        guard let listened = settings.lastListenedSurah,
              let surah = quranData.surah(listened.surahNumber) else {
            return fallbackEntry(settings: settings, message: "Open the app to resume your last listened surah.")
        }

        return QuranWidgetEntry(
            date: Date(),
            kind: .lastListenedSurah,
            title: kind.title,
            icon: kind.icon,
            primaryText: surah.nameTransliteration,
            secondaryText: listened.reciter.displayNameForNowPlaying,
            tertiaryText: "\(formatDurationMMSS(listened.currentDuration)) / \(formatDurationMMSS(listened.fullDuration))",
            accentColor: settings.accentColor,
            fallbackText: nil
        )
    }

    private func makeRandomAyahEntry(settings: Settings, quranData: QuranData) -> QuranWidgetEntry {
        guard let target = randomSafeAyah(in: quranData) else {
            return fallbackEntry(settings: settings, message: "No safe random ayah was available right now.")
        }

        return QuranWidgetEntry(
            date: Date(),
            kind: .randomAyah,
            title: kind.title,
            icon: kind.icon,
            primaryText: target.ayah.displayArabicText(surahId: target.surah.id, clean: true),
            secondaryText: "Surah \(target.surah.id):\(target.ayah.id) • \(target.surah.nameTransliteration)",
            tertiaryText: snippet(target.ayah.textEnglishSaheeh),
            accentColor: settings.accentColor,
            fallbackText: nil
        )
    }

    private func makeRandomBookmarkedAyahEntry(settings: Settings, quranData: QuranData) -> QuranWidgetEntry {
        let bookmarked = settings.bookmarkedAyahs
            .shuffled()
            .compactMap { bookmark -> (Surah, Ayah)? in
                guard let surah = quranData.surah(bookmark.surah),
                      let ayah = quranData.ayah(surah: bookmark.surah, ayah: bookmark.ayah),
                      isSafeWidgetAyah(ayah) else { return nil }
                return (surah, ayah)
            }
            .first

        guard let (surah, ayah) = bookmarked else {
            return fallbackEntry(settings: settings, message: "Add a bookmark to show a random bookmarked ayah here.")
        }

        return QuranWidgetEntry(
            date: Date(),
            kind: .randomBookmarkedAyah,
            title: kind.title,
            icon: kind.icon,
            primaryText: ayah.displayArabicText(surahId: surah.id, clean: true),
            secondaryText: "Surah \(surah.id):\(ayah.id) • \(surah.nameTransliteration)",
            tertiaryText: snippet(ayah.textEnglishSaheeh),
            accentColor: settings.accentColor,
            fallbackText: nil
        )
    }

    private func randomSafeAyah(in quranData: QuranData) -> (surah: Surah, ayah: Ayah)? {
        var safeAyahs: [(surah: Surah, ayah: Ayah)] = []
        for surah in quranData.filteredSurahs(query: "") {
            for ayah in surah.ayahs where isSafeWidgetAyah(ayah) {
                safeAyahs.append((surah: surah, ayah: ayah))
            }
        }

        return safeAyahs.randomElement()
    }

    private func isSafeWidgetAyah(_ ayah: Ayah) -> Bool {
        let combined = [ayah.textEnglishSaheeh, ayah.textEnglishMustafa, ayah.textTransliteration]
            .joined(separator: " ")
            .lowercased()

        let blockedWords = ["kill", "killing", "fight", "fighting", "violence", "violent", "murder", "slay", "slaughter", "battle", "war"]
        return !blockedWords.contains(where: { combined.contains($0) })
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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header

            if let fallbackText = entry.fallbackText {
                Text(fallbackText)
                    .font(isAccessoryRectangularFamily ? .caption2 : .caption)
                    .foregroundColor(.secondary)
                    .lineLimit(isAccessoryRectangularFamily ? 2 : 3)
            } else if isAccessoryRectangularFamily {
                accessoryBody
            } else {
                regularBody
            }
        }
        .padding(isAccessoryRectangularFamily ? 0 : 12)
        .foregroundColor(entry.accentColor.color)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
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

    private var accessoryBody: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.primaryText)
                .font(.caption2.weight(.semibold))
                .lineLimit(2)
            if let secondary = entry.secondaryText {
                Text(secondary)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var regularBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.primaryText)
                .font(.headline)
                .lineLimit(2)

            if let secondary = entry.secondaryText {
                Text(secondary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if let tertiary = entry.tertiaryText {
                Text(tertiary)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
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
