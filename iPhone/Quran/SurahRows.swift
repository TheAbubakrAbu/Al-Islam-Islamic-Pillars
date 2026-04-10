import SwiftUI

struct SurahRow: View {
    @EnvironmentObject var settings: Settings
    
    let surah: Surah
    var ayah: Int?
    var end: Bool?
    var isFavorite: Bool = false

    private var revelationEmoji: String {
        surah.type == "makkan" ? "🕋" : "🕌"
    }

    private var revelationName: String {
        surah.type == "makkan" ? "Makkan" : "Madinan"
    }

    private var pageCountLabel: String {
        let count = max(surah.pageCount, 1)
        if count == 1, surah.isLessThanOnePage == true {
            return "<1 Page"
        }
        return count == 1 ? "1 Page" : "\(count) Pages"
    }

    private var startPageNumber: Int {
        surah.pageStart ?? surah.ayahs.compactMap(\.page).min() ?? 1
    }

    private var ayahAndRevelationLine: String {
        "\(surah.numberOfAyahs) Ayahs • \(revelationName) \(revelationEmoji)"
    }

    private var pageLine: String {
        "Page \(startPageNumber) • \(pageCountLabel)"
    }

    private var positionContextLine: String? {
        guard let ayah else { return nil }
        if end != nil {
            return "Ends at \(surah.id):\(ayah)"
        }
        return "Starts at \(surah.id):\(ayah)"
    }

    @ViewBuilder
    private var surahNumberPill: some View {
        ZStack(alignment: .topTrailing) {
            Text("\(surah.id)")
                .font(.subheadline.weight(.bold))
                .foregroundColor(settings.accentColor.color)
                .frame(minWidth: 40)
                .frame(maxHeight: .infinity)
                .conditionalGlassEffect(
                    useColor: isFavorite ? 0.3 : nil,
                    customTint: isFavorite ? settings.accentColor.color : nil
                )
                .accessibilityLabel("Surah \(surah.id)")

            if isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(settings.accentColor.color)
                    .padding(4)
                    .offset(x: 8, y: -6)
            }
        }
    }
    
    var body: some View {
        #if os(iOS)
        HStack(alignment: .top, spacing: 12) {
            surahNumberPill

            VStack(alignment: .leading, spacing: 2) {
                if let context = positionContextLine {
                    Text(context)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(surah.nameTransliteration)
                        .foregroundColor(.primary)
                        .font(.subheadline.weight(.semibold))
                    
                    Text(surah.nameEnglish)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }

                Text(ayahAndRevelationLine)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(pageLine)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 8)

            HStack {
                Text(surah.nameArabic)
                    .font(.custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title3).pointSize))
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.primary)
                
                Text(surah.idArabic)
                    .font(.custom("KFGQPCQUMBULUthmanicScript-Regu", size: UIFont.preferredFont(forTextStyle: .title1).pointSize))
                    .foregroundColor(settings.accentColor.color)
            }
            .padding(.top, 1)
        }
        .padding(.vertical, 6)
        .minimumScaleFactor(0.75)
        #else
        VStack {
            Text("\(surah.nameArabic) - \(surah.idArabic)")
                .font(.headline)
                .foregroundColor(settings.accentColor.color)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            Text("\(surah.id) - \(surah.nameTransliteration)")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(revelationEmoji) • \(surah.numberOfAyahs) Ayahs • \(pageLine)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        #endif
    }
}

struct SurahAyahRow: View {
    @EnvironmentObject var settings: Settings
    
    var surah: Surah
    var ayah: Ayah
    var note: String? = nil
    var disableTajweedColors: Bool = false

    private func arabicDisplayText() -> String {
        let clean = settings.cleanArabicText && !shouldShowTajweedColors
        let text = ayah.displayArabicText(surahId: surah.id, clean: clean)
        return settings.beginnerMode ? text.map { "\($0) " }.joined() : text
    }

    private var shouldShowTajweedColors: Bool {
        if disableTajweedColors { return false }
        return settings.showTajweedColors
            && settings.showArabicText
            && settings.isHafsDisplay
            && !settings.cleanArabicText
            && !settings.beginnerMode
    }

