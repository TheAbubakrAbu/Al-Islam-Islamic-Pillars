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
    @State private var showListeningHistory = false
    @State private var showReadingHistory = false
    @State private var searchHistorySaveTask: Task<Void, Never>?
    @State private var lastSavedSearchQuery = ""
    
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

    private struct SearchDisplayContext {
        let isSearching: Bool
        let favoriteSurahs: Set<Int>
        let bookmarkedAyahs: Set<String>
        let pageJuzQuery: PageJuzQuery
        let explicitPageOrJuzMode: Bool
        let pageSearchResult: (surah: Surah, ayah: Ayah)?
        let juzSearchResult: (surah: Surah, ayah: Ayah)?
        let exactMatch: (surah: Surah?, ayah: Ayah?)
        let filteredSurahs: [Surah]
        let canShowMoreAyahHits: Bool
        let ayahCountDisplayText: String
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

    private func persistQuranSearchHistoryIfNeeded(_ rawQuery: String, requireMinLength: Bool = false) {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if requireMinLength && trimmed.count < 3 { return }

        // Avoid repeatedly writing the same query while user is editing.
        if lastSavedSearchQuery.caseInsensitiveCompare(trimmed) == .orderedSame { return }

        settings.addQuranSearchHistory(trimmed)
        lastSavedSearchQuery = trimmed
    }

    private func scheduleDebouncedQuranSearchHistorySave(for query: String) {
        searchHistorySaveTask?.cancel()
        let snapshot = query
        searchHistorySaveTask = Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                persistQuranSearchHistoryIfNeeded(snapshot, requireMinLength: true)
            }
        }
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
            VStack(alignment: .leading, spacing: 5) {
                Text("Search for Surahs")
                    .font(.subheadline.bold())
                    .foregroundStyle(settings.accentColor.color)
                
                Text("Search by surah number, Arabic name, English translation, or transliteration.")
                    .font(.caption)
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Search for Ayahs")
                    .font(.subheadline.bold())
                    .foregroundStyle(settings.accentColor.color)
                
                Text("Search ayah like X:Y, or by Arabic, English translation, and transliteration.")
                    .font(.caption)
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Search by page or juz")
                    .font(.subheadline.bold())
                    .foregroundStyle(settings.accentColor.color)
                
                Text("Use 'page X', 'juz X', or plain numbers to match page/juz results.")
                    .font(.caption)
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Tips")
                    .font(.subheadline.bold())
                    .foregroundStyle(settings.accentColor.color)
                
                Text("You can scroll to a surah from loaded surah or ayah results, and use the context menu on items to see more actions and info.")
                    .font(.caption)
                    .foregroundStyle(.primary)
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
        ) { Button("OK", role: .cancel) { } } message: {
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
        #if !os(watchOS)
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
            if let surah = quranData.quran.first(where: { $0.id == surahID }) {
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
                // Explicit "page X" / "juz X" — show compact result first (not buried under 30 juz sections).
                if context.explicitPageOrJuzMode && context.isSearching {
                    pageSearchSection(context: context)
                    juzSearchSection(context: context)
                }
                surahContentSections(context: context)
                searchResultSections(context: context)
            }
            .applyConditionalListStyle(defaultView: settings.defaultView)
            .dismissKeyboardOnScroll()
            .listSectionIndexVisibilityWhenAvailable(visible: !settings.groupBySurah && searchText.isEmpty)
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
        #if !os(watchOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                settingsButton
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            NavigationView { SettingsQuranView(showEdits: false, presentedAsSheet: true) }
        }
        .onDisappear {
            withAnimation {
                searchHistorySaveTask?.cancel()
                persistQuranSearchHistoryIfNeeded(searchText)
            }
        }
        .overlay(alignment: .top) {
            searchHelpOverlay
        }
        .safeAreaInset(edge: .bottom) {
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
        #if !os(watchOS)
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
        #if !os(watchOS)
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
        #if !os(watchOS)
        if quranPlayer.isPlaying || quranPlayer.isPaused {
            NowPlayingView(quranView: true, scrollDown: $scrollToSurahID, searchText: $searchText)
        }
        #endif
    }

    private var sortModePicker: some View {
        #if !os(watchOS)
        Picker("Sort Type", selection: $settings.groupBySurah.animation(.easeInOut)) {
            Text("Sort by Surah").tag(true)
            Text("Sort by Juz").tag(false)
        }
        .pickerStyle(SegmentedPickerStyle())
        .conditionalGlassEffect()
        #else
        EmptyView()
        #endif
    }

    private var searchAndPlaybackRow: some View {
        #if !os(watchOS)
        HStack(spacing: 0) {
            quranSearchBar

            playbackMenuButton
                .frame(width: 26, height: 26)
                .padding()
                .conditionalGlassEffect()
        }
        .padding([.leading, .top], -8)
        #else
        EmptyView()
        #endif
    }

    private var quranSearchBar: some View {
        #if !os(watchOS)
        SearchBar(
            text: $searchText.animation(.easeInOut),
            onSearchButtonClicked: {
                persistQuranSearchHistoryIfNeeded(searchText)
            },
            onFocusChanged: { focused in
                withAnimation {
                    isQuranSearchFocused = focused
                }
                if !focused {
                    persistQuranSearchHistoryIfNeeded(searchText)
                }
            }
        )
        #else
        EmptyView()
        #endif
    }

    private var playbackMenuButton: some View {
        #if !os(watchOS)
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
        #if !os(watchOS)
        if let last = settings.lastListenedSurah,
           let surah = quranData.quran.first(where: { $0.id == last.surahNumber }) {
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
                let surahName = quranData.quran.first(where: { $0.id == randomID })?.nameTransliteration ?? "Random Surah"
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
            Label("Play Random Ayah", systemImage: "shuffle")
        }
        #endif
    }

    @ViewBuilder
    private func primaryHistorySections(context: SearchDisplayContext) -> some View {
        #if !os(watchOS)
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

            Image(systemName: settings.showBookmarks ? "chevron.down" : "chevron.up")
                .foregroundColor(settings.accentColor.color)
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation { settings.showBookmarks.toggle() }
                }
                .buttonStyle(.plain)
                .padding(4)
                .conditionalGlassEffect()
        }
    }

    @ViewBuilder
    private func bookmarkRow(_ bookmarkedAyah: BookmarkedAyah, context: SearchDisplayContext) -> some View {
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

            Image(systemName: settings.showFavorites ? "chevron.down" : "chevron.up")
                .foregroundColor(settings.accentColor.color)
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation { settings.showFavorites.toggle() }
                }
                .buttonStyle(.plain)
                .padding(4)
                .conditionalGlassEffect()
        }
    }

    @ViewBuilder
    private func favoriteRow(surahID: Int, context: SearchDisplayContext) -> some View {
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
            .leftSwipeActions(surah: surah.id, favoriteSurahs: context.favoriteSurahs)
            #if !os(watchOS)
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
        // Full 30-juz list only when browsing (Sort by Juz, empty search). Never stack it under explicit page/juz queries.
        if context.explicitPageOrJuzMode && context.isSearching {
            EmptyView()
        } else if !settings.groupBySurah && !context.isSearching {
            juzSections(context: context)
        } else if settings.groupBySurah || (context.isSearching && settings.searchForSurahs) {
            surahSearchSection(context: context)
        }
    }

    private func surahSearchSection(context: SearchDisplayContext) -> some View {
        Section(header: surahSectionHeader(context: context)) {
            ForEach(context.filteredSurahs, id: \.id) { surah in
                NavigationLink(destination: AyahsView(surah: surah)) {
                    SurahRow(surah: surah)
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
                #if !os(watchOS)
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
                    #if !os(watchOS)
                    .background(.ultraThinMaterial)
                    #endif
                    .clipShape(Capsule())
                    .conditionalGlassEffect()
            }
            .padding(.vertical, 4)
        } else {
            SurahsHeader()
        }
    }

    @ViewBuilder
    private func juzSections(context: SearchDisplayContext) -> some View {
        ForEach(QuranData.juzList, id: \.id) { juz in
            Section(header: JuzHeader(juz: juz)) {
                let surahsInRange = quranData.quran.filter {
                    $0.id >= juz.startSurah && $0.id <= juz.endSurah
                }

                ForEach(surahsInRange, id: \.id) { surah in
                    juzSurahRow(surah: surah, juz: juz, context: context)
                }
            }
            .sectionIndexLabelWhenAvailable("\(juz.id)")
        }
    }

    @ViewBuilder
    private func juzSurahRow(surah: Surah, juz: Juz, context: SearchDisplayContext) -> some View {
        let startAyah = (surah.id == juz.startSurah) ? juz.startAyah : 1
        let endAyah = (surah.id == juz.endSurah) ? juz.endAyah : surah.numberOfAyahs
        let singleSurah = juz.startSurah == surah.id && juz.endSurah == surah.id

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

            if !context.explicitPageOrJuzMode {
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
                    scrollToSurahID: $scrollToSurahID
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
                    scrollToSurahID: $scrollToSurahID
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

    private func ayahSearchSection(context: SearchDisplayContext) -> some View {
        Section(header: ayahSearchHeader(context: context)) {
            if let surah = context.exactMatch.surah,
               let ayah = context.exactMatch.ayah {
                AyahSearchResultRow(
                    surah: surah,
                    ayah: ayah,
                    favoriteSurahs: context.favoriteSurahs,
                    bookmarkedAyahs: context.bookmarkedAyahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID
                )
            }

            ForEach(verseHits) { hit in
                ayahHitRow(hit: hit, context: context)
            }

            ayahLoadMoreControls(context: context)
        }
    }

    private func ayahSearchHeader(context: SearchDisplayContext) -> some View {
        HStack {
            Text("AYAH SEARCH RESULTS")

            Spacer()

            Text(context.ayahCountDisplayText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                #if !os(watchOS)
                .background(.ultraThinMaterial)
                #endif
                .clipShape(Capsule())
                .conditionalGlassEffect()
        }
        .padding(.vertical, 4)
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
                    scrollToSurahID: $scrollToSurahID
                )
                .id("ayah-results-\(surah.id)-\(ayah.id)")
                .animation(.easeInOut, value: verseHits.count)
            }
        }
    }

    @ViewBuilder
    private func ayahLoadMoreControls(context: SearchDisplayContext) -> some View {
        if context.canShowMoreAyahHits {
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

    private func handleAyahSearchChange(_ txt: String) {
        let query = txt.trimmingCharacters(in: .whitespacesAndNewlines)

        scheduleDebouncedQuranSearchHistorySave(for: query)

        guard !query.isEmpty else {
            withAnimation {
                searchHistorySaveTask?.cancel()
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

        let filteredSurahs = quranData.quran.filter { surah in
            if let numericQuery, numericQuery == surah.id { return true }
            if searchText.isEmpty { return true }
            return upperQuery.contains(surah.nameEnglish.uppercased()) ||
                upperQuery.contains(surah.nameTransliteration.uppercased()) ||
                settings.cleanSearch(surah.nameArabic).contains(cleanedSearch) ||
                settings.cleanSearch(surah.nameTransliteration).contains(cleanedSearch) ||
                settings.cleanSearch(surah.nameEnglish).contains(cleanedSearch) ||
                settings.cleanSearch(String(surah.id)).contains(cleanedSearch) ||
                settings.cleanSearch(surah.idArabic).contains(cleanedSearch)
        }

        return SearchDisplayContext(
            isSearching: !searchText.isEmpty,
            favoriteSurahs: Set(settings.favoriteSurahs),
            bookmarkedAyahs: Set(settings.bookmarkedAyahs.map(\.id)),
            pageJuzQuery: pageJuzQuery,
            explicitPageOrJuzMode: pageJuzQuery.isExplicitPage || pageJuzQuery.isExplicitJuz,
            pageSearchResult: firstAyahResult(page: pageJuzQuery.page),
            juzSearchResult: firstAyahResult(juz: pageJuzQuery.juz),
            exactMatch: exactMatch,
            filteredSurahs: filteredSurahs,
            canShowMoreAyahHits: hasMoreHits && !verseHits.isEmpty,
            ayahCountDisplayText: {
                let exactMatchBump = (exactMatch.surah != nil && exactMatch.ayah != nil) ? 1 : 0
                let ayahCount = verseHits.count + exactMatchBump
                return "\(ayahCount)\((hasMoreHits && !verseHits.isEmpty) ? "+" : "")"
            }()
        )
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
            loadingFallbackView
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
    AlIslamPreviewContainer(embedInNavigation: false) {
        QuranView()
    }
}
