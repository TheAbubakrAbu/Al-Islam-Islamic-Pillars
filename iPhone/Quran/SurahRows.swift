import SwiftUI

struct SurahRow: View, Equatable {
    @EnvironmentObject var settings: Settings
    
    let surah: Surah
    var ayah: Int?
    var end: Bool?
    let favoriteState: Bool
    let showInfo: Bool
    let accentColor: AccentColor
    let useFontArabic: Bool
    let fontArabic: String
    let khatmCompletedAyahs: Int?
    let khatmTotalAyahs: Int?
    let searchQuery: String

    init(
        surah: Surah,
        ayah: Int? = nil,
        end: Bool? = nil,
        isFavorite: Bool? = nil,
        hideInfo: Bool? = nil,
        accentColor: AccentColor = Settings.shared.accentColor,
        useFontArabic: Bool = Settings.shared.useFontArabic,
        fontArabic: String = Settings.shared.fontArabic,
        khatmCompletedAyahs: Int? = nil,
        khatmTotalAyahs: Int? = nil,
        searchQuery: String = ""
    ) {
        self.surah = surah
        self.ayah = ayah
        self.end = end
        self.favoriteState = isFavorite ?? Settings.shared.isSurahFavorite(surah: surah.id)
        self.showInfo = hideInfo.map { !$0 } ?? Settings.shared.showFullSurahRow
        self.accentColor = accentColor
        self.useFontArabic = useFontArabic
        self.fontArabic = fontArabic
        self.khatmCompletedAyahs = khatmCompletedAyahs
        self.khatmTotalAyahs = khatmTotalAyahs
        self.searchQuery = searchQuery
    }

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
        "\(surah.numberOfAyahs) Ayahs \(revelationEmoji)"
    }

    private var sortedMetricLine: String? {
        switch settings.quranSortMode {
        case .ayahs:
            return surah.ayahCountLabel(for: settings.displayQiraahForArabic)
        case .page:
            return pageCountLabel
        case .words:
            return "Words: \(surah.wordCount)"
        case .letters:
            return "Letters: \(surah.letterCount)"
        default:
            return nil
        }
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

    private var badgeWidth: CGFloat {
        let font = UIFont.preferredFont(forTextStyle: .headline)
        let text = "100" as NSString
        let size = text.size(withAttributes: [.font: font])
        return size.width + 8
    }

    private var isKhatmComplete: Bool {
        guard let khatmCompletedAyahs, let khatmTotalAyahs else { return false }
        return khatmTotalAyahs > 0 && khatmCompletedAyahs >= khatmTotalAyahs
    }

    private var isKhatmPartiallyComplete: Bool {
        guard let khatmCompletedAyahs, let khatmTotalAyahs else { return false }
        return khatmCompletedAyahs > 0 && khatmCompletedAyahs < khatmTotalAyahs
    }

    @ViewBuilder
    private var khatmProgressLine: some View {
        if let khatmCompletedAyahs, let khatmTotalAyahs {
            HStack(spacing: 5) {
                Image(systemName: isKhatmComplete ? "checkmark.circle.fill" : "circle.dashed")
                    .font(.caption2.weight(.semibold))
                Text("\(khatmCompletedAyahs)/\(khatmTotalAyahs) ayahs")
                    .font(.caption2.weight(isKhatmComplete ? .semibold : .regular))
            }
            .foregroundStyle(
                isKhatmComplete ? accentColor.color :
                isKhatmPartiallyComplete ? accentColor.color.opacity(0.72) :
                .secondary
            )
        }
    }
    
    @ViewBuilder
    private var surahNumberPill: some View {
        ZStack(alignment: .topTrailing) {
            Text("\(surah.id)")
                .font(.caption.weight(.bold))
                .foregroundColor(accentColor.color)
                .frame(width: badgeWidth)
                .frame(maxHeight: .infinity)
                .conditionalGlassEffect(
                    useColor: favoriteState ? 0.3 : nil,
                    customTint: favoriteState ? accentColor.color : nil
                )
                .onTapGesture {
                    settings.hapticFeedback()
                    settings.toggleSurahFavorite(surah: surah.id)
                }
                .accessibilityLabel("Surah \(surah.id)")

            if favoriteState {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(settings.accentColor.color)
                    .padding(4)
                    .offset(x: 8, y: -6)
            }
        }
        .padding(.vertical, {
            if #available(iOS 26, *) { 0 } else { 8 }
        }())
    }
    
    var body: some View {
        #if os(iOS)
        HStack(alignment: .center) {
            surahNumberPill
                .padding(.trailing, 2)

            VStack(alignment: .leading, spacing: 2) {
                if let context = positionContextLine {
                    Text(context)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                HighlightedSnippet(
                    source: surah.nameTransliteration,
                    term: searchQuery,
                    font: .subheadline.weight(.semibold),
                    accent: accentColor.color,
                    fg: .primary
                )
                
                HighlightedSnippet(
                    source: surah.nameEnglish,
                    term: searchQuery,
                    font: .caption,
                    accent: accentColor.color,
                    fg: showInfo ? .primary : .secondary
                )

                if showInfo {
                    Text(pageLine)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(ayahAndRevelationLine)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if let sortedMetricLine,
                       settings.quranSortMode == .words || settings.quranSortMode == .letters {
                        Text(sortedMetricLine)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else if let sortedMetricLine {
                    Text(sortedMetricLine)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                khatmProgressLine
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)

            HStack {
                HighlightedSnippet(
                    source: surah.nameArabic,
                    term: searchQuery,
                    font: .custom(fontArabic, size: UIFont.preferredFont(forTextStyle: .title3).pointSize),
                    accent: accentColor.color,
                    fg: .primary
                )
                
                Text(surah.idArabic)
                    .font(.custom(Settings.hafsUthmaniFontName, size: UIFont.preferredFont(forTextStyle: .title1).pointSize))
                    .foregroundColor(accentColor.color)
            }
            .minimumScaleFactor(1)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .contentShape(Rectangle())
        #else
        VStack {
            HStack {
                Text("\(surah.id) - \(surah.nameTransliteration)")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("\(surah.nameArabic) - \(surah.idArabic)")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .minimumScaleFactor(0.9)
            }

            Text("\(revelationEmoji) • \(surah.numberOfAyahs) Ayahs • \(pageLine)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .contentShape(Rectangle())
        #endif
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.surah == rhs.surah &&
        lhs.ayah == rhs.ayah &&
        lhs.end == rhs.end &&
        lhs.favoriteState == rhs.favoriteState &&
        lhs.showInfo == rhs.showInfo &&
        lhs.accentColor == rhs.accentColor &&
        lhs.useFontArabic == rhs.useFontArabic &&
        lhs.fontArabic == rhs.fontArabic &&
        lhs.khatmCompletedAyahs == rhs.khatmCompletedAyahs &&
        lhs.khatmTotalAyahs == rhs.khatmTotalAyahs &&
        lhs.searchQuery == rhs.searchQuery
    }
}

struct SurahAyahRow: View {
    @EnvironmentObject var settings: Settings
    @State private var confirmRemoveNote = false
    
    var surah: Surah
    var ayah: Ayah
    var note: String? = nil
    var disableTajweedColors: Bool = false

    private var isBookmarked: Bool {
        settings.bookmarkedAyahs.contains { $0.surah == surah.id && $0.ayah == ayah.id }
    }

    private func toggleBookmarkWithNoteGuard() {
        if !settings.toggleBookmarkIfNoNoteLoss(surah: surah.id, ayah: ayah.id) {
            confirmRemoveNote = true
        }
    }

    private func arabicDisplayText() -> String {
        let clean = settings.cleanArabicText
        let text = ayah.displayArabicText(surahId: surah.id, clean: clean)
        return settings.beginnerMode ? text.map { String($0) }.joined(separator: " ") : text
    }

    private var shouldShowTajweedColors: Bool {
        if disableTajweedColors { return false }
        return settings.showTajweedColors
            && settings.showArabicText
            && settings.isHafsDisplay
    }

    private func arabicTajweedText() -> AttributedString? {
        guard shouldShowTajweedColors else { return nil }
        let text = ayah.displayArabicText(surahId: surah.id, clean: false)
        let displayText = settings.cleanArabicText ? ayah.displayArabicText(surahId: surah.id, clean: true) : text
        let renderedDisplayText = settings.beginnerMode ? displayText.map { String($0) }.joined(separator: " ") : displayText
        return TajweedStore.shared.attributedText(
            surah: surah.id,
            ayah: ayah.id,
            text: text,
            displayText: renderedDisplayText,
            cleanDisplayText: settings.cleanArabicText,
            beginnerSpacing: settings.beginnerMode
        )
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
    
    private var badgeWidth: CGFloat {
        let font = UIFont.preferredFont(forTextStyle: .headline)
        let text = "10:100" as NSString
        let size = text.size(withAttributes: [.font: font])
        return size.width + 8
    }
    
    var body: some View {
        HStack {
            VStack {
                ZStack(alignment: .topTrailing) {
                    Text("\(surah.id):\(ayah.id)")
                        .font(.headline)
                        .monospacedDigit()
                        #if os(iOS)
                        .frame(width: badgeWidth, alignment: .center)
                        .padding(4)
                        #else
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        #endif
                        .conditionalGlassEffect(
                            useColor: isBookmarked ? 0.3 : nil,
                            customTint: isBookmarked ? settings.accentColor.color : nil,
                            interactive: false
                        )
                        .onTapGesture {
                            settings.hapticFeedback()
                            toggleBookmarkWithNoteGuard()
                        }

                    if isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.caption2)
                            .foregroundStyle(settings.accentColor.color)
                            .padding(4)
                            .offset(x: 8, y: -6)
                    }
                }
                
                Text(surah.nameTransliteration)
                    #if os(iOS)
                    .font(.caption)
                    #else
                    .font(.caption2)
                    #endif
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            #if os(iOS)
            .frame(width: 65, alignment: .center)
            #else
            .frame(width: 50, alignment: .center)
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
        .contentShape(Rectangle())
        .confirmationDialog(Settings.bookmarkNoteRemovalDialogTitle, isPresented: $confirmRemoveNote, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                settings.hapticFeedback()
                settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
            }
            Button("Cancel") {}
        } message: {
            Text(Settings.bookmarkNoteRemovalDialogMessage)
        }
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
    var onSelectSurah: ((Int) -> Void)? = nil

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
                    Group {
                        if let onSelectSurah {
                            Button {
                                settings.hapticFeedback()
                                onSelectSurah(surah.id)
                            } label: {
                                lastListenedTitleRow(surah: surah)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        } else {
                            NavigationLink(destination:
                                SurahView(surah: surah)
                                    .transition(.opacity)
                                    .animation(.easeInOut, value: lastListenedSurah.surahName)
                            ) {
                                lastListenedTitleRow(surah: surah)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .contentShape(Rectangle())
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
                            if let onSelectSurah {
                                Button {
                                    settings.hapticFeedback()
                                    onSelectSurah(historySurah.id)
                                } label: {
                                    listeningHistoryLabel(item)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                            } else {
                                NavigationLink(destination: SurahView(surah: historySurah)) {
                                    listeningHistoryLabel(item)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                }
                                .contentShape(Rectangle())
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
                Text("Surah Actions")
                    .foregroundStyle(.secondary)

                Button(role: .destructive) {
                    settings.hapticFeedback()
                    withAnimation {
                        settings.lastListenedSurah = nil
                    }
                } label: {
                    Label("Remove", systemImage: "minus.circle")
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

    private func lastListenedTitleRow(surah: Surah) -> some View {
        HStack {
            Text("Surah \(lastListenedSurah.surahNumber): \(lastListenedSurah.surahName)")
                .font(.title2.bold())
                .foregroundColor(settings.accentColor.color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer()

            Menu {
                Text("Last Listened")
                    .foregroundStyle(.secondary)

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

    private func listeningHistoryLabel(_ item: ListeningHistoryItem) -> some View {
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
    var onSelectAyah: ((Int, Int) -> Void)? = nil

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
            Group {
                if let onSelectAyah {
                    Button {
                        settings.hapticFeedback()
                        onSelectAyah(surah.id, ayah.id)
                    } label: {
                        SurahAyahRow(surah: surah, ayah: ayah, note: noteToShow)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                } else {
                    NavigationLink(destination: SurahView(surah: surah, ayah: ayah.id)) {
                        SurahAyahRow(surah: surah, ayah: ayah, note: noteToShow)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .tag(surah.id)
                    .contentShape(Rectangle())
                }
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
                        Group {
                            if let onSelectAyah {
                                Button {
                                    settings.hapticFeedback()
                                    onSelectAyah(surah.id, ayah.id)
                                } label: {
                                    SurahAyahRow(
                                        surah: surah,
                                        ayah: ayah,
                                        note: noteText(surahID: surah.id, ayahID: ayah.id)
                                    )
                                    .opacity(0.6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                            } else {
                                NavigationLink(destination: SurahView(surah: surah, ayah: ayah.id)) {
                                    SurahAyahRow(
                                        surah: surah,
                                        ayah: ayah,
                                        note: noteText(surahID: surah.id, ayahID: ayah.id)
                                    )
                                    .opacity(0.6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .tag(surah.id)
                                .contentShape(Rectangle())
                            }
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
    var onSelectAyah: ((Int, Int) -> Void)? = nil

    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah.id)-\(ayah.id)")
    }

    private var pageJuzLine: String? {
        if let page = ayah.page, let juz = ayah.juz {
            return "Page \(page) • Juz \(juz)"
        }
        if let page = ayah.page {
            return "Page \(page)"
        }
        if let juz = ayah.juz {
            return "Juz \(juz)"
        }
        return nil
    }

    var body: some View {
        let row = VStack(alignment: .leading, spacing: 4) {
            SurahAyahRow(surah: surah, ayah: ayah, disableTajweedColors: disableTajweedColors)

            if settings.showFullSurahRow, let pageJuzLine {
                Label(pageJuzLine, systemImage: "map")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }

        Group {
            if let onSelectAyah {
                Button {
                    settings.hapticFeedback()
                    onSelectAyah(surah.id, ayah.id)
                } label: {
                    row
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            } else {
                NavigationLink(destination: SurahView(surah: surah, ayah: ayah.id)) {
                    row
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .contentShape(Rectangle())
            }
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
    @State private var confirmRemoveNote = false

    
    let surahName: String
    let surah: Int
    let ayah:  Int
    let query: String
    
    let arabic: String
    let transliteration: String
    let englishSaheeh: String
    let englishMustafa: String
    let page: Int?
    let juz: Int?
    
    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    var qiraahRefreshKey: String = ""

    /// When true (Quran search grouped by surah): `surah:ayah` label + same Arabic / transliteration / English visibility rules as the full row, without the top surah name line.
    var compact: Bool = false
    var disableTajweedColors: Bool = false

    private final class NormalizedSources {
        let arabic: String
        let transliteration: String
        let saheeh: String
        let mustafa: String

        init(arabic: String, transliteration: String, saheeh: String, mustafa: String) {
            self.arabic = arabic
            self.transliteration = transliteration
            self.saheeh = saheeh
            self.mustafa = mustafa
        }
    }

    private struct SearchVisibility {
        let mArabic: Bool
        let mTr: Bool
        let mSaheeh: Bool
        let mMustafa: Bool
        let showArabicLine: Bool
        let showTrLine: Bool
        let showSaheehLine: Bool
        let showMustafaLine: Bool
    }

    private static let normalizedSourcesCache: NSCache<NSString, NormalizedSources> = {
        let cache = NSCache<NSString, NormalizedSources>()
        cache.countLimit = 5000
        return cache
    }()
    
    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah)-\(ayah)")
    }
    
    private var badgeWidth: CGFloat {
        let font = UIFont.preferredFont(forTextStyle: .headline)
        let text = "10:100" as NSString
        let size = text.size(withAttributes: [.font: font])
        return size.width + 8
    }

    private var pageJuzLine: String? {
        if let page, let juz {
            return "Page \(page) • Juz \(juz)"
        }
        if let page {
            return "Page \(page)"
        }
        if let juz {
            return "Juz \(juz)"
        }
        return nil
    }

    @ViewBuilder
    private var pageJuzMetadata: some View {
        if settings.showFullSurahRow, let pageJuzLine {
            Label(pageJuzLine, systemImage: "map")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private func toggleBookmarkWithNoteGuard() {
        if !settings.toggleBookmarkIfNoNoteLoss(surah: surah, ayah: ayah) {
            confirmRemoveNote = true
        }
    }

    @ViewBuilder
    private var ayahReferenceBadge: some View {
        ZStack(alignment: .topTrailing) {
            Text("\(surah):\(ayah)")
                .font(.caption.weight(.semibold))
                .foregroundColor(settings.accentColor.color)
                .monospacedDigit()
                .frame(width: badgeWidth, alignment: .center)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .conditionalGlassEffect(
                    useColor: isBookmarked ? 0.3 : nil,
                    customTint: isBookmarked ? settings.accentColor.color : nil
                )
                .onTapGesture {
                    settings.hapticFeedback()
                    toggleBookmarkWithNoteGuard()
                }

            if isBookmarked {
                Image(systemName: "bookmark.fill")
                    .font(.caption2)
                    .foregroundStyle(settings.accentColor.color)
                    .padding(4)
                    .offset(x: 8, y: -6)
            }
        }
    }

    private var shouldShowTajweedColors: Bool {
        if disableTajweedColors { return false }
        return settings.showTajweedColors
            && settings.showArabicText
            && settings.isHafsDisplay
    }

    private var searchArabicFontName: String {
        settings.quranArabicFontName(for: settings.displayQiraahForArabic)
    }

    private func arabicDisplayText() -> String {
        settings.beginnerMode ? arabic.map { String($0) }.joined(separator: " ") : arabic
    }

    private func arabicTajweedText() -> AttributedString? {
        guard shouldShowTajweedColors else { return nil }
        return TajweedStore.shared.attributedText(
            surah: surah,
            ayah: ayah,
            text: arabic,
            displayText: arabicDisplayText(),
            cleanDisplayText: settings.cleanArabicText,
            beginnerSpacing: settings.beginnerMode
        )
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

    private func normalizedSources() -> NormalizedSources {
        let key = "\(surah):\(ayah)|\(qiraahRefreshKey)|\(arabic.hashValue)|\(transliteration.hashValue)|\(englishSaheeh.hashValue)|\(englishMustafa.hashValue)" as NSString
        if let cached = Self.normalizedSourcesCache.object(forKey: key) {
            return cached
        }

        let sources = NormalizedSources(
            arabic: settings.cleanSearch(arabic, whitespace: false).removingArabicDiacriticsAndSigns,
            transliteration: settings.cleanSearch(transliteration, whitespace: false).removingArabicDiacriticsAndSigns,
            saheeh: settings.cleanSearch(englishSaheeh, whitespace: false).removingArabicDiacriticsAndSigns,
            mustafa: settings.cleanSearch(englishMustafa, whitespace: false).removingArabicDiacriticsAndSigns
        )
        Self.normalizedSourcesCache.setObject(sources, forKey: key)
        return sources
    }

    private func searchVisibility() -> SearchVisibility {
        let normalizedQuery = settings.cleanSearch(query, whitespace: true).removingArabicDiacriticsAndSigns
        let sources = normalizedSources()

        let mArabic = !normalizedQuery.isEmpty && sources.arabic.contains(normalizedQuery)
        let mTr = !normalizedQuery.isEmpty && sources.transliteration.contains(normalizedQuery)
        let mSaheeh = !normalizedQuery.isEmpty && sources.saheeh.contains(normalizedQuery)
        let mMustafa = !normalizedQuery.isEmpty && sources.mustafa.contains(normalizedQuery)
        let showArabicLine = settings.showArabicText || mArabic
        let showTrLine = settings.isHafsDisplay && (settings.showTransliteration || mTr)

        let showEnglishLines: (saheeh: Bool, mustafa: Bool) = {
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

        return SearchVisibility(
            mArabic: mArabic,
            mTr: mTr,
            mSaheeh: mSaheeh,
            mMustafa: mMustafa,
            showArabicLine: showArabicLine,
            showTrLine: showTrLine,
            showSaheehLine: showEnglishLines.saheeh,
            showMustafaLine: showEnglishLines.mustafa
        )
    }

    @ViewBuilder
    private func buildCompactSearchRow() -> some View {
        let visibility = searchVisibility()

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ayahReferenceBadge

                if visibility.showArabicLine {
                    HighlightedSnippet(
                        source: arabicDisplayText(),
                        term: visibility.mArabic ? query : "",
                        font: .custom(searchArabicFontName, size: UIFont.preferredFont(forTextStyle: .body).pointSize),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        preStyledSource: arabicTajweedText(),
                        beginnerMode: settings.beginnerMode
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .multilineTextAlignment(.trailing)
                }
            }

            if visibility.showTrLine {
                HighlightedSnippet(
                    source: transliteration,
                    term: visibility.mTr ? query : "",
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }

            if visibility.showSaheehLine {
                HighlightedSnippet(
                    source: englishSaheeh,
                    term: visibility.mSaheeh ? query : "",
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }

            if visibility.showMustafaLine {
                HighlightedSnippet(
                    source: englishMustafa,
                    term: visibility.mMustafa ? query : "",
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }

            pageJuzMetadata
        }
        .confirmationDialog(Settings.bookmarkNoteRemovalDialogTitle, isPresented: $confirmRemoveNote, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                settings.hapticFeedback()
                settings.toggleBookmark(surah: surah, ayah: ayah)
            }
            Button("Cancel") {}
        } message: {
            Text(Settings.bookmarkNoteRemovalDialogMessage)
        }
    }

    @ViewBuilder
    private func buildFullSearchRow() -> some View {
        let visibility = searchVisibility()

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ayahReferenceBadge

                Text(surahName)
            }
            .font(.caption)
            .foregroundColor(settings.accentColor.color)
            .transition(.opacity)

            if visibility.showArabicLine {
                HighlightedSnippet(
                    source: arabicDisplayText(),
                    term: visibility.mArabic ? query : "",
                    font: .custom(searchArabicFontName, size: UIFont.preferredFont(forTextStyle: .body).pointSize),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    preStyledSource: arabicTajweedText(),
                    beginnerMode: settings.beginnerMode
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
            }

            if visibility.showTrLine {
                HighlightedSnippet(
                    source: transliteration,
                    term: visibility.mTr ? query : "",
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }

            if visibility.showSaheehLine {
                HighlightedSnippet(
                    source: englishSaheeh,
                    term: visibility.mSaheeh ? query : "",
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }

            if visibility.showMustafaLine {
                HighlightedSnippet(
                    source: englishMustafa,
                    term: visibility.mMustafa ? query : "",
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }

            pageJuzMetadata
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
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
        l.page == r.page &&
        l.juz == r.juz &&
        l.favoriteSurahs == r.favoriteSurahs &&
        l.bookmarkedAyahs == r.bookmarkedAyahs
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
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
