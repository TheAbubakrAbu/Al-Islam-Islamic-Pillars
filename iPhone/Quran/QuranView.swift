import SwiftUI

struct QuranView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var isQuranSearchFocused = false
    @State private var scrollToSurahID: Int = -1
    @State private var showingSettingsSheet = false
    @State private var showReciterPickerSheet = false
    @State private var showListeningHistory = false
    @State private var showReadingHistory = false
    @State private var searchTextAtFocusStart = ""
    @State private var lastSavedSearchQuery = ""
    @State private var isListMoving = false
    @State private var listMotionIdleTask: Task<Void, Never>?
    @State private var showAyahSearchLearnMore = false

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
        quranData.surah(settings.lastReadSurah)
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
           let surah = quranData.surah(sNum),
           let ayah = quranData.ayah(surah: sNum, ayah: aNum) {
            return (surah, ayah)
        }
        return (nil, nil)
    }
    
    /// Verse hits sorted by surah, then ayah (search results are always grouped by surah).
    private var verseHitsGroupedBySurah: [(surahId: Int, hits: [VerseIndexEntry])] {
        var grouped = [Int: [VerseIndexEntry]]()
        var orderedSurahIDs: [Int] = []

        for hit in verseHits {
            if grouped[hit.surah] == nil {
                grouped[hit.surah] = []
                orderedSurahIDs.append(hit.surah)
            }
            grouped[hit.surah, default: []].append(hit)
        }

        return orderedSurahIDs.compactMap { sid in
            guard let hits = grouped[sid] else { return nil }
            return (sid, hits)
        }
    }

    private struct PageJuzQuery {
        let page: Int?
        let juz: Int?
        let isExplicitPage: Bool
        let isExplicitJuz: Bool
    }

    private struct SearchDisplayContext {
        let isSearching: Bool
        let favoriteSurahs: Set<Int>
        let bookmarkedAyahs: Set<String>
        let pageJuzQuery: PageJuzQuery
        let explicitPageOrJuzMode: Bool
        let pageSearchResult: (surah: Surah, ayah: Ayah)?
        let juzSearchResult: (surah: Surah, ayah: Ayah)?
        let exactMatch: (surah: Surah?, ayah: Ayah?)
        let surahCountQuery: SurahCountQuery?
        let filteredSurahs: [Surah]
        let canShowMoreAyahHits: Bool
        let ayahCountDisplayText: String
    }

    private struct SurahCountQuery {
        let ayahs: Int?
        let pages: Int?

        var hasAny: Bool { ayahs != nil || pages != nil }
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
        quranData.firstAyahResult(page: page, juz: juz)
    }

    private func parseSurahCountQuery(from raw: String) -> SurahCountQuery? {
        let parts = raw
            .lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)

        guard parts.count >= 2 else { return nil }

        let ayahUnits: Set<String> = ["ayah", "ayahs", "aayah", "aayahs", "ay"]
        let pageUnits: Set<String> = ["page", "pages", "pg", "pgs"]

        var ayahs: Int? = nil
        var pages: Int? = nil

        for idx in 0..<(parts.count - 1) {
            let numberToken = parts[idx]
            let unit = parts[idx + 1]
            guard let value = Int(numberToken) ?? arabicToEnglishNumber(numberToken), value >= 1 else { continue }

            if ayahUnits.contains(unit) {
                ayahs = value
            } else if pageUnits.contains(unit) {
                pages = value
            }
        }

        let query = SurahCountQuery(ayahs: ayahs, pages: pages)
        return query.hasAny ? query : nil
    }

    private func filteredSurahs(for query: String, countQuery: SurahCountQuery?) -> [Surah] {
        guard let countQuery else {
            return quranData.filteredSurahs(query: query)
        }

        return quranData.quran.filter { surah in
            let ayahMatches: Bool = {
                guard let requestedAyahs = countQuery.ayahs else { return true }
                return surah.numberOfAyahs == requestedAyahs
            }()

            let pageMatches: Bool = {
                guard let requestedPages = countQuery.pages else { return true }
                if requestedPages == 1 {
                    // Include explicit <1-page surahs in 1-page count search.
                    return surah.pageCount == 1 || surah.isLessThanOnePage == true
                }
                return surah.pageCount == requestedPages
            }()

            return ayahMatches && pageMatches
        }
    }

    private func persistQuranSearchHistoryIfNeeded(_ rawQuery: String, requireMinLength: Bool = false) {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if requireMinLength && trimmed.count < 3 { return }

        // Avoid repeatedly writing the same query while user is editing.
        if lastSavedSearchQuery.caseInsensitiveCompare(trimmed) == .orderedSame { return }

        settings.addQuranSearchHistory(trimmed)
        lastSavedSearchQuery = trimmed
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
        isQuranSearchFocused
            && !isListMoving
            && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func markListMoving() {
        listMotionIdleTask?.cancel()
        if !isListMoving {
            isListMoving = true
        }
    }

    private func markListStaticSoon() {
        listMotionIdleTask?.cancel()
        listMotionIdleTask = Task {
            try? await Task.sleep(nanoseconds: 220_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                isListMoving = false
            }
        }
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
            Text("Quick Search Help")
                .font(.subheadline.bold())
                .foregroundStyle(settings.accentColor.color)

            VStack(alignment: .leading, spacing: 4) {
                Text("• Surah: number, Arabic, English, or transliteration")
                Text("• Ayah: X:Y or text (Arabic/English/transliteration)")
                Text("• Page/Juz: 'page X', 'juz X', or plain numbers")
                Text("• Counts: '286 ayahs' or '48 pages'")
            }
            .font(.caption)
            .foregroundStyle(.primary)

            Button {
                settings.hapticFeedback()
                withAnimation {
                    showAyahSearchLearnMore.toggle()
                }
            } label: {
                Label(showAyahSearchLearnMore ? "Hide Ayah Search Guide" : "Ayah Search Guide", systemImage: "text.magnifyingglass")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)
            }
            .buttonStyle(.plain)

            if showAyahSearchLearnMore {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Boolean operators: & (AND), | (OR), ! (NOT)")
                    Text("Use #Arabic for normalized letters + matching tashkeel")
                    Text("Use #English for exact phrase (case-insensitive)")
                    Text("Use ^term for starts-with and term% for ends-with")
                    Text("Use count filters: 'X ayahs', 'X pages', or both")
                    Text("Example: ^Allah & mercy%")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .conditionalGlassEffect(rectangle: true)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var loadingFallbackView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading Quran...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var body: some View {
        navigationContainer
        .confirmationDialog(
            quranPlayer.playbackAlertTitle,
            isPresented: $quranPlayer.showInternetAlert,
            titleVisibility: .visible
        ) { Button("OK") { } } message: {
            Text(quranPlayer.playbackAlertMessage)
        }
    }
    
    private var navigationContainer: some View {
        Group {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                if useStackOnThisDevice {
                    stackNavigation
                } else {
                    splitNavigation
                }
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                legacyPadNavigation
            } else {
                legacyPhoneNavigation
            }
            #else
            NavigationView { content }
            #endif
        }
    }

    @available(iOS 16.0, *)
    private var stackNavigation: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: QuranRoute.self) { route in
                    routeDestination(route)
                }
        }
    }

    @available(iOS 16.0, *)
    private var splitNavigation: some View {
        NavigationSplitView {
            content
        } detail: {
            detailFallback
        }
    }

    private var legacyPadNavigation: some View {
        NavigationView {
            content
            detailFallback
        }
        #if os(iOS)
        .navigationViewStyle(.columns)
        #endif
    }

    private var legacyPhoneNavigation: some View {
        NavigationView {
            content
        }
    }

    @ViewBuilder
    private func routeDestination(_ route: QuranRoute) -> some View {
        switch route {
        case let .ayahs(surahID, ayah):
            if let surah = quranData.surah(surahID) {
                AyahsView(surah: surah, ayah: ayah)
            } else {
                loadingFallbackView
            }
        }
    }
    
    var content: some View {
        ScrollViewReader { scrollProxy in
            let context = searchDisplayContext

            List {
                primaryHistorySections(context: context)
                bookmarkSection(context: context)
                favoriteSection(context: context)
                if context.explicitPageOrJuzMode && context.isSearching {
                    pageSearchSection(context: context)
                    juzSearchSection(context: context)
                }
                surahContentSections(context: context)
                searchResultSections(context: context)
            }
            .applyConditionalListStyle(defaultView: settings.defaultView)
            .listSectionIndexVisibilityWhenAvailable(visible: settings.quranSortMode == .juz && searchText.isEmpty)
            .animation(.easeInOut(duration: 0.22), value: settings.quranSortMode)
            #if os(watchOS)
            .searchable(text: $searchText)
            #endif
            .onChange(of: scrollToSurahID) { id in
                guard id > 0 else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        scrollProxy.scrollTo("surah_\(id)", anchor: .top)
                    }
                }
            }
            
        }
        .navigationTitle("Al-Quran")
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                settingsButton
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            NavigationView { SettingsQuranView(showEdits: false, presentedAsSheet: true) }
        }
        .sheet(isPresented: $showReciterPickerSheet) {
            NavigationView {
                ReciterListView(dismissAfterSelectingReciter: true, autoScrollToInitialSelection: false)
                    .environmentObject(settings)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showReciterPickerSheet = false
                            }
                        }
                    }
            }
            .navigationViewStyle(.stack)
            .modifier(QuranReciterPickerSheetPresentationModifier())
        }
        .onDisappear {
            withAnimation {
                persistQuranSearchHistoryIfNeeded(searchText)
            }
        }
        .onChange(of: settings.displayQiraah) { _ in
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                handleAyahSearchChange(searchText)
            }
        }
        .overlay(alignment: .top) {
            searchHelpOverlay
        }
        .adaptiveSafeArea(edge: .bottom) {
            bottomControls
        }
        #endif
    }

    private var settingsButton: some View {
        Button {
            settings.hapticFeedback()
            showingSettingsSheet = true
        } label: {
            Image(systemName: "gear")
        }
    }

    private var bottomControls: some View {
        #if os(iOS)
        VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
            searchHistoryChips
            nowPlayingInset
            sortModePicker
            searchAndPlaybackRow
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .background(Color.white.opacity(0.00001))
        .animation(.easeInOut, value: quranPlayer.isPlaying)
        #else
        EmptyView()
        #endif
    }

    @ViewBuilder
    private var searchHistoryChips: some View {
        #if os(iOS)
        if isQuranSearchFocused && !settings.quranSearchHistory.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(settings.quranSearchHistory, id: \.self) { query in
                        searchHistoryChip(query: query)
                    }
                }
            }
        }
        #endif
    }

    private func searchHistoryChip(query: String) -> some View {
        HStack(spacing: 4) {
            Button {
                settings.hapticFeedback()
                withAnimation {
                    searchText = query
                    settings.addQuranSearchHistory(query)
                    self.endEditing()
                }
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
                    .padding(.trailing, 8)
            }
        }
        .foregroundStyle(settings.accentColor.color)
        .conditionalGlassEffect(useColor: 0.25)
    }

    @ViewBuilder
    private var nowPlayingInset: some View {
        #if os(iOS)
        if quranPlayer.isPlaying || quranPlayer.isPaused {
            NowPlayingView(quranView: true, scrollDown: $scrollToSurahID, searchText: $searchText)
        }
        #endif
    }

    private var sortModePicker: some View {
        #if os(iOS)
        Picker("Sort Type", selection: Binding(
            get: { settings.quranSortMode },
            set: { newMode in
                withAnimation(.easeInOut(duration: 0.22)) {
                    settings.quranSortMode = newMode
                }
            }
        ).animation(.easeInOut)) {
            Text("Surah").tag(Settings.QuranSortMode.surah)
            Text("Juz").tag(Settings.QuranSortMode.juz)
            Text("Revelation").tag(Settings.QuranSortMode.revelation)
        }
        .pickerStyle(SegmentedPickerStyle())
        .conditionalGlassEffect()
        #else
        EmptyView()
        #endif
    }

    private var searchAndPlaybackRow: some View {
        #if os(iOS)
        HStack(spacing: 0) {
            quranSearchBar

            playbackMenuButton
                .frame(width: 27, height: 27)
                .padding()
                .conditionalGlassEffect()
                .padding(.bottom, 2)
        }
        .padding([.leading, .top], -8)
        #else
        EmptyView()
        #endif
    }

    private var quranSearchBar: some View {
        #if os(iOS)
        SearchBar(
            text: $searchText.animation(.easeInOut),
            onSearchButtonClicked: {
                self.endEditing()
            },
            onFocusChanged: { focused in
                withAnimation {
                    isQuranSearchFocused = focused
                }
                if focused {
                    searchTextAtFocusStart = searchText
                }
                if !focused {
                    if searchTextAtFocusStart.caseInsensitiveCompare(searchText) != .orderedSame {
                        persistQuranSearchHistoryIfNeeded(searchText, requireMinLength: true)
                    }
                }
            }
        )
        #else
        EmptyView()
        #endif
    }

    private var playbackMenuButton: some View {
        #if os(iOS)
        VStack {
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
                            .foregroundColor(settings.accentColor.color)
                            .transition(.opacity)
                    }
                }
            } else {
                Menu {
                    playbackMenuContent
                } label: {
                    Image(systemName: "play.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(settings.accentColor.color)
                        .transition(.opacity)
                }
            }
        }
        #else
        EmptyView()
        #endif
    }

    @ViewBuilder
    private var playbackMenuContent: some View {
        #if os(iOS)
        if let last = settings.lastListenedSurah,
              let surah = quranData.surah(last.surahNumber) {
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
                let randomID = Int.random(in: 1...114)
                let surahName = quranData.surah(randomID)?.nameTransliteration ?? "Random Surah"
                quranPlayer.playSurah(surahNumber: randomID, surahName: surahName)
            }
        } label: {
            Label("Play Random Surah", systemImage: "shuffle")
        }

        Button {
            settings.hapticFeedback()
            if let randomSurah = quranData.quran.randomElement(),
               let randomAyah = randomSurah.ayahs.randomElement() {
                quranPlayer.playAyah(
                    surahNumber: randomSurah.id,
                    ayahNumber: randomAyah.id,
                    continueRecitation: true
                )
            }
        } label: {
            Label("Play Random Ayah", systemImage: "shuffle.circle")
        }
        
        Button {
            settings.hapticFeedback()
            showReciterPickerSheet = true
        } label: {
            Label("Choose Reciter", systemImage: "headphones")
        }
        #endif
    }

    @ViewBuilder
    private func primaryHistorySections(context: SearchDisplayContext) -> some View {
        #if os(iOS)
        if context.isSearching == false, let surah = settings.lastListenedSurah {
            LastListenedSurahRow(
                lastListenedSurah: surah,
                favoriteSurahs: context.favoriteSurahs,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID,
                showListeningHistory: $showListeningHistory
            )
        }
        #else
        NowPlayingView(quranView: true)
        #endif

        if context.isSearching == false,
           let lastReadSurah,
           let lastReadAyah {
            LastReadAyahRow(
                surah: lastReadSurah,
                ayah: lastReadAyah,
                favoriteSurahs: context.favoriteSurahs,
                bookmarkedAyahs: context.bookmarkedAyahs,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID,
                showReadingHistory: $showReadingHistory
            )
        }
    }

    @ViewBuilder
    private func bookmarkSection(context: SearchDisplayContext) -> some View {
        if !settings.bookmarkedAyahs.isEmpty && !context.isSearching {
            Section(header: bookmarkHeader) {
                if settings.showBookmarks {
                    ForEach(settings.bookmarkedAyahs.sorted {
                        $0.surah == $1.surah ? ($0.ayah < $1.ayah) : ($0.surah < $1.surah)
                    }, id: \.id) { bookmarkedAyah in
                        bookmarkRow(bookmarkedAyah, context: context)
                    }
                }
            }
        }
    }

    private var bookmarkHeader: some View {
        HStack {
            Text("BOOKMARKED AYAHS")

            Spacer()
            
            Text("\(settings.bookmarkedAyahs.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .conditionalGlassEffect()
                .padding(.vertical, -16)

            Image(systemName: settings.showBookmarks ? "chevron.down.circle" : "chevron.up.circle")
                .foregroundColor(settings.accentColor.color)
                .padding(4)
                .conditionalGlassEffect()
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation { settings.showBookmarks.toggle() }
                }
        }
    }

    @ViewBuilder
    private func bookmarkRow(_ bookmarkedAyah: BookmarkedAyah, context: SearchDisplayContext) -> some View {
          if let surah = quranData.surah(bookmarkedAyah.surah),
              let ayah = quranData.ayah(surah: bookmarkedAyah.surah, ayah: bookmarkedAyah.ayah) {
            let noteText = bookmarkedAyah.note?.trimmingCharacters(in: .whitespacesAndNewlines)
            let noteToShow = (noteText?.isEmpty == false) ? noteText : nil

            Group {
                #if os(iOS)
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
                favoriteSurahs: context.favoriteSurahs,
                bookmarkedAyahs: context.bookmarkedAyahs,
                bookmarkedSurah: bookmarkedAyah.surah,
                bookmarkedAyah: bookmarkedAyah.ayah
            )
            .ayahContextMenuModifier(
                surah: surah.id,
                ayah: ayah.id,
                favoriteSurahs: context.favoriteSurahs,
                bookmarkedAyahs: context.bookmarkedAyahs,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
        }
    }

    @ViewBuilder
    private func favoriteSection(context: SearchDisplayContext) -> some View {
        if !settings.favoriteSurahs.isEmpty && !context.isSearching {
            Section(header: favoriteHeader) {
                if settings.showFavorites {
                    ForEach(settings.favoriteSurahs.sorted(), id: \.self) { surahID in
                        favoriteRow(surahID: surahID, context: context)
                    }
                }
            }
        }
    }

    private var favoriteHeader: some View {
        HStack {
            Text("FAVORITE SURAHS")

            Spacer()
            
            Text("\(settings.favoriteSurahs.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .conditionalGlassEffect()
                .padding(.vertical, -16)

            Image(systemName: settings.showFavorites ? "chevron.down.circle" : "chevron.up.circle")
                .foregroundColor(settings.accentColor.color)
                .padding(4)
                .conditionalGlassEffect()
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation { settings.showFavorites.toggle() }
                }
        }
    }

    @ViewBuilder
    private func favoriteRow(surahID: Int, context: SearchDisplayContext) -> some View {
        if let surah = quranData.surah(surahID) {
            Group {
                #if os(iOS)
                Button {
                    push(surahID: surahID)
                } label: {
                    NavigationLink(destination: AyahsView(surah: surah)) {
                        SurahRow(surah: surah, isFavorite: context.favoriteSurahs.contains(surah.id))
                    }
                }
                #else
                NavigationLink(destination: AyahsView(surah: surah)) {
                    SurahRow(surah: surah, isFavorite: context.favoriteSurahs.contains(surah.id))
                }
                #endif
            }
            .rightSwipeActions(
                surahID: surahID,
                surahName: surah.nameTransliteration,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
            .leftSwipeActions(surah: surah.id, favoriteSurahs: context.favoriteSurahs)
            #if os(iOS)
            .contextMenu {
                SurahContextMenu(
                    surahID: surah.id,
                    surahName: surah.nameTransliteration,
                    favoriteSurahs: context.favoriteSurahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID
                )
            }
            #endif
        }
    }

    @ViewBuilder
    private func surahContentSections(context: SearchDisplayContext) -> some View {
        // Full browse list only when browsing. Never stack it under explicit page/juz queries.
        if context.explicitPageOrJuzMode && context.isSearching {
            EmptyView()
        } else if context.isSearching {
            if settings.searchForSurahs {
                surahSearchSection(context: context)
            }
        } else {
            switch settings.quranSortMode {
            case .surah:
                surahSearchSection(context: context)
            case .juz:
                juzSections(context: context)
            case .page:
                pageSections(context: context)
            case .revelation:
                revelationSections(context: context)
            }
        }
    }

    private func surahSearchSection(context: SearchDisplayContext) -> some View {
        Section(header: surahSectionHeader(context: context)) {
            ForEach(context.filteredSurahs, id: \.id) { surah in
                NavigationLink(destination: AyahsView(surah: surah)) {
                    surahSearchRow(surah: surah, context: context)
                }
                .id("surah_\(surah.id)")
                .onAppear {
                    if surah.id == scrollToSurahID {
                        withAnimation {
                            scrollToSurahID = -1
                        }
                    }
                }
                .rightSwipeActions(
                    surahID: surah.id,
                    surahName: surah.nameTransliteration,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID
                )
                .leftSwipeActions(surah: surah.id, favoriteSurahs: context.favoriteSurahs)
                #if os(iOS)
                .contextMenu {
                    SurahContextMenu(
                        surahID: surah.id,
                        surahName: surah.nameTransliteration,
                        favoriteSurahs: context.favoriteSurahs,
                        searchText: $searchText,
                        scrollToSurahID: $scrollToSurahID
                    )
                }
                #endif
                .animation(.easeInOut, value: searchText)
            }
        }
    }

    @ViewBuilder
    private func surahSearchRow(surah: Surah, context: SearchDisplayContext) -> some View {
        if settings.quranSortMode == .revelation {
            HStack(spacing: 10) {
                revelationOrderBadge(surah.revelationOrder ?? 0)

                SurahRow(surah: surah, isFavorite: context.favoriteSurahs.contains(surah.id))
            }
        } else {
            SurahRow(surah: surah, isFavorite: context.favoriteSurahs.contains(surah.id))
        }
    }
    
    private var revelationBadgeWidth: CGFloat {
        let font = UIFont.preferredFont(forTextStyle: .caption1)
        let text = "#114" as NSString
        let size = text.size(withAttributes: [.font: font])
        return size.width + 8
    }

    private func revelationOrderBadge(_ order: Int) -> some View {
        Text("#\(order)")
            .font(.caption.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(settings.accentColor.color)
            .frame(width: revelationBadgeWidth, alignment: .center)
            .accessibilityLabel("Revelation order \(order)")
    }

    @ViewBuilder
    private func surahSectionHeader(context: SearchDisplayContext) -> some View {
        if context.isSearching {
            HStack {
                Text("SURAH SEARCH RESULTS")

                Spacer()

                Text("\(context.filteredSurahs.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .conditionalGlassEffect()
                    .padding(.vertical, -16)
            }
        } else {
            SurahsHeader()
        }
    }

    @ViewBuilder
    private func juzSections(context: SearchDisplayContext) -> some View {
        ForEach(quranData.juzSections) { sectionData in
            let juz = sectionData.juz
            Section(header: JuzHeader(juz: juz)) {
                ForEach(sectionData.rows) { row in
                    preprocessedJuzRow(row: row, context: context)
                }
            }
            .sectionIndexLabelWhenAvailable("\(juz.id)")
        }
    }

    @ViewBuilder
    private func preprocessedJuzRow(row: QuranData.JuzSectionData.Row, context: SearchDisplayContext) -> some View {
        if let surah = quranData.surah(row.surahID) {
            let destination: AnyView = {
                switch row.kind {
                case .plain:
                    return AnyView(AyahsView(surah: surah))
                case .start(let ayah):
                    if ayah > 1 {
                        return AnyView(AyahsView(surah: surah, ayah: ayah))
                    }
                    return AnyView(AyahsView(surah: surah))
                case .end(let ayah):
                    if ayah < surah.numberOfAyahs {
                        return AnyView(AyahsView(surah: surah, ayah: ayah))
                    }
                    return AnyView(AyahsView(surah: surah))
                }
            }()

            NavigationLink(destination: destination) {
                switch row.kind {
                case .plain:
                    SurahRow(surah: surah, isFavorite: context.favoriteSurahs.contains(surah.id))
                case .start(let ayah):
                    SurahRow(surah: surah, ayah: ayah, isFavorite: context.favoriteSurahs.contains(surah.id))
                case .end(let ayah):
                    SurahRow(surah: surah, ayah: ayah, end: true, isFavorite: context.favoriteSurahs.contains(surah.id))
                }
            }
            #if os(iOS)
            .rightSwipeActions(
                surahID: surah.id,
                surahName: surah.nameTransliteration,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
            .leftSwipeActions(surah: surah.id, favoriteSurahs: context.favoriteSurahs)
            .contextMenu {
                SurahContextMenu(
                    surahID: surah.id,
                    surahName: surah.nameTransliteration,
                    favoriteSurahs: context.favoriteSurahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID
                )
            }
            #endif
        }
    }

    @ViewBuilder
    private func pageSections(context: SearchDisplayContext) -> some View {
        ForEach(quranData.pageSections) { pageGroup in
            Section(header: PageHeader(page: pageGroup.page)) {
                ForEach(pageGroup.surahIDs, id: \.self) { surahID in
                    if let surah = quranData.surah(surahID) {
                        surahRow(surah: surah, context: context)
                    }
                }
            }
            .sectionIndexLabelWhenAvailable("\(pageGroup.surahIDs.first ?? pageGroup.page)")
        }
    }

    @ViewBuilder
    private func revelationSections(context: SearchDisplayContext) -> some View {
        Section(header: SurahsHeader(text: "REVELATION ORDER")) {
            ForEach(quranData.revelationOrderSurahIDs, id: \.self) { surahID in
                if let surah = quranData.surah(surahID) {
                    NavigationLink(destination: AyahsView(surah: surah)) {
                        HStack(spacing: 10) {
                            revelationOrderBadge(surah.revelationOrder ?? 0)
                            
                            SurahRow(surah: surah, isFavorite: context.favoriteSurahs.contains(surah.id))
                        }
                    }
                    .id("surah_\(surah.id)")
                    #if os(iOS)
                    .rightSwipeActions(
                        surahID: surah.id,
                        surahName: surah.nameTransliteration,
                        searchText: $searchText,
                        scrollToSurahID: $scrollToSurahID
                    )
                    .leftSwipeActions(surah: surah.id, favoriteSurahs: context.favoriteSurahs)
                    .contextMenu {
                        SurahContextMenu(
                            surahID: surah.id,
                            surahName: surah.nameTransliteration,
                            favoriteSurahs: context.favoriteSurahs,
                            searchText: $searchText,
                            scrollToSurahID: $scrollToSurahID
                        )
                    }
                    #endif
                }
            }
        }
    }

    @ViewBuilder
    private func surahRow(surah: Surah, context: SearchDisplayContext) -> some View {
        NavigationLink(destination: AyahsView(surah: surah)) {
            SurahRow(surah: surah, isFavorite: context.favoriteSurahs.contains(surah.id))
        }
        .id("surah_\(surah.id)")
        #if os(iOS)
        .rightSwipeActions(
            surahID: surah.id,
            surahName: surah.nameTransliteration,
            searchText: $searchText,
            scrollToSurahID: $scrollToSurahID
        )
        .leftSwipeActions(surah: surah.id, favoriteSurahs: context.favoriteSurahs)
        .contextMenu {
            SurahContextMenu(
                surahID: surah.id,
                surahName: surah.nameTransliteration,
                favoriteSurahs: context.favoriteSurahs,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
        }
        #endif
    }

    @ViewBuilder
    private func searchResultSections(context: SearchDisplayContext) -> some View {
        if context.isSearching {
            // Page/juz rows for explicit queries are inserted above surahContentSections.
            if !context.explicitPageOrJuzMode {
                pageSearchSection(context: context)
                juzSearchSection(context: context)
            }

            if !context.explicitPageOrJuzMode, context.surahCountQuery == nil {
                ayahSearchSection(context: context)
                    .onChange(of: searchText) { txt in
                        handleAyahSearchChange(txt)
                    }
            }
        }
    }

    @ViewBuilder
    private func pageSearchSection(context: SearchDisplayContext) -> some View {
        if let page = context.pageJuzQuery.page,
           let pageResult = context.pageSearchResult {
            Section(header: pageSearchHeader(title: "PAGE SEARCH RESULT", valueText: "Page \(page)")) {
                AyahSearchResultRow(
                    surah: pageResult.surah,
                    ayah: pageResult.ayah,
                    favoriteSurahs: context.favoriteSurahs,
                    bookmarkedAyahs: context.bookmarkedAyahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID,
                    disableTajweedColors: true
                )
            }
        }
    }

    @ViewBuilder
    private func juzSearchSection(context: SearchDisplayContext) -> some View {
        if let juz = context.pageJuzQuery.juz,
           let juzResult = context.juzSearchResult {
            Section(header: pageSearchHeader(title: "JUZ SEARCH RESULT", valueText: "Juz \(juz)")) {
                AyahSearchResultRow(
                    surah: juzResult.surah,
                    ayah: juzResult.ayah,
                    favoriteSurahs: context.favoriteSurahs,
                    bookmarkedAyahs: context.bookmarkedAyahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID,
                    disableTajweedColors: true
                )
            }
        }
    }

    private func pageSearchHeader(title: String, valueText: String) -> some View {
        HStack {
            Text(title)

            Spacer()

            Text(valueText)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .conditionalGlassEffect()
                .padding(.vertical, -16)
        }
    }

    @ViewBuilder
    private func ayahSearchSection(context: SearchDisplayContext) -> some View {
        let bestHits = bestAyahHitsForCurrentQuery()

        if !bestHits.isEmpty {
            Section(header: bestAyahHeader(count: bestHits.count)) {
                ForEach(bestHits) { hit in
                    ayahHitRow(hit: hit, context: context)
                }
            }
        }

        Section(header: ayahSearchHeader(context: context)) {
            ayahExactMatchRows(context: context)
        }
        
        ForEach(verseHitsGroupedBySurah, id: \.surahId) { group in
            Section {
                ForEach(group.hits) { hit in
                    ayahHitRow(hit: hit, context: context)
                }
            } header: {
                surahSearchSectionHeader(surahId: group.surahId)
            }
        }
        Section {
            ayahLoadMoreControls(context: context)
        }
    }

    private func bestAyahHeader(count: Int) -> some View {
        HStack {
            Text("BEST RESULTS")

            Spacer()

            Text(String(count))
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .conditionalGlassEffect()
                .padding(.vertical, -16)
        }
    }

    private func bestAyahHitsForCurrentQuery(maxResults: Int = 3) -> [VerseIndexEntry] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 4, !verseHits.isEmpty else { return [] }

        let normalizedQuery = normalizedBestMatchText(trimmed)
        guard !normalizedQuery.isEmpty else { return [] }

        let queryTokens = normalizedQuery
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }

        guard !queryTokens.isEmpty else { return [] }

        typealias RankedHit = (hit: VerseIndexEntry, score: Int)
        var ranked: [RankedHit] = []
        ranked.reserveCapacity(verseHits.count)

        for hit in verseHits {
            guard let ayah = quranData.ayah(surah: hit.surah, ayah: hit.ayah) else { continue }

            let arabic = normalizedBestMatchText(ayah.displayArabicText(surahId: hit.surah, clean: settings.cleanArabicText))
            let tr = normalizedBestMatchText(ayah.textTransliteration)
            let en1 = normalizedBestMatchText(ayah.textEnglishSaheeh)
            let en2 = normalizedBestMatchText(ayah.textEnglishMustafa)
            let sources = [arabic, tr, en1, en2]

            var score = 0

            if sources.contains(where: { $0 == normalizedQuery }) {
                score += 260
            }

            if sources.contains(where: { $0.hasPrefix(normalizedQuery) }) {
                score += 180
            } else if sources.contains(where: { $0.contains(normalizedQuery) }) {
                score += 120
            }

            let tokenHits = queryTokens.filter { token in
                sources.contains(where: { $0.contains(token) })
            }.count

            score += tokenHits * 24

            if tokenHits == queryTokens.count {
                score += 60
            }

            if score > 0 {
                ranked.append((hit: hit, score: score))
            }
        }

        guard !ranked.isEmpty else { return [] }

        ranked.sort {
            if $0.score != $1.score { return $0.score > $1.score }
            if $0.hit.surah != $1.hit.surah { return $0.hit.surah < $1.hit.surah }
            return $0.hit.ayah < $1.hit.ayah
        }

        let topScore = ranked[0].score
        let secondScore = ranked.count > 1 ? ranked[1].score : 0
        let isClearlyBetter = topScore >= 220 || (ranked.count > 1 && (topScore - secondScore) >= 40)
        guard isClearlyBetter else { return [] }

        let minAcceptedScore = max(150, topScore - 55)
        var selected: [VerseIndexEntry] = []
        var seen = Set<String>()

        for candidate in ranked where candidate.score >= minAcceptedScore {
            let key = "\(candidate.hit.surah)-\(candidate.hit.ayah)"
            if seen.insert(key).inserted {
                selected.append(candidate.hit)
            }
            if selected.count >= maxResults { break }
        }

        return selected
    }

    private func normalizedBestMatchText(_ text: String) -> String {
        settings.cleanSearch(text, whitespace: true)
            .removingArabicDiacriticsAndSigns
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @ViewBuilder
    private func surahSearchSectionHeader(surahId: Int) -> some View {
        if let s = quranData.surah(surahId) {
            let latinHeader1 = "\(s.id). \(s.nameTransliteration)".uppercased()
            
            let latinHeader2 = "(\(s.nameEnglish)) —".uppercased()
            
            HStack(spacing: 6) {
                Text(latinHeader1)
                
                Text(latinHeader2)
                    .font(.caption)
                
                Text(s.nameArabic)
                    .font(.caption)
            }
        } else {
            Text("SURAH \(surahId)")
        }
    }

    @ViewBuilder
    private func ayahExactMatchRows(context: SearchDisplayContext) -> some View {
        if let surah = context.exactMatch.surah,
           let ayah = context.exactMatch.ayah {
            AyahSearchResultRow(
                surah: surah,
                ayah: ayah,
                favoriteSurahs: context.favoriteSurahs,
                bookmarkedAyahs: context.bookmarkedAyahs,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID,
                disableTajweedColors: true
            )
        }
    }

    private func ayahSearchHeader(context: SearchDisplayContext) -> some View {
        HStack {
            Text("AYAH SEARCH RESULTS")

            Spacer()

            Text(context.ayahCountDisplayText)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .conditionalGlassEffect()
                .padding(.vertical, -16)
        }
    }

    @ViewBuilder
    private func ayahHitRow(hit: VerseIndexEntry, context: SearchDisplayContext) -> some View {
        if let surah = quranData.surah(hit.surah),
           let ayah = quranData.ayah(surah: hit.surah, ayah: hit.ayah) {
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
                    favoriteSurahs: context.favoriteSurahs,
                    bookmarkedAyahs: context.bookmarkedAyahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID,
                    qiraahRefreshKey: settings.displayQiraah,
                    compact: true,
                    disableTajweedColors: true
                )
                .id("ayah-results-\(surah.id)-\(ayah.id)")
                .animation(.easeInOut, value: verseHits.count)
            }
        }
    }

    @ViewBuilder
    private func ayahLoadMoreControls(context: SearchDisplayContext) -> some View {
        if context.canShowMoreAyahHits {
            #if os(iOS)
            Menu("Load more ayah matches") {
                ForEach([5, 10, 20], id: \.self) { amount in
                    Button {
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
                    } label: {
                        Label("Load \(amount)", systemImage: "\(amount).circle")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(8)
            .conditionalGlassEffect()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .listRowSeparator(.hidden, edges: .bottom)
            .padding(.bottom, -8)
            #else
            Button("Load \(hitPageSize) ayah matches") {
                let (moreHits, moreAvail) = fetchHits(query: searchText, limit: hitPageSize, offset: verseHits.count)
                withAnimation {
                    verseHits.append(contentsOf: moreHits)
                    hasMoreHits = moreAvail
                }
            }
            .foregroundColor(settings.accentColor.color)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(8)
            .conditionalGlassEffect()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            #endif
            
            Button {
                settings.hapticFeedback()
                withAnimation {
                    verseHits = quranData.searchVersesAll(term: searchText)
                    hasMoreHits = false
                }
            } label: {
                Text("Load all ayah matches")
            }
            .foregroundColor(settings.accentColor.color)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(8)
            .conditionalGlassEffect()
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            #if os(iOS)
            .padding(.top, -8)
            .listRowSeparator(.hidden)
            #endif
        }
    }

    private func handleAyahSearchChange(_ txt: String) {
        let query = txt.trimmingCharacters(in: .whitespacesAndNewlines)

        if parseSurahCountQuery(from: query) != nil {
            withAnimation {
                verseHits = []
                hasMoreHits = false
                blockAyahSearchAfterZero = false
            }
            return
        }

        guard !query.isEmpty else {
            withAnimation {
                verseHits = []
                hasMoreHits = false
                blockAyahSearchAfterZero = false
            }
            return
        }

        if blockAyahSearchAfterZero {
            if query.count < zeroResultQueryLength {
                blockAyahSearchAfterZero = false
            } else if query.count > zeroResultQueryLength {
                return
            }
        }

        let (first, more) = fetchHits(query: query, limit: hitPageSize, offset: 0)
        withAnimation {
            verseHits = first
            hasMoreHits = more
            if first.isEmpty {
                blockAyahSearchAfterZero = true
                zeroResultQueryLength = query.count
            } else {
                blockAyahSearchAfterZero = false
            }
        }
    }

    private var searchDisplayContext: SearchDisplayContext {
        let pageJuzQuery = parsePageJuzQuery(from: searchText)
        let exactMatch = getSurahAndAyah(from: searchText)
        let surahCountQuery = parseSurahCountQuery(from: searchText)
        let filteredSurahs = filteredSurahs(for: searchText, countQuery: surahCountQuery)

        return SearchDisplayContext(
            isSearching: !searchText.isEmpty,
            favoriteSurahs: Set(settings.favoriteSurahs),
            bookmarkedAyahs: Set(settings.bookmarkedAyahs.map(\.id)),
            pageJuzQuery: pageJuzQuery,
            explicitPageOrJuzMode: pageJuzQuery.isExplicitPage || pageJuzQuery.isExplicitJuz,
            pageSearchResult: firstAyahResult(page: pageJuzQuery.page),
            juzSearchResult: firstAyahResult(juz: pageJuzQuery.juz),
            exactMatch: exactMatch,
            surahCountQuery: surahCountQuery,
            filteredSurahs: filteredSurahs,
            canShowMoreAyahHits: hasMoreHits && !verseHits.isEmpty,
            ayahCountDisplayText: {
                let exactMatchBump = (exactMatch.surah != nil && exactMatch.ayah != nil) ? 1 : 0
                let ayahCount = verseHits.count + exactMatchBump
                return "\(ayahCount)\((hasMoreHits && !verseHits.isEmpty) ? "+" : "")"
            }()
        )
    }
    
    /// First bookmark that resolves against loaded Quran data (surah then ayah order).
    private func resolvedFirstBookmark() -> (surah: Surah, ayah: Ayah)? {
        let sorted = settings.bookmarkedAyahs.sorted {
            $0.surah == $1.surah ? ($0.ayah < $1.ayah) : ($0.surah < $1.surah)
        }
        for b in sorted {
            if let surah = quranData.surah(b.surah),
               let ayah = quranData.ayah(surah: b.surah, ayah: b.ayah) {
                return (surah, ayah)
            }
        }
        return nil
    }

    private var hasStoredLastReadAyah: Bool {
        settings.lastReadSurah >= 1 && settings.lastReadAyah >= 1
    }

    @ViewBuilder
    var detailFallback: some View {
        if hasStoredLastReadAyah, let s = lastReadSurah, let a = lastReadAyah {
            AyahsView(surah: s, ayah: a.id)
        } else if let b = resolvedFirstBookmark() {
            AyahsView(surah: b.surah, ayah: b.ayah.id)
        } else if let favID = settings.favoriteSurahs.sorted().first,
                  let s = quranData.surah(favID) {
            AyahsView(surah: s)
        } else if let s = quranData.surah(1) {
            AyahsView(surah: s)
        } else {
            Color.clear
        }
    }

}

#if os(iOS)
private struct QuranReciterPickerSheetPresentationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}
#endif

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
            listSectionIndexVisibility(visible ? .visible : .hidden)
        } else {
            self
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        QuranView()
    }
}
