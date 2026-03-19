import SwiftUI

struct QuranView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer
    
    @State private var searchText = ""
    @State private var isQuranSearchFocused = false
    @State private var scrollToSurahID: Int = -1
    @State private var showingSettingsSheet = false
    @State private var showListeningHistory = false
    @State private var showReadingHistory = false
    
    @State private var verseHits: [VerseIndexEntry] = []
    @State private var hasMoreHits = true
    @State private var blockAyahSearchAfterZero = false
    @State private var zeroResultQueryLength = 0
    private let hitPageSize = 5
        
    private static let arFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "ar")
        return f
    }()
    
    func arabicToEnglishNumber(_ arabicNumber: String) -> Int? {
        QuranView.arFormatter.number(from: arabicNumber)?.intValue
    }
    
    var lastReadSurah: Surah? {
        quranData.quran.first(where: { $0.id == settings.lastReadSurah })
    }

    var lastReadAyah: Ayah? {
        lastReadSurah?.ayahs.first(where: { $0.id == settings.lastReadAyah })
    }
    
    func getSurahAndAyah(from searchText: String) -> (surah: Surah?, ayah: Ayah?) {
        let surahAyahPair = searchText.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ":").map(String.init)
        var surahNumber: Int? = nil
        var ayahNumber: Int? = nil

        if surahAyahPair.count == 2 {
            if let s = Int(surahAyahPair[0]), (1...114).contains(s) {
                surahNumber = s
                ayahNumber = Int(surahAyahPair[1])
            } else if let s = arabicToEnglishNumber(surahAyahPair[0]), (1...114).contains(s) {
                surahNumber = s
                ayahNumber = arabicToEnglishNumber(surahAyahPair[1])
            }
        }

        if let sNum = surahNumber,
           let aNum = ayahNumber,
           let surah = quranData.quran.first(where: { $0.id == sNum }),
           let ayah = surah.ayahs.first(where: { $0.id == aNum }) {
            return (surah, ayah)
        }
        return (nil, nil)
    }

    private struct PageJuzQuery {
        let page: Int?
        let juz: Int?
        let isExplicitPage: Bool
        let isExplicitJuz: Bool
    }

    private func parsePageJuzQuery(from raw: String) -> PageJuzQuery {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return PageJuzQuery(page: nil, juz: nil, isExplicitPage: false, isExplicitJuz: false)
        }

        let lowered = trimmed.lowercased()

        if lowered.hasPrefix("page ") {
            let valueText = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
            let n = Int(valueText) ?? arabicToEnglishNumber(valueText)
            let validPage = (n != nil && (1...630).contains(n!)) ? n : nil
            return PageJuzQuery(page: validPage, juz: nil, isExplicitPage: true, isExplicitJuz: false)
        }

        if lowered.hasPrefix("juz ") {
            let valueText = String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
            let n = Int(valueText) ?? arabicToEnglishNumber(valueText)
            let validJuz = (n != nil && (1...30).contains(n!)) ? n : nil
            return PageJuzQuery(page: nil, juz: validJuz, isExplicitPage: false, isExplicitJuz: true)
        }

        let n = Int(trimmed) ?? arabicToEnglishNumber(trimmed)
        guard let n else {
            return PageJuzQuery(page: nil, juz: nil, isExplicitPage: false, isExplicitJuz: false)
        }

        let page = (1...630).contains(n) ? n : nil
        let juz = (1...30).contains(n) ? n : nil
        return PageJuzQuery(page: page, juz: juz, isExplicitPage: false, isExplicitJuz: false)
    }

    private func firstAyahResult(page: Int? = nil, juz: Int? = nil) -> (surah: Surah, ayah: Ayah)? {
        guard page != nil || juz != nil else { return nil }

        for surah in quranData.quran {
            let ayahsForQiraah = surah.ayahs.filter { $0.existsInQiraah(settings.displayQiraahForArabic) }
            if let hit = ayahsForQiraah.first(where: { a in
                (page != nil && a.page == page) || (juz != nil && a.juz == juz)
            }) {
                return (surah, hit)
            }
        }

        return nil
    }
    
    enum QuranRoute: Hashable {
        case ayahs(surahID: Int, ayah: Int?)
    }
    
    @State private var path: [QuranRoute] = []

    var useStackOnThisDevice: Bool {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            return UIDevice.current.userInterfaceIdiom == .phone
        }
        #endif
        return false
    }

    func push(surahID: Int, ayahID: Int? = nil) {
        #if os(iOS)
        if #available(iOS 16.0, *), useStackOnThisDevice {
            path.append(QuranRoute.ayahs(surahID: surahID, ayah: ayahID))
        }
        #endif
    }
    
    private func fetchHits(query: String, limit: Int, offset: Int) -> ([VerseIndexEntry], Bool) {
        let page = quranData.searchVerses(term: query, limit: limit + 1, offset: offset)
        let more = page.count > limit
        return (Array(page.prefix(limit)), more)
    }

    private var shouldShowSearchHelpOverlay: Bool {
        isQuranSearchFocused && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @ViewBuilder
    private var searchHelpOverlay: some View {
        if shouldShowSearchHelpOverlay {
            searchHelpOverlayCard
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: shouldShowSearchHelpOverlay)
        }
    }

    private var searchHelpOverlayCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Search for Surahs")
                .font(.subheadline.bold())
                .foregroundStyle(settings.accentColor.color)

            Text("Search by surah number, Arabic name, English translation, or transliteration.")
                .font(.caption)
                .foregroundStyle(.primary)

            Text("Search for Ayahs")
                .font(.subheadline.bold())
                .foregroundStyle(settings.accentColor.color)

            Text("Search ayah like X:Y, or by Arabic, English translation, and transliteration.")
                .font(.caption)
                .foregroundStyle(.primary)

            Text("Search by page or juz")
                .font(.subheadline.bold())
                .foregroundStyle(settings.accentColor.color)

            Text("Use 'page X', 'juz X', or plain numbers to match page/juz results.")
                .font(.caption)
                .foregroundStyle(.primary)

            Text("Tips")
                .font(.subheadline.bold())
                .foregroundStyle(settings.accentColor.color)

            Text("You can scroll to a surah from loaded surah or ayah results, and use the context menu on items to see more actions and info.")
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .conditionalGlassEffect()
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
     
    var body: some View {
        Group {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                if useStackOnThisDevice {
                    NavigationStack(path: $path) {
                        content
                            .navigationDestination(for: QuranRoute.self) { route in
                                switch route {
                                case let .ayahs(surahID, ayah):
                                    if let s = quranData.quran.first(where: { $0.id == surahID }) {
                                        AyahsView(surah: s, ayah: ayah)
                                    } else {
                                        AyahsView(surah: quranData.quran[0])
                                    }
                                }
                            }
                    }
                } else {
                    NavigationView {
                        content
                        detailFallback
                    }
                    .navigationViewStyle(.columns)
                }
            } else {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    NavigationView {
                        content
                        detailFallback
                    }
                    .navigationViewStyle(.columns)
                } else {
                    NavigationView { content }
                }
            }
            #else
            NavigationView { content }
            #endif
        }
        .confirmationDialog(
            quranPlayer.playbackAlertTitle,
            isPresented: $quranPlayer.showInternetAlert,
            titleVisibility: .visible
        ) { Button("OK", role: .cancel) { } } message: {
            Text(quranPlayer.playbackAlertMessage)
        }
    }
    
    var content: some View {
        ScrollViewReader { scrollProxy in
            let pageJuzQuery = parsePageJuzQuery(from: searchText)
            let explicitPageOrJuzMode = pageJuzQuery.isExplicitPage || pageJuzQuery.isExplicitJuz
            let pageSearchResult = firstAyahResult(page: pageJuzQuery.page)
            let juzSearchResult = firstAyahResult(juz: pageJuzQuery.juz)

            List {
            let favoriteSurahs = Set(settings.favoriteSurahs)
            let bookmarkedAyahs = Set(settings.bookmarkedAyahs.map(\.id))
            
            #if !os(watchOS)
            if searchText.isEmpty, let surah = settings.lastListenedSurah {
                LastListenedSurahRow(
                    lastListenedSurah: surah,
                    favoriteSurahs: favoriteSurahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID,
                    showListeningHistory: $showListeningHistory
                )
            }
            #else
            NowPlayingView(quranView: true)
            #endif

            if searchText.isEmpty, let lastReadSurah = lastReadSurah, let lastReadAyah = lastReadAyah {
                LastReadAyahRow(
                    surah: lastReadSurah,
                    ayah: lastReadAyah,
                    favoriteSurahs: favoriteSurahs,
                    bookmarkedAyahs: bookmarkedAyahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID,
                    showReadingHistory: $showReadingHistory
                )
            }
            
            if !settings.bookmarkedAyahs.isEmpty && searchText.isEmpty {
                Section(header:
                    HStack {
                        Text("BOOKMARKED AYAHS")
                    
                        Spacer()
                    
                        Image(systemName: settings.showBookmarks ? "chevron.down" : "chevron.up")
                            .foregroundColor(settings.accentColor.color)
                            .onTapGesture {
                                settings.hapticFeedback()
                                withAnimation { settings.showBookmarks.toggle() }
                            }
                            .buttonStyle(.plain)
                            .clipShape(Rectangle())
                    }
                ) {
                    if settings.showBookmarks {
                        ForEach(settings.bookmarkedAyahs.sorted {
                            $0.surah == $1.surah ? ($0.ayah < $1.ayah) : ($0.surah < $1.surah)
                        }, id: \.id) { bookmarkedAyah in
                            if let surah = quranData.quran.first(where: { $0.id == bookmarkedAyah.surah }),
                               let ayah = surah.ayahs.first(where: { $0.id == bookmarkedAyah.ayah }) {
                                
                                let noteText = bookmarkedAyah.note?.trimmingCharacters(in: .whitespacesAndNewlines)
                                let noteToShow = (noteText?.isEmpty == false) ? noteText : nil
                                
                                Group {
                                    #if !os(watchOS)
                                    Button {
                                        push(surahID: bookmarkedAyah.surah, ayahID: bookmarkedAyah.ayah)
                                    } label: {
                                        NavigationLink(destination: AyahsView(surah: surah, ayah: ayah.id)) {
                                            SurahAyahRow(surah: surah, ayah: ayah, note: noteToShow)
                                        }
                                    }
                                    #else
                                    NavigationLink(destination: AyahsView(surah: surah, ayah: ayah.id)) {
                                        SurahAyahRow(surah: surah, ayah: ayah, note: noteToShow)
                                    }
                                    #endif
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
                                    bookmarkedSurah: bookmarkedAyah.surah,
                                    bookmarkedAyah: bookmarkedAyah.ayah
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
                    }
                }
            }
            
            if !settings.favoriteSurahs.isEmpty && searchText.isEmpty {
                Section(header:
                    HStack {
                        Text("FAVORITE SURAHS")
                    
                        Spacer()
                    
                        Image(systemName: settings.showFavorites ? "chevron.down" : "chevron.up")
                            .foregroundColor(settings.accentColor.color)
                            .onTapGesture {
                                settings.hapticFeedback()
                                withAnimation { settings.showFavorites.toggle() }
                            }
                            .buttonStyle(.plain)
                            .clipShape(Rectangle())
                    }
                ) {
                    if settings.showFavorites {
                        ForEach(settings.favoriteSurahs.sorted(), id: \.self) { surahID in
                            if let surah = quranData.quran.first(where: { $0.id == surahID }) {
                                Group {
                                    #if !os(watchOS)
                                    Button {
                                        push(surahID: surahID)
                                    } label: {
                                        NavigationLink(destination: AyahsView(surah: surah)) {
                                            SurahRow(surah: surah)
                                        }
                                    }
                                    #else
                                    NavigationLink(destination: AyahsView(surah: surah)) {
                                        SurahRow(surah: surah)
                                    }
                                    #endif
                                }
                                .rightSwipeActions(
                                    surahID: surahID,
                                    surahName: surah.nameTransliteration,
                                    searchText: $searchText,
                                    scrollToSurahID: $scrollToSurahID
                                )
                                .leftSwipeActions(surah: surah.id, favoriteSurahs: favoriteSurahs)
                                #if !os(watchOS)
                                .contextMenu {
                                    SurahContextMenu(
                                        surahID: surah.id,
                                        surahName: surah.nameTransliteration,
                                        favoriteSurahs: favoriteSurahs,
                                        searchText: $searchText,
                                        scrollToSurahID: $scrollToSurahID
                                    )
                                }
                                #endif
                            }
                        }
                    }
                }
            }
            
            if !explicitPageOrJuzMode {
                if settings.groupBySurah || (!searchText.isEmpty && settings.searchForSurahs) {
                let cleanedSearch = settings.cleanSearch(searchText.replacingOccurrences(of: ":", with: ""))
                let surahAyahPair = searchText.split(separator: ":").map(String.init)
                let upperQuery = searchText.uppercased()
                let numericQuery: Int? = {
                    if surahAyahPair.count == 2 {
                        return Int(surahAyahPair[0]) ?? arabicToEnglishNumber(surahAyahPair[0])
                    } else {
                        return Int(cleanedSearch) ?? arabicToEnglishNumber(cleanedSearch)
                    }
                }()

                let filteredSurahs: [Surah] = quranData.quran.filter { surah in
                    if let n = numericQuery, n == surah.id { return true }
                    if searchText.isEmpty { return true }
                    return upperQuery.contains(surah.nameEnglish.uppercased())                     ||
                           upperQuery.contains(surah.nameTransliteration.uppercased())             ||
                           settings.cleanSearch(surah.nameArabic).contains(cleanedSearch)          ||
                           settings.cleanSearch(surah.nameTransliteration).contains(cleanedSearch) ||
                           settings.cleanSearch(surah.nameEnglish).contains(cleanedSearch)         ||
                           settings.cleanSearch(String(surah.id)).contains(cleanedSearch)          ||
                           settings.cleanSearch(surah.idArabic).contains(cleanedSearch)
                }

                Section(header:
                    Group {
                        if searchText.isEmpty {
                            SurahsHeader()
                        } else {
                            HStack {
                                Text("SURAH SEARCH RESULTS")
                                
                                Spacer()
                                
                                Text("\(filteredSurahs.count)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(settings.accentColor.color)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    #if !os(watchOS)
                                    .background(.ultraThinMaterial)
                                    #endif
                                    .clipShape(Capsule())
                            }
                            .padding(.vertical, 4)
                        }
                    }
                ) {
                    ForEach(filteredSurahs, id: \.id) { surah in
                        NavigationLink(destination: AyahsView(surah: surah)) {
                            SurahRow(surah: surah)
                        }
                        .id("surah_\(surah.id)")
                        .onAppear {
                            if surah.id == scrollToSurahID {
                                scrollToSurahID = -1
                            }
                        }
                        .rightSwipeActions(
                            surahID: surah.id,
                            surahName: surah.nameTransliteration,
                            searchText: $searchText,
                            scrollToSurahID: $scrollToSurahID
                        )
                        .leftSwipeActions(surah: surah.id, favoriteSurahs: favoriteSurahs)
                        #if !os(watchOS)
                        .contextMenu {
                            SurahContextMenu(
                                surahID: surah.id,
                                surahName: surah.nameTransliteration,
                                favoriteSurahs: favoriteSurahs,
                                searchText: $searchText,
                                scrollToSurahID: $scrollToSurahID
                            )
                        }
                        #endif
                        .animation(.easeInOut, value: searchText)
                    }
                }
            } else {
                ForEach(QuranData.juzList, id: \.id) { juz in
                    Section(header: JuzHeader(juz: juz)) {
                        let surahsInRange = quranData.quran.filter {
                            $0.id >= juz.startSurah && $0.id <= juz.endSurah
                        }
                        ForEach(surahsInRange, id: \.id) { surah in
                            let startAyah = (surah.id == juz.startSurah) ? juz.startAyah : 1
                            let endAyah = (surah.id == juz.endSurah) ? juz.endAyah : surah.numberOfAyahs
                            let singleSurah = (juz.startSurah == surah.id && juz.endSurah == surah.id)
                            
                            Group {
                                if singleSurah {
                                    if startAyah > 1 {
                                        NavigationLink(destination: AyahsView(surah: surah, ayah: startAyah)) {
                                            SurahRow(surah: surah, ayah: startAyah)
                                        }
                                    } else {
                                        NavigationLink(destination: AyahsView(surah: surah)) {
                                            SurahRow(surah: surah, ayah: startAyah)
                                        }
                                    }
                                    if endAyah < surah.numberOfAyahs {
                                        NavigationLink(destination: AyahsView(surah: surah, ayah: endAyah)) {
                                            SurahRow(surah: surah, ayah: endAyah, end: true)
                                        }
                                    } else {
                                        NavigationLink(destination: AyahsView(surah: surah)) {
                                            SurahRow(surah: surah)
                                        }
                                    }
                                } else if surah.id == juz.startSurah {
                                    if startAyah > 1 {
                                        NavigationLink(destination: AyahsView(surah: surah, ayah: startAyah)) {
                                            SurahRow(surah: surah, ayah: startAyah)
                                        }
                                    } else {
                                        NavigationLink(destination: AyahsView(surah: surah)) {
                                            SurahRow(surah: surah, ayah: startAyah)
                                        }
                                    }
                                } else if surah.id == juz.endSurah {
                                    if surah.id == 114 {
                                        NavigationLink(destination: AyahsView(surah: surah)) {
                                            SurahRow(surah: surah)
                                        }
                                    } else if endAyah < surah.numberOfAyahs {
                                        NavigationLink(destination: AyahsView(surah: surah, ayah: endAyah)) {
                                            SurahRow(surah: surah, ayah: endAyah, end: true)
                                        }
                                    } else {
                                        NavigationLink(destination: AyahsView(surah: surah)) {
                                            SurahRow(surah: surah)
                                        }
                                    }
                                } else {
                                    NavigationLink(destination: AyahsView(surah: surah)) {
                                        SurahRow(surah: surah)
                                    }
                                }
                            }
                            .id("surah_\(surah.id)")
                            #if !os(watchOS)
                            .rightSwipeActions(
                                surahID: surah.id,
                                surahName: surah.nameTransliteration,
                                searchText: $searchText,
                                scrollToSurahID: $scrollToSurahID
                            )
                            .leftSwipeActions(surah: surah.id, favoriteSurahs: favoriteSurahs)
                            .contextMenu {
                                SurahContextMenu(
                                    surahID: surah.id,
                                    surahName: surah.nameTransliteration,
                                    favoriteSurahs: favoriteSurahs,
                                    searchText: $searchText,
                                    scrollToSurahID: $scrollToSurahID
                                )
                            }
                            #endif
                        }
                    }
                    .sectionIndexLabelWhenAvailable("\(juz.id)")
                }
            }
            }
            
            if !searchText.isEmpty {
                if let page = pageJuzQuery.page, let pageResult = pageSearchResult {
                    Section(header:
                        HStack {
                            Text("PAGE SEARCH RESULT")

                            Spacer()

                            Text("Page \(page)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(settings.accentColor.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                #if !os(watchOS)
                                .background(.ultraThinMaterial)
                                #endif
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 4)
                    ) {
                        AyahSearchResultRow(
                            surah: pageResult.surah,
                            ayah: pageResult.ayah,
                            favoriteSurahs: favoriteSurahs,
                            bookmarkedAyahs: bookmarkedAyahs,
                            searchText: $searchText,
                            scrollToSurahID: $scrollToSurahID
                        )
                    }
                }

                if let juz = pageJuzQuery.juz, let juzResult = juzSearchResult {
                    Section(header:
                        HStack {
                            Text("JUZ SEARCH RESULT")

                            Spacer()

                            Text("Juz \(juz)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(settings.accentColor.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                #if !os(watchOS)
                                .background(.ultraThinMaterial)
                                #endif
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 4)
                    ) {
                        AyahSearchResultRow(
                            surah: juzResult.surah,
                            ayah: juzResult.ayah,
                            favoriteSurahs: favoriteSurahs,
                            bookmarkedAyahs: bookmarkedAyahs,
                            searchText: $searchText,
                            scrollToSurahID: $scrollToSurahID
                        )
                    }
                }

                if !explicitPageOrJuzMode {
                let searchResult = getSurahAndAyah(from: searchText)
                let surah = searchResult.surah
                let ayah = searchResult.ayah
                
                let exactMatchBump = (surah != nil && ayah != nil) ? 1 : 0
                let canShowNext = hasMoreHits && !verseHits.isEmpty
                let ayahCount = verseHits.count + exactMatchBump
                let ayahCountStr = "\(ayahCount)\(canShowNext ? "+" : "")"
                
                Section(header:
                    HStack {
                        Text("AYAH SEARCH RESULTS")
                    
                        Spacer()
                    
                        Text(ayahCountStr)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(settings.accentColor.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            #if !os(watchOS)
                            .background(.ultraThinMaterial)
                            #endif
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 4)
                ) {
                    if let surah = surah, let ayah = ayah {
                        AyahSearchResultRow(
                            surah: surah,
                            ayah: ayah,
                            favoriteSurahs: favoriteSurahs,
                            bookmarkedAyahs: bookmarkedAyahs,
                            searchText: $searchText,
                            scrollToSurahID: $scrollToSurahID
                        )
                    }
                    
                    ForEach(verseHits) { hit in
                        if let surah = quranData.surah(hit.surah), let ayah = quranData.ayah(surah: hit.surah, ayah: hit.ayah) {
                            NavigationLink {
                                AyahsView(surah: surah, ayah: ayah.id)
                            } label: {
                                AyahSearchRow(
                                    surahName: surah.nameTransliteration,
                                    surah: hit.surah,
                                    ayah: hit.ayah,
                                    query: searchText,
                                    arabic: ayah.displayArabicText(surahId: hit.surah, clean: settings.cleanArabicText),
                                    transliteration: ayah.textTransliteration,
                                    englishSaheeh: ayah.textEnglishSaheeh,
                                    englishMustafa: ayah.textEnglishMustafa,
                                    favoriteSurahs: favoriteSurahs,
                                    bookmarkedAyahs: bookmarkedAyahs,
                                    searchText: $searchText,
                                    scrollToSurahID: $scrollToSurahID
                                )
                            }
                        }
                    }

                    if canShowNext {
                        #if !os(watchOS)
                        Menu("Load more ayah matches") {
                            ForEach([5, 10, 20], id: \.self) { amount in
                                Button("Load \(amount)") {
                                    settings.hapticFeedback()
                                    let (moreHits, moreAvail) = fetchHits(
                                        query: searchText,
                                        limit: amount,
                                        offset: verseHits.count
                                    )
                                    withAnimation {
                                        verseHits.append(contentsOf: moreHits)
                                        hasMoreHits = moreAvail
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        #else
                        if hasMoreHits && !verseHits.isEmpty {
                            Button("Load \(hitPageSize) ayah matches") {
                                let (moreHits, moreAvail) = fetchHits(query: searchText, limit: hitPageSize, offset: verseHits.count)
                                withAnimation {
                                    verseHits.append(contentsOf: moreHits)
                                    hasMoreHits = moreAvail
                                }
                            }
                            .foregroundColor(settings.accentColor.color)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                        }
                        #endif

                        Button {
                            settings.hapticFeedback()
                            withAnimation {
                                verseHits = quranData.searchVersesAll(term: searchText)
                                hasMoreHits = false
                            }
                        } label: {
                            Text("Load all ayah matches")
                                .foregroundColor(settings.accentColor.color)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                    }
                }
                .onChange(of: searchText) { txt in
                    let q = txt.trimmingCharacters(in: .whitespacesAndNewlines)

                    guard !q.isEmpty else {
                        withAnimation {
                            verseHits = []
                            hasMoreHits = false
                            blockAyahSearchAfterZero = false
                        }
                        return
                    }

                    if blockAyahSearchAfterZero {
                        if q.count < zeroResultQueryLength {
                            blockAyahSearchAfterZero = false
                        } else if q.count > zeroResultQueryLength {
                            return
                        }
                    }

                    let (first, more) = fetchHits(query: q, limit: hitPageSize, offset: 0)
                    withAnimation {
                        verseHits = first
                        hasMoreHits = more
                        if first.isEmpty {
                            blockAyahSearchAfterZero = true
                            zeroResultQueryLength = q.count
                        } else {
                            blockAyahSearchAfterZero = false
                        }
                    }
                }
                }
            }
        }
        .applyConditionalListStyle(defaultView: settings.defaultView)
        .dismissKeyboardOnScroll()
        .listSectionIndexVisibilityWhenAvailable(visible: !settings.groupBySurah && searchText.isEmpty)
        #if os(watchOS)
        .searchable(text: $searchText)
        #endif
        .onChange(of: scrollToSurahID) { id in
            if id > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation { scrollProxy.scrollTo("surah_\(id)", anchor: .top) }
                }
            }
        }
        .overlay(alignment: .top) {
            searchHelpOverlay
        }
        }
        .navigationTitle("Al-Quran")
        #if !os(watchOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    settings.hapticFeedback()
                    showingSettingsSheet = true
                } label: { Image(systemName: "gear") }
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            NavigationView { SettingsQuranView(showEdits: false) }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 4) {
                if isQuranSearchFocused && !settings.quranSearchHistory.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(settings.quranSearchHistory, id: \.self) { query in
                                HStack(spacing: 4) {
                                    Button {
                                        settings.hapticFeedback()
                                        searchText = query
                                        settings.addQuranSearchHistory(query)
                                        self.endEditing()
                                    } label: {
                                        Text(query)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                    }

                                    Button {
                                        settings.hapticFeedback()
                                        settings.removeQuranSearchHistory(query)
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.caption2.bold())
                                            .padding(.trailing, 4)
                                    }
                                    .accessibilityLabel("Remove \(query) from search history")
                                }
                                .foregroundStyle(settings.accentColor.color)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(settings.accentColor.color.opacity(0.12))
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(settings.accentColor.color.opacity(0.25), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
                
                if quranPlayer.isPlaying || quranPlayer.isPaused {
                    NowPlayingView(quranView: true, scrollDown: $scrollToSurahID, searchText: $searchText)
                        .padding(.bottom, 8)
                }
                
                Picker("Sort Type", selection: $settings.groupBySurah.animation(.easeInOut)) {
                    Text("Sort by Surah").tag(true)
                    Text("Sort by Juz").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 8)
                
                HStack {
                    SearchBar(
                        text: $searchText.animation(.easeInOut),
                        onSearchButtonClicked: {
                            settings.addQuranSearchHistory(searchText)
                        },
                        onFocusChanged: { focused in
                            withAnimation {
                                isQuranSearchFocused = focused
                            }
                        }
                    )
                    
                    if quranPlayer.isLoading || quranPlayer.isPlaying || quranPlayer.isPaused {
                        Button {
                            settings.hapticFeedback()
                            if quranPlayer.isLoading {
                                quranPlayer.isLoading = false
                                quranPlayer.pause(saveInfo: false)
                            } else {
                                quranPlayer.stop()
                            }
                        } label: {
                            if quranPlayer.isLoading {
                                RotatingGearView().transition(.opacity)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(settings.accentColor.color)
                                    .transition(.opacity)
                            }
                        }
                        .padding(.trailing, 28)
                    } else {
                        Menu {
                            if let last = settings.lastListenedSurah, let surah = quranData.quran.first(where: { $0.id == last.surahNumber }) {
                                Button {
                                    settings.hapticFeedback()
                                    quranPlayer.playSurah(
                                        surahNumber: last.surahNumber,
                                        surahName: last.surahName,
                                        certainReciter: true
                                    )
                                } label: {
                                    Label("Play Last Listened Surah (\(surah.nameTransliteration))", systemImage: "play.fill")
                                }
                            }
                            
                            Button {
                                settings.hapticFeedback()
                                if let randomSurah = quranData.quran.randomElement() {
                                    quranPlayer.playSurah(surahNumber: randomSurah.id, surahName: randomSurah.nameTransliteration)
                                } else {
                                    let n = Int.random(in: 1...114)
                                    let name = quranData.quran.first(where: { $0.id == n })?.nameTransliteration ?? "Random Surah"
                                    quranPlayer.playSurah(surahNumber: n, surahName: name)
                                }
                            } label: {
                                Label("Play Random Surah", systemImage: "shuffle")
                            }
                            
                            Button {
                                settings.hapticFeedback()
                                
                                if let randomSurah = quranData.quran.randomElement() {
                                    if let randomAyah = randomSurah.ayahs.randomElement() {
                                        quranPlayer.playAyah(
                                            surahNumber: randomSurah.id,
                                            ayahNumber: randomAyah.id,
                                            continueRecitation: true
                                        )
                                    }
                                }
                            } label: {
                                Label("Play Random Ayah", systemImage: "shuffle.circle.fill")
                            }
                        } label: {
                            Image(systemName: "play.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                                .foregroundColor(settings.accentColor.color)
                                .transition(.opacity)
                        }
                        .padding(.trailing, 28)
                    }
                }
            }
            .padding(.top, 8)
            .conditionalGlassEffect()
            .padding([.horizontal, .bottom])
            .animation(.easeInOut, value: quranPlayer.isPlaying)
        }
        #endif
    }
    
    @ViewBuilder
    var detailFallback: some View {
        if let lastSurah = lastReadSurah, let lastAyah = lastReadAyah {
            AyahsView(surah: lastSurah, ayah: lastAyah.id)
        } else if !settings.bookmarkedAyahs.isEmpty {
            let first = settings.bookmarkedAyahs.sorted {
                $0.surah == $1.surah ? ($0.ayah < $1.ayah) : ($0.surah < $1.surah)
            }.first
            let surah = quranData.quran.first(where: { $0.id == first?.surah })
            let ayah = surah?.ayahs.first(where: { $0.id == first?.ayah })
            if let s = surah, let a = ayah { AyahsView(surah: s, ayah: a.id) }
        } else if let firstFav = settings.favoriteSurahs.sorted().first, let surah = quranData.quran.first(where: { $0.id == firstFav }) {
            AyahsView(surah: surah)
        } else {
            AyahsView(surah: quranData.quran[0])
        }
    }

}

// MARK: - iOS 26+ Section index for Juz fast-scroll
private extension View {
    @ViewBuilder
    func sectionIndexLabelWhenAvailable(_ label: String) -> some View {
        if #available(iOS 26.0, watchOS 26.0, *) {
            sectionIndexLabel(label)
        } else {
            self
        }
    }

    @ViewBuilder
    func listSectionIndexVisibilityWhenAvailable(visible: Bool) -> some View {
        if #available(iOS 26.0, watchOS 26.0, *) {
            listSectionIndexVisibility(.visible)
        } else {
            self
        }
    }
}

#Preview {
    QuranView()
        .environmentObject(Settings.shared)
        .environmentObject(QuranData.shared)
        .environmentObject(QuranPlayer.shared)
}