    private func arabicTajweedText() -> AttributedString? {
        guard shouldShowTajweedColors else { return nil }
        let text = ayah.displayArabicText(surahId: surah.id, clean: false)
        return TajweedStore.shared.attributedText(surah: surah.id, ayah: ayah.id, text: text)
    }

    private var tajweedAnimationKey: String {
        let categorySignature = TajweedLegendCategory.allCases
            .map { settings.isTajweedCategoryVisible($0) ? "1" : "0" }
            .joined()
        return [
            settings.showTajweedColors ? "1" : "0",
            settings.cleanArabicText ? "1" : "0",
            settings.beginnerMode ? "1" : "0",
            settings.displayQiraah,
            categorySignature
        ].joined(separator: "|")
    }
    
    var body: some View {
        HStack {
            VStack {
                Text("\(surah.id):\(ayah.id)")
                    .font(.headline)
                
                Text(surah.nameTransliteration)
                    .font(.caption)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            #if os(iOS)
            .frame(width: 65, alignment: .center)
            #else
            .frame(width: 40, alignment: .center)
            #endif
            .foregroundColor(settings.accentColor.color)
            .padding(.trailing, 8)
            
            if let note = note {
                Text(note)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
            } else {
                VStack {
                    if settings.showArabicText {
                        HighlightedSnippet(
                            source: arabicDisplayText(),
                            term: "",
                            font: .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize * 1.1),
                            accent: settings.accentColor.color,
                            fg: .primary,
                            preStyledSource: arabicTajweedText(),
                            beginnerMode: settings.beginnerMode,
                            lineLimit: 1
                        )
                            .animation(.easeInOut, value: tajweedAnimationKey)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    if settings.showTransliteration, settings.isHafsDisplay {
                        Text(ayah.textTransliteration)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                    }
                    
                    if settings.showEnglishSaheeh, settings.isHafsDisplay {
                        Text(ayah.textEnglishSaheeh)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                    } else if settings.showEnglishMustafa, settings.isHafsDisplay {
                        Text(ayah.textEnglishMustafa)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 2)
    }
}

private enum _FmtCache {
    static let mmss: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.minute, .second]
        f.zeroFormattingBehavior = .pad
        return f
    }()
}

@inline(__always)
func formatMMSS(_ seconds: Double) -> String {
    _FmtCache.mmss.string(from: seconds) ?? "00:00"
}

#if os(iOS)
struct LastListenedSurahRow: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var quranData: QuranData
    @EnvironmentObject private var quranPlayer: QuranPlayer

    let lastListenedSurah: LastListenedSurah
    let favoriteSurahs: Set<Int>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    var qiraahRefreshKey: String = ""
    @Binding var showListeningHistory: Bool

    var body: some View {
        guard let surah = quranData.quran.first(where: { $0.id == lastListenedSurah.surahNumber })
        else { return AnyView(EmptyView()) }

        return AnyView(
            Section(header:
                HStack {
                    Text("LAST LISTENED SURAH")

                    Spacer()

                    if !quranPlayer.listeningHistory.isEmpty {
                        Image(systemName: showListeningHistory ? "minus.circle" : "plus.circle")
                            .foregroundColor(settings.accentColor.color)
                            .padding(4)
                            .conditionalGlassEffect()
                            .onTapGesture {
                                settings.hapticFeedback()
                                
                                withAnimation {
                                    showListeningHistory.toggle()
                                }
                            }
                    }
                }
            ) {
                VStack {
                    NavigationLink(destination:
                        AyahsView(surah: surah)
                            .transition(.opacity)
                            .animation(.easeInOut, value: lastListenedSurah.surahName)
                    ) {
                        HStack {
                            Text("Surah \(lastListenedSurah.surahNumber): \(lastListenedSurah.surahName)")
                                .font(.title2.bold())
                                .foregroundColor(settings.accentColor.color)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)

                            Spacer()

                            Menu {
                                Button {
                                    settings.hapticFeedback()
                                    quranPlayer.playSurah(
                                        surahNumber: lastListenedSurah.surahNumber,
                                        surahName: lastListenedSurah.surahName,
                                        certainReciter: true)
                                } label: {
                                    Label("Play Last Listened", systemImage: "play.fill")
                                }

                                Button {
                                    settings.hapticFeedback()
                                    quranPlayer.playSurah(
                                        surahNumber: lastListenedSurah.surahNumber,
                                        surahName: surah.nameTransliteration)
                                } label: {
                                    Label("Play from Beginning", systemImage: "memories")
                                }
                            } label: {
                                Image(systemName: "play.fill")
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 22, height: 22)
                                    .foregroundColor(settings.accentColor.color)
                                    .minimumScaleFactor(0.75)
                                    .transition(.opacity)
                                    .opacity(!quranPlayer.isPlaying && !quranPlayer.isPaused ? 1 : 0)
                                    .animation(.easeInOut, value: quranPlayer.isPlaying)
                                    .animation(.easeInOut, value: quranPlayer.isPaused)
                            }
                            .disabled(quranPlayer.isPlaying || quranPlayer.isPaused)
                        }
                    }
                    .padding(.bottom, 1)

                    HStack {
                        Text(lastListenedSurah.reciter.displayNameWithEnglishQiraah)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        Spacer()

                        Text("\(formatMMSS(lastListenedSurah.currentDuration)) / \(formatMMSS(lastListenedSurah.fullDuration))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .padding(.vertical, 8)

                if showListeningHistory && !quranPlayer.listeningHistory.isEmpty {
                    ForEach(quranPlayer.listeningHistory) { item in
                        if let historySurah = quranData.quran.first(where: { $0.id == item.surahNumber }) {
                            NavigationLink(destination: AyahsView(surah: historySurah)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Surah \(item.surahNumber): \(item.surahName)")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(settings.accentColor.color.opacity(0.75))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)

                                    Text(item.reciter.name)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .rightSwipeActions(
                surahID: surah.id,
                surahName: surah.nameTransliteration,
                certainReciter: true,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
            .leftSwipeActions(surah: surah.id, favoriteSurahs: favoriteSurahs)
            #if os(iOS)
            .contextMenu {
                Button(role: .destructive) {
                    settings.hapticFeedback()
                    withAnimation {
                        settings.lastListenedSurah = nil
                    }
                } label: {
                    Label("Remove", systemImage: "trash")
                }

                Divider()

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: lastListenedSurah.surahNumber,
                        surahName: lastListenedSurah.surahName,
                        certainReciter: true
                    )
                } label: {
                    Label("Play Last Listened", systemImage: "play.fill")
                }

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: lastListenedSurah.surahNumber,
                        surahName: surah.nameTransliteration
                    )
                } label: {
                    Label("Play from Beginning", systemImage: "memories")
                }

                Divider()

                SurahContextMenu(
                    surahID: surah.id,
                    surahName: surah.nameTransliteration,
                    favoriteSurahs: favoriteSurahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID,
                    lastListened: true
                )
            }
            #endif
            .animation(.easeInOut, value: quranPlayer.isPlaying || quranPlayer.isPaused)
        )
    }
}
#endif

struct LastReadAyahRow: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var quranPlayer: QuranPlayer
    @EnvironmentObject private var quranData: QuranData

    let surah: Surah
    let ayah: Ayah

    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    @Binding var showReadingHistory: Bool

    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah.id)-\(ayah.id)")
    }
    
    private var noteToShow: String? {
        noteText(surahID: surah.id, ayahID: ayah.id)
    }

    private func noteText(surahID: Int, ayahID: Int) -> String? {
        guard let idx = settings.bookmarkedAyahs.firstIndex(where: { $0.surah == surahID && $0.ayah == ayahID }) else {
            return nil
        }
        let t = settings.bookmarkedAyahs[idx].note?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (t?.isEmpty == false) ? t : nil
    }

    var body: some View {
        Section(header:
            HStack {
                Text("LAST READ AYAH")

                Spacer()

                if !quranPlayer.readingHistory.isEmpty {
                    Image(systemName: showReadingHistory ? "minus.circle" : "plus.circle")
                        .foregroundColor(settings.accentColor.color)
                        .padding(4)
                        .conditionalGlassEffect()
                        .onTapGesture {
                            settings.hapticFeedback()
                            
                            withAnimation {
                                showReadingHistory.toggle()
                            }
                        }
                }
            }
        ) {
            NavigationLink(destination: AyahsView(surah: surah, ayah: ayah.id)) {
                SurahAyahRow(surah: surah, ayah: ayah, note: noteToShow)
            }
            .rightSwipeActions(
                surahID: surah.id,
                surahName: surah.nameTransliteration,
                ayahID: ayah.id,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
            .leftSwipeActions(
                surah: surah.id,
                favoriteSurahs: favoriteSurahs,
                bookmarkedAyahs: bookmarkedAyahs,
                bookmarkedSurah: surah.id,
                bookmarkedAyah: ayah.id
            )
            .ayahContextMenuModifier(
                surah: surah.id,
                ayah: ayah.id,
                favoriteSurahs: favoriteSurahs,
                bookmarkedAyahs: bookmarkedAyahs,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID,
                lastRead: true
            )

            if showReadingHistory && !quranPlayer.readingHistory.isEmpty {
                ForEach(quranPlayer.readingHistory) { item in
                    let normalizedAyah = max(1, item.ayahNumber)
                    if let surah = quranData.quran.first(where: { $0.id == item.surahNumber }), let ayah = surah.ayahs.first(where: { $0.id == normalizedAyah }) {
                        NavigationLink(destination: AyahsView(surah: surah, ayah: ayah.id)) {
                            SurahAyahRow(
                                surah: surah,
                                ayah: ayah,
                                note: noteText(surahID: surah.id, ayahID: ayah.id)
                            )
                            .opacity(0.6)
                        }
                        .rightSwipeActions(
                            surahID: surah.id,
                            surahName: surah.nameTransliteration,
                            ayahID: ayah.id,
                            searchText: $searchText,
                            scrollToSurahID: $scrollToSurahID
                        )
                        .leftSwipeActions(
                            surah: surah.id,
                            favoriteSurahs: favoriteSurahs,
                            bookmarkedAyahs: bookmarkedAyahs,
                            bookmarkedSurah: surah.id,
                            bookmarkedAyah: ayah.id
                        )
                        .ayahContextMenuModifier(
                            surah: surah.id,
                            ayah: ayah.id,
                            favoriteSurahs: favoriteSurahs,
                            bookmarkedAyahs: bookmarkedAyahs,
                            searchText: $searchText,
                            scrollToSurahID: $scrollToSurahID,
                            lastRead: true
                        )
                    }
                }
            }
        }
    }
}

struct AyahSearchResultRow: View {
    @EnvironmentObject private var settings: Settings

    let surah: Surah
    let ayah: Ayah

    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    var disableTajweedColors: Bool = false

    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah.id)-\(ayah.id)")
    }

    var body: some View {
        NavigationLink(destination: AyahsView(surah: surah, ayah: ayah.id)) {
            SurahAyahRow(surah: surah, ayah: ayah, disableTajweedColors: disableTajweedColors)
        }
        .rightSwipeActions(
            surahID: surah.id,
            surahName: surah.nameTransliteration,
            searchText: $searchText,
            scrollToSurahID: $scrollToSurahID
        )
        .leftSwipeActions(
            surah: surah.id,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            bookmarkedSurah: surah.id,
            bookmarkedAyah: ayah.id,
        )
        .ayahContextMenuModifier(
            surah: surah.id,
            ayah: ayah.id,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            searchText: $searchText,
            scrollToSurahID: $scrollToSurahID
        )
    }
}

struct AyahSearchRow: View, Equatable {
    @EnvironmentObject private var settings: Settings
    
    let surahName: String
    let surah: Int
    let ayah:  Int
    let query: String
    
    let arabic: String
    let transliteration: String
    let englishSaheeh: String
    let englishMustafa: String
    
    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    var qiraahRefreshKey: String = ""

    /// When true (Quran search grouped by surah): `surah:ayah` label + same Arabic / transliteration / English visibility rules as the full row, without the top surah name line.
    var compact: Bool = false
    var disableTajweedColors: Bool = false
    
    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah)-\(ayah)")
    }

    private var shouldShowTajweedColors: Bool {
        if disableTajweedColors { return false }
        return settings.showTajweedColors
            && settings.showArabicText
            && settings.isHafsDisplay
            && !settings.cleanArabicText
            && !settings.beginnerMode
    }

    private func arabicTajweedText() -> AttributedString? {
        guard shouldShowTajweedColors else { return nil }
        return TajweedStore.shared.attributedText(surah: surah, ayah: ayah, text: arabic)
    }

    private var tajweedAnimationKey: String {
        let categorySignature = TajweedLegendCategory.allCases
            .map { settings.isTajweedCategoryVisible($0) ? "1" : "0" }
            .joined()
        return [
            settings.showTajweedColors ? "1" : "0",
            settings.cleanArabicText ? "1" : "0",
            settings.beginnerMode ? "1" : "0",
            settings.displayQiraah,
            categorySignature,
            query
        ].joined(separator: "|")
    }

    @ViewBuilder
    private func buildCompactSearchRow() -> some View {
        let normalizedQuery = settings.cleanSearch(query, whitespace: true).removingArabicDiacriticsAndSigns

        let srcArabic = settings.cleanSearch(arabic, whitespace: false).removingArabicDiacriticsAndSigns
        let srcTr = settings.cleanSearch(transliteration, whitespace: false).removingArabicDiacriticsAndSigns
        let srcSaheeh = settings.cleanSearch(englishSaheeh, whitespace: false).removingArabicDiacriticsAndSigns
        let srcMustafa = settings.cleanSearch(englishMustafa, whitespace: false).removingArabicDiacriticsAndSigns

        let mArabic = !normalizedQuery.isEmpty && srcArabic.contains(normalizedQuery)
        let mTr = !normalizedQuery.isEmpty && srcTr.contains(normalizedQuery)
        let mSaheeh = !normalizedQuery.isEmpty && srcSaheeh.contains(normalizedQuery)
        let mMustafa = !normalizedQuery.isEmpty && srcMustafa.contains(normalizedQuery)

        let showArabicLine = settings.showArabicText || mArabic
        let showTrLine = settings.isHafsDisplay && (settings.showTransliteration || mTr)

        let (showSaheehLine, showMustafaLine): (Bool, Bool) = {
            guard settings.isHafsDisplay else { return (false, false) }
            let userSaheehOn = settings.showEnglishSaheeh
            let userMustafaOn = settings.showEnglishMustafa
            if mSaheeh && mMustafa { return (true, true) }
            if mSaheeh || mMustafa { return (mSaheeh, mMustafa) }
            if userSaheehOn && !userMustafaOn { return (true, false) }
            if userMustafaOn && !userSaheehOn { return (false, true) }
            if userSaheehOn && userMustafaOn { return (true, false) }
            return (false, false)
        }()

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("\(surah):\(ayah)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(minWidth: 52, alignment: .leading)

                if showArabicLine {
                    HighlightedSnippet(
                        source: arabic,
                        term: query,
                        font: .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .body).pointSize),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        preStyledSource: arabicTajweedText(),
                        beginnerMode: settings.beginnerMode
                    )
                    .animation(.easeInOut, value: tajweedAnimationKey)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .multilineTextAlignment(.trailing)
                }
            }

            if showTrLine {
                HighlightedSnippet(
                    source: transliteration,
                    term: query,
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }

            if showSaheehLine {
                HighlightedSnippet(
                    source: englishSaheeh,
                    term: query,
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }

            if showMustafaLine {
                HighlightedSnippet(
                    source: englishMustafa,
                    term: query,
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }
        }
    }

    @ViewBuilder
    private func buildFullSearchRow() -> some View {
        let normalizedQuery = settings.cleanSearch(query, whitespace: true).removingArabicDiacriticsAndSigns

        let srcArabic = settings.cleanSearch(arabic, whitespace: false).removingArabicDiacriticsAndSigns
        let srcTr = settings.cleanSearch(transliteration, whitespace: false).removingArabicDiacriticsAndSigns
        let srcSaheeh = settings.cleanSearch(englishSaheeh, whitespace: false).removingArabicDiacriticsAndSigns
        let srcMustafa = settings.cleanSearch(englishMustafa, whitespace: false).removingArabicDiacriticsAndSigns

        let mArabic = !normalizedQuery.isEmpty && srcArabic.contains(normalizedQuery)
        let mTr = !normalizedQuery.isEmpty && srcTr.contains(normalizedQuery)
        let mSaheeh = !normalizedQuery.isEmpty && srcSaheeh.contains(normalizedQuery)
        let mMustafa = !normalizedQuery.isEmpty && srcMustafa.contains(normalizedQuery)

        let showArabicLine = settings.showArabicText || mArabic
        let showTrLine = settings.isHafsDisplay && (settings.showTransliteration || mTr)

        let (showSaheehLine, showMustafaLine): (Bool, Bool) = {
            guard settings.isHafsDisplay else { return (false, false) }
            let userSaheehOn = settings.showEnglishSaheeh
            let userMustafaOn = settings.showEnglishMustafa
            if mSaheeh && mMustafa { return (true, true) }
            if mSaheeh || mMustafa { return (mSaheeh, mMustafa) }
            if userSaheehOn && !userMustafaOn { return (true, false) }
            if userMustafaOn && !userSaheehOn { return (false, true) }
            if userSaheehOn && userMustafaOn { return (true, false) }
            return (false, false)
        }()

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(surahName) \(surah):\(ayah)")

                if isBookmarked {
                    Spacer()

                    Image(systemName: "bookmark.fill")
                }
            }
            .font(.caption)
            .foregroundColor(settings.accentColor.color)
            .transition(.opacity)

            if showArabicLine {
                HighlightedSnippet(
                    source: arabic,
                    term: query,
                    font: .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .body).pointSize),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    preStyledSource: arabicTajweedText(),
                    beginnerMode: settings.beginnerMode
                )
                .animation(.easeInOut, value: tajweedAnimationKey)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
            }

            if showTrLine {
                HighlightedSnippet(
                    source: transliteration,
                    term: query,
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }

            if showSaheehLine {
                HighlightedSnippet(
                    source: englishSaheeh,
                    term: query,
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }

            if showMustafaLine {
                HighlightedSnippet(
                    source: englishMustafa,
                    term: query,
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }
        }
    }
    
    var body: some View {
        Group {
            if compact {
                buildCompactSearchRow()
            } else {
                buildFullSearchRow()
            }
        }
        .padding(.vertical, 2)
        .rightSwipeActions(
            surahID: surah,
            surahName: surahName,
            ayahID: ayah,
            searchText: $searchText,
            scrollToSurahID: $scrollToSurahID
        )
        .leftSwipeActions(
            surah: surah,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            bookmarkedSurah: surah,
            bookmarkedAyah: ayah
        )
        .ayahContextMenuModifier(
            surah: surah,
            ayah: ayah,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            searchText: $searchText,
            scrollToSurahID: $scrollToSurahID
        )
    }
    
    static func == (l: Self, r: Self) -> Bool {
        l.surah == r.surah && l.ayah == r.ayah &&
        l.query == r.query &&
        l.qiraahRefreshKey == r.qiraahRefreshKey &&
        l.compact == r.compact &&
        l.disableTajweedColors == r.disableTajweedColors &&
        l.favoriteSurahs == r.favoriteSurahs &&
        l.bookmarkedAyahs == r.bookmarkedAyahs
    }
}

private struct SurahRowsPreviewContent: View {
    var body: some View {
        List {
            SurahRow(
                surah: AlIslamPreviewData.surah,
            )
            
            SurahAyahRow(
                surah: AlIslamPreviewData.surah,
                ayah: AlIslamPreviewData.ayah
            )
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        SurahRowsPreviewContent()
    }
}
